import gleam/io
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import aoc2023_gleam

pub fn main() {
  let filename = "inputs/day02.txt"

  let lines_result = aoc2023_gleam.read_lines(from: filename)
  case lines_result {
    Ok(lines) -> {
      // If the file was converting into a list of lines
      // successfully then run each part of the problem
      io.println("Part 1: " <> aoc2023_gleam.solution_or_error(solve_p1(lines)))
      io.println("Part 2: " <> aoc2023_gleam.solution_or_error(solve_p2(lines)))
    }
    Error(_) -> io.println("Error reading file")
  }
}

type Draw {
  Draw(red: Int, green: Int, blue: Int)
}

const max = Draw(red: 12, green: 13, blue: 14)

// Part 1
pub fn solve_p1(lines: List(String)) -> Result(String, String) {
  // Determine if each game is possible
  use games <- result.try(result.all(list.map(lines, parse_game)))
  let possibles = list.map(games, possible_game)

  // Sum ip indecies of each possible game or return error
  let solution =
    list.index_fold(
      possibles,
      from: 0,
      with: fn(acc: Int, poss: Bool, idx: Int) -> Int {
        case poss {
          True -> acc + idx + 1
          False -> acc
        }
      },
    )

  // Return solution as string
  Ok(int.to_string(solution))
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  // Find fewest cubes required for each game
  use games <- result.try(result.all(list.map(lines, parse_game)))
  let mincubes = list.map(games, fewest_cubes)

  // Calculate power
  let solution =
    list.fold(mincubes, from: 0, with: fn(acc: Int, d: Draw) -> Int {
      let power = d.red * d.green * d.blue
      acc + power
    })

  Ok(int.to_string(solution))
}

/// Turn a game into a list of bag draws
fn parse_game(line: String) -> Result(List(Draw), String) {
  // Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
  case string.split(line, on: ": ") {
    [_, draws] -> {
      string.split(draws, on: "; ")
      |> list.map(parse_draw)
      |> result.all
    }
    _ -> Error("Unable to split " <> line <> " on colon")
  }
}

/// Parse a draw into a draw record
fn parse_draw(draw: String) -> Result(Draw, String) {
  string.split(draw, ", ")
  |> list.try_fold(from: Draw(0, 0, 0), with: fn(b: Draw, a: String) -> Result(
    Draw,
    String,
  ) {
    case string.split(a, " ") {
      [n, color] -> {
        let count_result = int.parse(n)
        case count_result {
          Ok(count) -> {
            case color {
              "red" -> Ok(Draw(..b, red: count))
              "green" -> Ok(Draw(..b, green: count))
              "blue" -> Ok(Draw(..b, blue: count))
              _ -> Error("Unexpected color: " <> color)
            }
          }
          Error(_) -> Error("Unable to parse " <> n <> " as integer")
        }
      }
      _ -> Error("Unable to parse draw: " <> a)
    }
  })
}

// A game is possible if there are no more than the maximum number
// of colors in each draw
fn possible_game(game: List(Draw)) -> Bool {
  list.all(game, fn(d: Draw) -> Bool {
    d.red <= max.red && d.green <= max.green && d.blue <= max.blue
  })
}

// Find fewest cubes of each color possible for this game
fn fewest_cubes(game: List(Draw)) -> Draw {
  list.fold(game, from: Draw(0, 0, 0), with: fn(acc, d) {
    Draw(
      red: int.max(acc.red, d.red),
      green: int.max(acc.green, d.green),
      blue: int.max(acc.blue, d.blue),
    )
  })
}
