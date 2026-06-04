class Sudoku::SolverController < ApplicationController
  include SudokuHelper
  def sudoku_solver
    @puzzle = load_game_state
    @difficulty = params[:difficulty] || "medium"
    @puzzle = @puzzle.present? ? @puzzle : set_new_puzzle(@difficulty || "medium")
  end

  def new_puzzle
    difficulty = params[:difficulty] || "medium"
    puzzle = set_new_puzzle(difficulty)
    save_game_state(puzzle, true)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("game_board", partial: "sudoku/solver/game_board", locals: { puzzle: puzzle })
      end
    end
  end

  def new_puzzle_from_api
    puzzle = fetch_api_puzzle(params[:difficulty])
    if puzzle.nil?
      render turbo_stream: turbo_stream.replace("message_card", partial: "sudoku/solver/message_card", locals: { message_type: "warning", message_text: "Sorry, I couldn't fetch a puzzle from the API. Here's a local one instead!" })
      puzzle = set_new_puzzle(params[:difficulty])
    else
      save_game_state(puzzle, true)
    end
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("game_board", partial: "sudoku/solver/game_board", locals: { puzzle: puzzle })
      end
    end
  end

  def solve_puzzle
    @puzzle = load_game_state
    if @puzzle.confirmed_count < 17
      render turbo_stream: turbo_stream.replace("message_card", partial: "sudoku/solver/message_card", locals: { message_type: "warning", message_text: "This puzzle has fewer than 17 clues, which is below the known threshold for a unique solution!" })
      return
    end
    solver = Sudoku::PuzzleSolver.new(@puzzle, display: true, slow_display: params[:speed] == "slow")
    success = solver.solve
    render turbo_stream: [
      turbo_stream.replace("message_card", partial: "sudoku/solver/message_card", locals: { message_type: success ? "" : "failure", message_text: success ? "" : "Oops, I couldn't solve that puzzle." }),
      turbo_stream.replace("game_board", partial: "sudoku/solver/game_board", locals: { puzzle: @puzzle, solved: true })
    ]
    save_game_state(@puzzle, true)
  end

  def generate_puzzles
    generator = Sudoku::PuzzleGenerator.new
    generator.generate_puzzles(5, "medium")
    @failed_puzzle = generator.failed_puzzles.sample
  end

  private

  def set_new_puzzle(difficulty = "medium")
    puzzle = fetch_api_puzzle(difficulty)
    if puzzle.nil?
      puzzles = Sudoku.load_puzzles
      puzzle = puzzles[difficulty].sample
    end
    save_game_state(puzzle)
    puzzle
  end

  def fetch_api_puzzle(difficulty)
    return nil unless Sudoku::YouDoSudokuClient.configured?

    Sudoku::YouDoSudokuClient.new.fetch_puzzle(difficulty: difficulty)
  rescue Sudoku::YouDoSudokuClient::ApiError, ArgumentError => e
    Rails.logger.warn("You Do Sudoku API fallback to local puzzle: #{e.message}")
    nil
  end
end
