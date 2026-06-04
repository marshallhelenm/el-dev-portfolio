require "set"

namespace :puzzles do
  desc "Generate JSON puzzles"
  task generate_json: :environment do
    puts "How many puzzles do you want to generate?"
    num_puzzles = STDIN.gets.chomp
    num_puzzles = num_puzzles.to_i
    puts "What difficulty level? (easy, medium, hard)"
    difficulty = STDIN.gets.chomp.downcase.to_sym
    puts "Should we display the generation process in the console? (y/n)"
    display_process = STDIN.gets.chomp.downcase == "y"
    puts "Generating JSON puzzles..."
    generator = Sudoku::PuzzleGenerator.new(print_progress: display_process)
    generator.generate_puzzles_to_json(num_puzzles, difficulty: difficulty)
    puts "JSON puzzles generated and saved to app/assets/puzzle_matrices.json"
  end

  desc "Fetch puzzles from You Do Sudoku API and save to JSON"
  task fetch_json_from_api: :environment do
    begin
      client = Sudoku::YouDoSudokuClient.new
    rescue ArgumentError => e
      puts e.message
      puts "Set YOU_DO_SUDOKU_API_KEY before running this task."
      next
    end

    puts "How many puzzles do you want to fetch from API?"
    num_puzzles = STDIN.gets.chomp.to_i
    puts "What difficulty level should we request? (easy, medium, hard)"
    requested_difficulty = STDIN.gets.chomp.downcase
    requested_difficulty = "medium" unless %w[easy medium hard].include?(requested_difficulty)

    json_path = Rails.root.join("app/assets/puzzle_matrices.json")
    puzzle_data = if File.exist?(json_path)
      JSON.parse(File.read(json_path))
    else
      { "easy" => [], "medium" => [], "hard" => [] }
    end

    %w[easy medium hard].each { |difficulty| puzzle_data[difficulty] ||= [] }
    existing_puzzle_keys = {}
    %w[easy medium hard].each do |difficulty|
      existing_puzzle_keys[difficulty] = Set.new(puzzle_data[difficulty].map { |puzzle| puzzle.flatten.join })
    end

    puts "Fetching #{num_puzzles} #{requested_difficulty} puzzles from API..."
    fetched_count = 0
    failed_count = 0
    duplicate_count = 0

    num_puzzles.times do |index|
      begin
        payload = client.fetch_puzzle_data(difficulty: requested_difficulty)
        matrix = Sudoku::YouDoSudokuClient.string_to_values_matrix(payload.fetch("puzzle"))
        matrix_array = matrix.to_a
        response_difficulty = payload["difficulty"].to_s.downcase
        if response_difficulty != requested_difficulty
          puts "Warning: API returned difficulty '#{response_difficulty}' which differs from requested '#{requested_difficulty}'"
          next
        end
        difficulty_bucket = %w[easy medium hard].include?(response_difficulty) ? response_difficulty : requested_difficulty
        puzzle_key = matrix_array.flatten.join
        if existing_puzzle_keys[difficulty_bucket].include?(puzzle_key)
          duplicate_count += 1
          puts "Fetched #{index + 1}/#{num_puzzles} (duplicate skipped for #{difficulty_bucket})"
        else
          puzzle_data[difficulty_bucket] << matrix_array
          existing_puzzle_keys[difficulty_bucket] << puzzle_key
          fetched_count += 1
          puts "Fetched #{index + 1}/#{num_puzzles} (saved to #{difficulty_bucket})"
        end
      rescue Sudoku::YouDoSudokuClient::ApiError => e
        failed_count += 1
        puts "Fetch #{index + 1}/#{num_puzzles} failed: #{e.message}"
      end
    end

    File.write(json_path, JSON.generate(puzzle_data))

    puts "Saved API puzzles to app/assets/puzzle_matrices.json"
    puts "Fetched: #{fetched_count}"
    puts "Duplicates skipped: #{duplicate_count}"
    puts "Failed: #{failed_count}"
  end
end
