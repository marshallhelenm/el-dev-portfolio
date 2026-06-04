require "json"
require "matrix"
require "net/http"
require "uri"

class Sudoku::YouDoSudokuClient
  class ApiError < StandardError; end

  BASE_URL = "https://you-do-sudoku-api.vercel.app/api".freeze
  ALLOWED_DIFFICULTIES = %w[easy medium hard].freeze

  def initialize(api_key: self.class.api_key, base_url: BASE_URL)
    raise ArgumentError, "You Do Sudoku API key is required" if api_key.to_s.strip.empty?

    @api_key = api_key
    @base_url = base_url
  end

  def self.configured?
    api_key.to_s.strip.present?
  end

  def self.api_key
    env_key = ENV["YOU_DO_SUDOKU_API_KEY"]
    return env_key if env_key.to_s.strip.present?

    return nil unless defined?(Rails) && Rails.respond_to?(:application)

    Rails.application.credentials.dig(:you_do_sudoku, :api_key)
  end

  def fetch_puzzle_data(difficulty: nil)
    uri = build_uri
    response = perform_request(uri, difficulty: difficulty)
    parse_response(response)
  end

  def fetch_puzzle_values_matrix(difficulty: nil)
    data = fetch_puzzle_data(difficulty: difficulty)
    self.class.string_to_values_matrix(data.fetch("puzzle"))
  end

  def fetch_puzzle(difficulty: nil)
    Sudoku::Puzzle.new(values: fetch_puzzle_values_matrix(difficulty: difficulty))
  end

  def self.string_to_values_matrix(puzzle_string)
    unless puzzle_string.is_a?(String) && puzzle_string.match?(/\A\d{81}\z/)
      raise ApiError, "Puzzle payload must be an 81-digit string"
    end

    rows = puzzle_string.chars.map(&:to_i).each_slice(9).to_a
    Matrix[*rows]
  end

  private

  def build_uri
    URI.parse(@base_url)
  end

  def perform_request(uri, difficulty: nil)
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["x-api-key"] = @api_key
    request.body = JSON.generate(request_body(difficulty))

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end
  rescue SocketError, Timeout::Error, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => e
    raise ApiError, "Unable to reach You Do Sudoku API: #{e.message}"
  end

  def request_body(difficulty)
    {
      difficulty: normalize_difficulty(difficulty),
      solution: true,
      array: false
    }
  end

  def normalize_difficulty(difficulty)
    normalized = difficulty.to_s.downcase.strip
    return "easy" if normalized.empty?
    return normalized if ALLOWED_DIFFICULTIES.include?(normalized)

    "easy"
  end

  def parse_response(response)
    unless response.code.to_i == 200
      raise ApiError, "You Do Sudoku API request failed (#{response.code}): #{response.body}"
    end

    parsed = JSON.parse(response.body)
    parsed.fetch("puzzle")
    parsed.fetch("solution")
    parsed
  rescue JSON::ParserError, KeyError => e
    raise ApiError, "Unexpected You Do Sudoku API response format: #{e.message}"
  end
end