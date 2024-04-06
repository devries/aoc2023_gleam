import gleam/io
import gleam/int
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import aoc2023_gleam

pub fn main() {
  let filename = "inputs/day04.txt"

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

// Part 1
pub fn solve_p1(lines: List(String)) -> Result(String, String) {
  list.map(lines, parse_line)
  |> list.map(score)
  |> result.all
  |> result.map(fn(a: List(Int)) -> String { int.to_string(int.sum(a)) })
  // Error("Unimplemented")
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  let _lines = lines
  Error("Unimplemented")
}

fn parse_line(line: String) -> Result(#(List(Int), List(Int)), String) {
  // Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
  case string.split(line, on: ": ") {
    [_, scratch_numbers] -> {
      let nls =
        string.split(scratch_numbers, on: " | ")
        |> list.map(parse_numberlist)
      case nls {
        [Ok(a), Ok(b)] -> Ok(#(a, b))
        [Error(a), ..] -> Error(a)
        [Ok(_), Error(b), ..] -> Error(b)
        _ -> Error(scratch_numbers <> " has no number lists in it")
      }
    }
    _ -> Error("unable to split '" <> line <> "' on colon")
  }
}

fn parse_numberlist(numberlist: String) -> Result(List(Int), String) {
  string.split(numberlist, " ")
  |> list.filter(fn(s: String) { s != "" })
  |> list.map(int.parse)
  |> result.all
  |> result.replace_error(
    numberlist <> " is not a space separated list of integers",
  )
}

fn intersection(a: List(Int), b: List(Int)) -> List(Int) {
  let a_set = set.from_list(a)
  let b_set = set.from_list(b)

  set.to_list(set.intersection(a_set, b_set))
}

fn score(tpl: Result(#(List(Int), List(Int)), String)) -> Result(Int, String) {
  case tpl {
    Ok(#(a, b)) -> {
      let match_numbers = intersection(a, b)
      let matches = list.length(match_numbers)
      case matches {
        0 -> Ok(0)
        _ -> Ok(int.bitwise_shift_left(1, matches - 1))
      }
    }
    Error(v) -> Error(v)
  }
}
