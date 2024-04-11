import gleam/dict
import gleam/io
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import aoc2023_gleam
import internal/lheap

pub fn main() {
  let filename = "inputs/day17.txt"

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
  use mapvalues <- result.try(parse_map(lines))

  let flat_values = list.flatten(mapvalues)

  let lp_result = list.last(flat_values)
  use #(endpoint, _) <- result.try(result.replace_error(
    lp_result,
    "no points found",
  ))

  let map = dict.from_list(flat_values)

  let starting_conditions = [
    #(0, Node(Point(0, 0), Right)),
    #(0, Node(Point(0, 0), Down)),
  ]

  let heap = lheap.insert_list(lheap.new(), starting_conditions)
  let endnode =
    find_endpoint_part1(map, heap, endpoint, dict.new())
    |> result.replace_error("Error in main loop")
  case endnode {
    Error(s) -> Error(s)
    Ok(#(val, _)) -> Ok(int.to_string(val))
  }
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  use mapvalues <- result.try(parse_map(lines))

  let flat_values = list.flatten(mapvalues)

  let lp_result = list.last(flat_values)
  use #(endpoint, _) <- result.try(result.replace_error(
    lp_result,
    "no points found",
  ))

  let map = dict.from_list(flat_values)

  let starting_conditions = [
    #(0, Node(Point(0, 0), Right)),
    #(0, Node(Point(0, 0), Down)),
  ]

  let heap = lheap.insert_list(lheap.new(), starting_conditions)
  let endnode =
    find_endpoint_part2(map, heap, endpoint, dict.new())
    |> result.replace_error("Error in main loop")
  case endnode {
    Error(s) -> Error(s)
    Ok(#(val, _)) -> Ok(int.to_string(val))
  }
}

type Point {
  Point(x: Int, y: Int)
}

type Direction {
  Up
  Down
  Left
  Right
}

type Node {
  Node(position: Point, direction: Direction)
}

fn parse_map(lines: List(String)) -> Result(List(List(#(Point, Int))), String) {
  let values_result =
    list.map(lines, parse_line)
    |> result.all

  use values <- result.map(values_result)

  use line, y <- list.index_map(values)
  use v, x <- list.index_map(line)
  #(Point(x, y), v)
}

fn parse_line(line: String) -> Result(List(Int), String) {
  string.to_graphemes(line)
  |> list.map(int.parse)
  |> result.all
  |> result.replace_error("Unable to parse line: " <> line)
}

fn steps_along(position: Point, direction: Direction, steps: Int) -> List(Point) {
  steps_along_acc(position, direction, steps, [])
  |> list.reverse
}

fn steps_along_acc(
  position: Point,
  direction: Direction,
  steps: Int,
  acc: List(Point),
) -> List(Point) {
  case steps {
    0 -> acc
    _ -> {
      let np = case direction {
        Up -> Point(position.x, position.y - 1)
        Down -> Point(position.x, position.y + 1)
        Left -> Point(position.x - 1, position.y)
        Right -> Point(position.x + 1, position.y)
      }
      steps_along_acc(np, direction, steps - 1, [np, ..acc])
    }
  }
}

fn cooling_along(
  map: dict.Dict(Point, Int),
  position: Point,
  direction: Direction,
  steps: Int,
  initial_cooling: Int,
) -> List(#(Int, Node)) {
  let pts = steps_along(position, direction, steps)

  let #(_, coolings) =
    result.values(list.map(pts, dict.get(map, _)))
    |> list.map_fold(initial_cooling, fn(acc, value) {
      #(acc + value, acc + value)
    })

  let nodes = list.map(pts, fn(p) { Node(p, direction) })
  list.zip(coolings, nodes)
}

fn find_endpoint_part1(
  map: dict.Dict(Point, Int),
  heap: lheap.Tree(Node),
  endpoint: Point,
  minmap: dict.Dict(Node, Int),
) -> Result(#(Int, Node), Nil) {
  use #(newheap, cooling, node) <- result.try(lheap.pop(heap))

  let pos = node.position
  let dir = node.direction
  case pos == endpoint {
    True -> Ok(#(cooling, node))

    False -> {
      let best = dict.get(minmap, node)
      case best {
        Ok(n) if n < cooling ->
          find_endpoint_part1(map, newheap, endpoint, minmap)
        _ -> {
          let newdirs = case dir {
            Up | Down -> [Left, Right]
            Left | Right -> [Up, Down]
          }

          let potentials =
            list.map(newdirs, cooling_along(map, pos, _, 3, cooling))
            |> list.flatten
            |> list.filter(fn(next) {
              let current = dict.get(minmap, next.1)
              case current {
                Ok(v) if next.0 >= v -> False
                _ -> True
              }
            })

          let newminmap =
            list.fold(potentials, minmap, fn(m, n) { dict.insert(m, n.1, n.0) })

          let newheap = lheap.insert_list(newheap, potentials)

          find_endpoint_part1(map, newheap, endpoint, newminmap)
        }
      }
    }
  }
}

fn find_endpoint_part2(
  map: dict.Dict(Point, Int),
  heap: lheap.Tree(Node),
  endpoint: Point,
  minmap: dict.Dict(Node, Int),
) -> Result(#(Int, Node), Nil) {
  use #(newheap, cooling, node) <- result.try(lheap.pop(heap))

  let pos = node.position
  let dir = node.direction
  case pos == endpoint {
    True -> Ok(#(cooling, node))

    False -> {
      let best = dict.get(minmap, node)
      case best {
        Ok(n) if n < cooling ->
          find_endpoint_part2(map, newheap, endpoint, minmap)
        _ -> {
          let newdirs = case dir {
            Up | Down -> [Left, Right]
            Left | Right -> [Up, Down]
          }

          let potentials =
            list.map(newdirs, fn(d) {
              cooling_along(map, pos, d, 10, cooling)
              |> list.drop(3)
            })
            |> list.flatten
            |> list.filter(fn(next) {
              let current = dict.get(minmap, next.1)
              case current {
                Ok(v) if next.0 >= v -> False
                _ -> True
              }
            })

          let newminmap =
            list.fold(potentials, minmap, fn(m, n) { dict.insert(m, n.1, n.0) })

          let newheap = lheap.insert_list(newheap, potentials)

          find_endpoint_part2(map, newheap, endpoint, newminmap)
        }
      }
    }
  }
}
