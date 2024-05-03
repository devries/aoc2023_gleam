import aoc2023_gleam
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string

pub fn main() {
  let filename = "inputs/day23.txt"

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
  let map = parse_map(lines)
  let steps = explore(map, map.start, set.from_list([map.start]), 0)
  Ok(int.to_string(steps))
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  let map = parse_map(lines)
  let steps = explore_noslip(map, map.start, set.from_list([map.start]), 0)
  Ok(int.to_string(steps))
}

type Point {
  Point(x: Int, y: Int)
}

type Direction {
  North
  South
  East
  West
}

type Map {
  Map(start: Point, end: Point, values: dict.Dict(Point, String))
}

fn parse_map(lines: List(String)) -> Map {
  let map = Map(Point(0, 0), Point(0, 0), dict.new())
  use map, line, y <- list.index_fold(lines, map)
  use map, val, x <- list.index_fold(string.to_graphemes(line), map)

  case y, val {
    0, "." ->
      Map(
        Point(x: x, y: -y),
        Point(x: 0, y: 0),
        dict.insert(map.values, Point(x: x, y: -y), val),
      )
    _, "." ->
      Map(
        map.start,
        Point(x: x, y: -y),
        dict.insert(map.values, Point(x: x, y: -y), val),
      )
    _, _ ->
      Map(map.start, map.end, dict.insert(map.values, Point(x: x, y: -y), val))
  }
}

fn step(map: Map, start: Point) -> List(Result(Point, Nil)) {
  use direction <- list.map([South, East, West, North])
  let next = case direction {
    North -> Point(start.x, start.y + 1)
    South -> Point(start.x, start.y - 1)
    East -> Point(start.x + 1, start.y)
    West -> Point(start.x - 1, start.y)
  }
  let val = dict.get(map.values, next)
  case direction, val {
    _, Ok(".") -> Ok(next)
    North, Ok("^") -> Ok(next)
    South, Ok("v") -> Ok(next)
    East, Ok(">") -> Ok(next)
    West, Ok("<") -> Ok(next)
    _, _ -> Error(Nil)
  }
}

fn explore(map: Map, position: Point, seen: set.Set(Point), steps: Int) -> Int {
  let next =
    step(map, position)
    |> result.values
    |> list.filter(fn(p) { !set.contains(seen, p) })

  case position == map.end, next {
    True, _ -> steps
    _, [] -> 0
    _, _ -> {
      list.map(next, fn(np) {
        explore(map, np, set.insert(seen, np), steps + 1)
      })
      |> list.fold(0, int.max)
    }
  }
}

fn step_noslip(map: Map, start: Point) -> List(Result(Point, Nil)) {
  use direction <- list.map([South, East, West, North])
  let next = case direction {
    North -> Point(start.x, start.y + 1)
    South -> Point(start.x, start.y - 1)
    East -> Point(start.x + 1, start.y)
    West -> Point(start.x - 1, start.y)
  }
  let val = dict.get(map.values, next)
  case val {
    Error(_) -> Error(Nil)
    Ok("#") -> Error(Nil)
    _ -> Ok(next)
  }
}

fn explore_noslip(
  map: Map,
  position: Point,
  seen: set.Set(Point),
  steps: Int,
) -> Int {
  let next =
    step_noslip(map, position)
    |> result.values
    |> list.filter(fn(p) { !set.contains(seen, p) })

  case position == map.end, next {
    True, _ -> steps
    _, [] -> 0
    _, _ -> {
      list.map(next, fn(np) {
        explore_noslip(map, np, set.insert(seen, np), steps + 1)
      })
      |> list.fold(0, int.max)
    }
  }
}
