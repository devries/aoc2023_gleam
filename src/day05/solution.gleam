import gleam/io
import gleam/int
import gleam/list
import gleam/result
// import gleam/set
import gleam/string
import aoc2023_gleam

pub fn main() {
  let filename = "inputs/day05.txt"

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
  let sections = split_by_empty_strings(lines, [])
  let #(seedinfo, conversiontableinfo) = list.split(sections, 1)

  // Get seed information out of seedinfo
  use seedresult <- result.try({
    list.flatten(seedinfo)
    |> list.first
    |> result.replace_error("Unable to find seed line")
  })

  use #(_, seedlist) <- result.try({
    string.split_once(seedresult, ": ")
    |> result.replace_error("Unable to split " <> seedresult <> " on colon")
  })

  use seeds <- result.try(parse_numberlist(seedlist))

  // get conversion tables out of conversiontables
  let conversion_tables =
    list.map(conversiontableinfo, list.map(_, parse_numberlist))
    |> list.map(result.values)

  let smallest =
    list.map(seeds, convert_series(conversion_tables, _))
    |> result.values
    |> min_list

  Ok(int.to_string(smallest))
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  let sections = split_by_empty_strings(lines, [])
  let #(seedinfo, conversiontableinfo) = list.split(sections, 1)

  // Get seed information out of seedinfo
  use seedresult <- result.try({
    list.flatten(seedinfo)
    |> list.first
    |> result.replace_error("Unable to find seed line")
  })

  use #(_, seedlist) <- result.try({
    string.split_once(seedresult, ": ")
    |> result.replace_error("Unable to split " <> seedresult <> " on colon")
  })

  use _seeds <- result.try(parse_numberlist(seedlist))

  // get conversion tables out of conversiontables
  let _conversion_tables =
    list.map(conversiontableinfo, list.map(_, parse_numberlist))
    |> list.map(result.values)

  Error("Unimplemented")
}

// Split into sublists around empty strings
fn split_by_empty_strings(
  lines: List(String),
  acc: List(List(String)),
) -> List(List(String)) {
  let #(head, tail) = list.split_while(lines, fn(ln) { ln != "" })
  case tail {
    [] -> list.reverse([head, ..acc])
    _ -> {
      let #(_, rest) = list.split(tail, 1)
      split_by_empty_strings(rest, [head, ..acc])
    }
  }
}

// Parse a space separated list of numbers
fn parse_numberlist(numberlist: String) -> Result(List(Int), String) {
  string.split(numberlist, " ")
  |> list.filter(fn(s: String) { s != "" })
  |> list.map(int.parse)
  |> result.all
  |> result.replace_error(
    numberlist <> " is not a space separated list of integers",
  )
}

// Use conversion table to find value
fn convert(conversion: List(List(Int)), value: Int) -> Result(Int, String) {
  case conversion {
    [] -> Ok(value)
    [first, ..rest] -> {
      case first {
        [destination, start, length] -> {
          let end = start + length
          case value {
            _ if value >= start && value < end ->
              Ok(value + destination - start)
            _ -> convert(rest, value)
          }
        }
        _ -> Error("Bad conversion array")
      }
    }
  }
}

// Use series of conversions to find value
fn convert_series(
  conversions: List(List(List(Int))),
  seed: Int,
) -> Result(Int, String) {
  case conversions {
    [] -> Ok(seed)
    [first, ..rest] -> {
      let newseed = convert(first, seed)
      result.try(newseed, convert_series(rest, _))
    }
  }
}

// Find minimum from list
fn min_list(values: List(Int)) -> Int {
  case values {
    [] -> 0
    [only] -> only
    [first, ..rest] -> list.fold(rest, first, int.min)
  }
}
