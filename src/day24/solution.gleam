import aoc2023_gleam
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/order.{Eq, Gt, Lt}
import gleam/result
import gleam/string

pub fn main() {
  let filename = "inputs/day24.txt"

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
// 33496 is too high
pub fn solve_p1(lines: List(String)) -> Result(String, String) {
  solve_p1_with_limits(lines, 200_000_000_000_000.0, 400_000_000_000_000.0)
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  Error("Unimplemented")
}

pub fn solve_p1_with_limits(
  lines: List(String),
  min: Float,
  max: Float,
) -> Result(String, String) {
  list.map(lines, parse_line)
  |> result.values
  |> list.combination_pairs
  |> list.map(fn(c) { forward_intersection(c.0, c.1) })
  |> result.values
  |> list.filter(fn(pt) { within_zone(pt.0, pt.1, min, max) })
  |> list.length
  |> int.to_string
  |> Ok
}

type Vector {
  Vector(x: Int, y: Int, z: Int)
}

type Trajectory {
  Trajectory(position: Vector, velocity: Vector)
}

fn parse_line(line: String) -> Result(Trajectory, String) {
  case string.split(line, on: " @ ") {
    [position, velocity] -> {
      use pos_result <- result.try(parse_vector(position))
      use vel_result <- result.try(parse_vector(velocity))
      Ok(Trajectory(pos_result, vel_result))
    }
    _ -> Error("Unable to parse: " <> line)
  }
}

fn parse_vector(vec: String) -> Result(Vector, String) {
  case string.split(vec, on: ", ") {
    [xs, ys, zs] -> {
      let xr =
        string.trim(xs)
        |> int.parse
      let yr =
        string.trim(ys)
        |> int.parse
      let zr =
        string.trim(zs)
        |> int.parse
      case xr, yr, zr {
        Ok(x), Ok(y), Ok(z) -> Ok(Vector(x, y, z))
        _, _, _ -> Error("Unable to parse: " <> vec)
      }
    }
    _ -> Error("Unable to parse: " <> vec)
  }
}

fn forward_intersection(
  a: Trajectory,
  b: Trajectory,
) -> Result(#(Float, Float), Nil) {
  let m_a = int.to_float(a.velocity.y) /. int.to_float(a.velocity.x)
  let m_b = int.to_float(b.velocity.y) /. int.to_float(b.velocity.x)

  case m_a == m_b {
    True -> Error(Nil)
    False -> {
      let x =
        {
          m_a
          *. int.to_float(a.position.x)
          -. m_b
          *. int.to_float(b.position.x)
          +. int.to_float(b.position.y)
          -. int.to_float(a.position.y)
        }
        /. { m_a -. m_b }
      let y =
        int.to_float(a.position.y) +. m_a *. { x -. int.to_float(a.position.x) }

      case past_present_future(a, x, y), past_present_future(b, x, y) {
        Gt, Gt -> Ok(#(x, y))
        _, _ -> Error(Nil)
      }
    }
  }
}

fn past_present_future(t: Trajectory, x: Float, y: Float) -> order.Order {
  case
    int.compare(t.velocity.x, 0),
    int.compare(t.velocity.y, 0),
    float.compare(x, int.to_float(t.position.x)),
    float.compare(y, int.to_float(t.position.y))
  {
    Eq, Eq, _, _ -> Eq
    Gt, _, Lt, _ -> Lt
    Lt, _, Gt, _ -> Lt
    _, Gt, _, Lt -> Lt
    _, Lt, _, Gt -> Lt
    _, _, _, _ -> Gt
  }
}

fn within_zone(x: Float, y: Float, min: Float, max: Float) {
  x >=. min && x <=. max && y >=. min && y <=. max
}
