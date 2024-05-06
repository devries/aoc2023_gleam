import aoc2023_gleam
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
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
  let graph = create_graph(map)

  let steps = explore_graph(graph, map.start, map.end, set.new(), 0)

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

fn create_graph(map: Map) -> dict.Dict(Point, List(#(Point, Int))) {
  build_graph(map, [map.start], set.new(), dict.new())
}

fn build_graph(
  map: Map,
  positions: List(Point),
  seen: set.Set(Point),
  graph: dict.Dict(Point, List(#(Point, Int))),
) -> dict.Dict(Point, List(#(Point, Int))) {
  case positions {
    [] -> graph
    [first, ..rest] -> {
      let adjacents = find_adjacent_nodes(map, first)
      let newgraph = dict.insert(graph, first, adjacents)
      let newseen = set.insert(seen, first)

      let to_explore =
        list.map(adjacents, fn(a) { a.0 })
        |> list.filter(fn(found) { !set.contains(newseen, found) })
      build_graph(map, list.append(to_explore, rest), newseen, newgraph)
    }
  }
}

fn find_adjacent_nodes(map: Map, start: Point) -> List(#(Point, Int)) {
  result.values(step_noslip(map, start, option.None))
  |> list.map(fn(first_step) {
    explore_to_node(map, first_step.0, first_step.1, 1)
  })
  |> result.values
}

fn explore_to_node(
  map: Map,
  position: Point,
  direction: Direction,
  steps: Int,
) -> Result(#(Point, Int), Nil) {
  case position {
    p if p == map.start -> Ok(#(position, steps))
    p if p == map.end -> Ok(#(position, steps))
    _ -> {
      let next =
        result.values(step_noslip(map, position, option.Some(direction)))
      case next {
        [#(pos, dir)] -> explore_to_node(map, pos, dir, steps + 1)
        [] -> Error(Nil)
        _ -> Ok(#(position, steps))
      }
    }
  }
}

fn opposite_direction(direction: Direction) -> Direction {
  case direction {
    North -> South
    South -> North
    East -> West
    West -> East
  }
}

fn step_noslip(
  map: Map,
  start: Point,
  direction: option.Option(Direction),
) -> List(Result(#(Point, Direction), Nil)) {
  let to_explore =
    list.filter([South, East, West, North], fn(d) {
      case direction {
        option.None -> True
        option.Some(din) -> !{ opposite_direction(din) == d }
      }
    })
  use direction <- list.map(to_explore)
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
    _ -> Ok(#(next, direction))
  }
}

fn explore_graph(
  graph: dict.Dict(Point, List(#(Point, Int))),
  position: Point,
  endpoint: Point,
  seen: set.Set(Point),
  steps: Int,
) -> Int {
  let assert Ok(next) = dict.get(graph, position)
  let newseen = set.insert(seen, position)
  let next_unseen = list.filter(next, fn(p) { !set.contains(newseen, p.0) })

  case position == endpoint, next_unseen {
    True, _ -> steps
    _, [] -> 0
    _, _ -> {
      list.map(next_unseen, fn(np) {
        explore_graph(graph, np.0, endpoint, newseen, steps + np.1)
      })
      |> list.fold(0, int.max)
    }
  }
}
