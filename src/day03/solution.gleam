import gleam/io
import gleam/int
import gleam/dict
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import aoc2023_gleam

pub fn main() {
  let filename = "inputs/day03.txt"

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
  let board = parse_schematic(lines)
  let symbols = symbol_dict(board)

  let numbers =
    list.filter(board, fn(val) {
      case val {
        #(_, _, Number(_)) -> True
        _ -> False
      }
    })

  let part_numbers =
    list.filter(numbers, fn(val) -> Bool {
      has_symbol(surrounding_points(val), symbols)
    })
    |> list.map(fn(val) -> Int {
      case val {
        #(_, _, Number(n)) -> n
        _ -> 0
      }
    })

  Ok(int.to_string(int.sum(part_numbers)))
}

// Part 2
pub fn solve_p2(_lines: List(String)) -> Result(String, String) {
  Error("Unimplemented")
}

// Parse map
type Point {
  Point(x: Int, y: Int)
}

type Value {
  Number(Int)
  Symbol(String)
}

fn parse_schematic(lines: List(String)) -> List(#(Point, Point, Value)) {
  {
    use line, y <- list.index_map(lines)
    use char, x <- list.index_map(string.to_graphemes(line))
    case char_to_value(char) {
      Ok(v) -> Ok(#(Point(x, y), v))
      Error(Nil) -> Error(Nil)
    }
  }
  |> list.flatten
  |> result.values
  |> consolidate(None, Point(0, 0), Point(0, 0), [])
}

fn char_to_value(char: String) -> Result(Value, Nil) {
  case char, int.parse(char) {
    _, Ok(n) -> Ok(Number(n))
    ".", _ -> Error(Nil)
    c, _ -> Ok(Symbol(c))
  }
}

// This function Takes a list of poisitions and single digit or symbol
// values and consolidates them into a list of tuples of starting position
// and a tuple of ending position and multidigit number value or symbol.
fn consolidate(
  input: List(#(Point, Value)),
  current: Option(Int),
  spt: Point,
  lpt: Point,
  holding: List(#(Point, Point, Value)),
) -> List(#(Point, Point, Value)) {
  case input {
    // match a number square
    [#(p, Number(n)), ..rest] -> {
      case p.y == spt.y && p.x == lpt.x + 1 {
        True ->
          case current {
            None -> consolidate(rest, Some(n), p, p, holding)
            Some(c) -> consolidate(rest, Some(10 * c + n), spt, p, holding)
          }
        False ->
          case current {
            None -> consolidate(rest, Some(n), p, p, holding)
            Some(c) ->
              consolidate(rest, Some(n), p, p, [
                #(spt, lpt, Number(c)),
                ..holding
              ])
          }
      }
    }
    [#(p, Symbol(s)), ..rest] -> {
      case current {
        None -> consolidate(rest, None, p, p, [#(p, p, Symbol(s)), ..holding])
        Some(c) ->
          consolidate(rest, None, p, p, [
            #(p, p, Symbol(s)),
            #(spt, lpt, Number(c)),
            ..holding
          ])
      }
    }
    [] -> {
      case current {
        None -> holding
        Some(c) -> [#(spt, lpt, Number(c)), ..holding]
      }
    }
  }
}

fn symbol_dict(
  schematic: List(#(Point, Point, Value)),
) -> dict.Dict(Point, Value) {
  list.filter(schematic, fn(val) {
    case val {
      #(_, _, Symbol(_)) -> True
      _ -> False
    }
  })
  |> list.map(fn(val) { #(val.0, val.2) })
  |> dict.from_list
}

fn surrounding_points(element: #(Point, Point, Value)) -> List(Point) {
  let start = element.0
  let end = element.1
  let pts =
    list.range(start.x - 1, end.x + 1)
    |> list.map(fn(i: Int) -> List(Point) {
      [Point(i, start.y - 1), Point(i, start.y + 1)]
    })
    |> list.flatten

  [Point(start.x - 1, start.y), Point(end.x + 1, end.y), ..pts]
}

fn has_symbol(pts: List(Point), symbols: dict.Dict(Point, Value)) -> Bool {
  list.any(pts, fn(p: Point) -> Bool {
    case dict.get(symbols, p) {
      Ok(_) -> True
      Error(_) -> False
    }
  })
}
