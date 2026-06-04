# frozen_string_literal: true

require "minitest/autorun"
require "matrix"
require_relative "../../../app/models/sudoku/puzzle"
require_relative "../../../app/models/sudoku/you_do_sudoku_client"

class YouDoSudokuClientTest < Minitest::Test
  Response = Struct.new(:code, :body)

  def setup
    @api_key = "test-key"
    @puzzle_string = "530070000600195000098000060800060003400803001700020006060000280000419005000080079"
    @solution_string = "534678912672195348198342567859761423426853791713924856961537284287419635345286179"
  end

  def test_initialize_requires_api_key
    assert_raises(ArgumentError) { Sudoku::YouDoSudokuClient.new(api_key: "") }
  end

  def test_fetch_puzzle_data_parses_success_response
    client = Sudoku::YouDoSudokuClient.new(api_key: @api_key)
    payload = {
      "difficulty" => "easy",
      "puzzle" => @puzzle_string,
      "solution" => @solution_string
    }

    client.stub(:perform_request, Response.new("200", payload.to_json)) do
      data = client.fetch_puzzle_data(difficulty: "easy")
      assert_equal "easy", data["difficulty"]
      assert_equal @puzzle_string, data["puzzle"]
      assert_equal @solution_string, data["solution"]
    end
  end

  def test_fetch_puzzle_returns_sudoku_puzzle
    client = Sudoku::YouDoSudokuClient.new(api_key: @api_key)
    payload = {
      "difficulty" => "easy",
      "puzzle" => @puzzle_string,
      "solution" => @solution_string
    }

    client.stub(:perform_request, Response.new("200", payload.to_json)) do
      puzzle = client.fetch_puzzle
      assert_instance_of Sudoku::Puzzle, puzzle
      assert_equal @puzzle_string.chars.first.to_i, puzzle.cell(0, 0).value
      assert_equal @puzzle_string.chars.last.to_i, puzzle.cell(8, 8).value
    end
  end

  def test_fetch_puzzle_data_raises_for_non_200
    client = Sudoku::YouDoSudokuClient.new(api_key: @api_key)

    client.stub(:perform_request, Response.new("401", "{\"error\":\"unauthorized\"}")) do
      assert_raises(Sudoku::YouDoSudokuClient::ApiError) { client.fetch_puzzle_data }
    end
  end

  def test_string_to_values_matrix_validates_payload
    assert_raises(Sudoku::YouDoSudokuClient::ApiError) do
      Sudoku::YouDoSudokuClient.string_to_values_matrix("123")
    end
  end
end