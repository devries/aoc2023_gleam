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

  use seeds <- result.try(parse_numberlist(seedlist))
  use seed_ranges <- result.try(find_seed_ranges(seeds, []))

  // get conversion tables out of conversiontables
  let conversion_tables =
    list.map(conversiontableinfo, list.map(_, parse_numberlist))
    |> list.map(result.values)

  use final_ranges <- result.try(whole_range_conversion_series(
    conversion_tables,
    seed_ranges,
  ))

  let smallest =
    list.map(final_ranges, fn(a) { a.0 })
    |> min_list

  Ok(int.to_string(smallest))
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
          let in_range = value >= start && value < end
          case in_range {
            True -> Ok(value + destination - start)
            False -> convert(rest, value)
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

fn find_seed_ranges(
  seedlist: List(Int),
  acc: List(#(Int, Int)),
) -> Result(List(#(Int, Int)), String) {
  case seedlist {
    [] -> Ok(acc)
    [_] -> Error("Odd number of values in seed list")
    [start, length, ..rest] -> find_seed_ranges(rest, [#(start, length), ..acc])
  }
}

type Location {
  Below
  Within
  Above
}

fn find_location(point: Int, start: Int, length: Int) -> Location {
  let below_start = point < start
  let below_end = point < start + length

  case #(below_start, below_end) {
    #(True, _) -> Below
    #(False, True) -> Within
    #(False, False) -> Above
  }
}

fn range_conversion(
  conversion: List(List(Int)),
  range: #(Int, Int),
  acc: List(#(Int, Int)),
) -> Result(List(#(Int, Int)), String) {
  case conversion {
    [] -> Ok([range, ..acc])
    [first, ..rest] -> {
      case first {
        [destination, start, length] -> {
          let low = range.0
          let high = range.0 + range.1
          let low_location = find_location(low, start, length)
          let high_location = find_location(high, start, length)

          case #(low_location, high_location) {
            // no intersection - check, confused
            #(Below, Below) | #(Above, Above) ->
              range_conversion(rest, range, acc)

            // entirely within
            #(Within, Within) -> {
              let newrange = #(range.0 + destination - start, range.1)
              Ok([newrange, ..acc])
            }

            // Intersects bottom of conversion range
            #(Below, Within) -> {
              let transformed_range = #(destination, high - start)
              let ongoing_range = #(low, start - low)
              range_conversion(rest, ongoing_range, [transformed_range, ..acc])
            }

            // Intersects top of conversion range
            #(Within, Above) -> {
              let transformed_range = #(
                low + destination - start,
                start + length - low,
              )
              let ongoing_range = #(start + length, high - start - length)
              range_conversion(rest, ongoing_range, [transformed_range, ..acc])
            }

            // Spans entire range
            #(Below, Above) -> {
              let transformed_range = #(destination, length)
              let lower_ongoing_range = #(low, start - low)
              let higher_ongoing_range = #(
                start + length,
                high - start - length,
              )
              use lower_conversions <- result.try(
                range_conversion(rest, lower_ongoing_range, []),
              )
              use upper_conversions <- result.try(
                range_conversion(rest, higher_ongoing_range, [
                  transformed_range,
                  ..acc
                ]),
              )
              Ok(list.append(lower_conversions, upper_conversions))
            }

            _ -> Error("Unexpected ordering")
          }
        }
        _ -> Error("Bad conversion list")
      }
    }
  }
}

fn whole_range_conversion(
  conversion: List(List(Int)),
  ranges: List(#(Int, Int)),
  acc: List(#(Int, Int)),
) -> Result(List(#(Int, Int)), String) {
  case ranges {
    [] -> Ok(acc)
    [first_range, ..rest_ranges] -> {
      use converted_ranges <- result.try(
        range_conversion(conversion, first_range, []),
      )
      let newacc = list.append(converted_ranges, acc)
      whole_range_conversion(conversion, rest_ranges, newacc)
    }
  }
}

fn whole_range_conversion_series(
  conversion_series: List(List(List(Int))),
  ranges: List(#(Int, Int)),
) -> Result(List(#(Int, Int)), String) {
  case conversion_series {
    [] -> Ok(ranges)
    [first, ..rest] -> {
      use newranges <- result.try(whole_range_conversion(first, ranges, []))
      whole_range_conversion_series(rest, newranges)
    }
  }
}
