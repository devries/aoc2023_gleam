import aoc2023_gleam
import gleam/dict
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string

pub fn main() {
  let filename = "inputs/day25.txt"

  let lines_result = aoc2023_gleam.read_lines(from: filename)
  case lines_result {
    Ok(lines) -> {
      // If the file was converting into a list of lines
      // successfully then run each part of the problem
      io.println("Part 1: " <> aoc2023_gleam.solution_or_error(solve_p1(lines)))
    }
    Error(_) -> io.println("Error reading file")
  }
}

// Part 1
pub fn solve_p1(lines: List(String)) -> Result(String, String) {
  use parsed_data <- result.try({ list.map(lines, parse_line) |> result.all })

  accumulate_connections(parsed_data, dict.new())
  |> pretty_print

  Error("Incomplete")
}

pub fn parse_line(line: String) -> Result(#(String, set.Set(String)), String) {
  case string.split(line, on: ": ") {
    [source, component_str] -> {
      let components = set.from_list(string.split(component_str, on: " "))
      Ok(#(source, components))
    }
    _ -> Error("Unable to parse: " <> line)
  }
}

pub fn accumulate_connections(
  conn: List(#(String, set.Set(String))),
  connections: dict.Dict(String, set.Set(String)),
) -> dict.Dict(String, set.Set(String)) {
  case conn {
    [] -> connections
    [first, ..rest] -> {
      let new_set = case dict.get(connections, first.0) {
        Ok(v) -> set.union(v, first.1)
        Error(_) -> first.1
      }
      let step_two_dict =
        reverse_connections(#(first.0, set.to_list(first.1)), connections)
      accumulate_connections(rest, dict.insert(step_two_dict, first.0, new_set))
    }
  }
}

pub fn reverse_connections(
  conn: #(String, List(String)),
  connections: dict.Dict(String, set.Set(String)),
) -> dict.Dict(String, set.Set(String)) {
  case conn.1 {
    [] -> connections
    [first, ..rest] -> {
      let new_set = case dict.get(connections, first) {
        Ok(v) -> set.insert(v, conn.0)
        Error(_) -> set.from_list([conn.0])
      }
      reverse_connections(
        #(conn.0, rest),
        dict.insert(connections, first, new_set),
      )
    }
  }
}

pub fn pretty_print(
  conn: dict.Dict(String, set.Set(String)),
) -> dict.Dict(String, set.Set(String)) {
  conn
  |> dict.to_list
  |> list.map(fn(l) {
    let values = set.to_list(l.1)
    io.println(l.0 <> ": " <> string.join(values, with: ", "))
  })

  conn
}
