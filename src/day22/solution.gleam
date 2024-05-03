import aoc2023_gleam
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string

pub fn main() {
  let filename = "inputs/day22.txt"

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
  use bricks <- result.map(
    list.map(lines, parse_line)
    |> result.all,
  )
  // This is sorted from top to bottom, we will want bottom to top
  let sorted_bricks =
    list.sort(bricks, fn(b1, b2) { int.compare(b1.zmin, b2.zmin) })

  let dropped_bricks = drop_all_bricks(sorted_bricks, [])

  let protected_count =
    protected_bricks(dropped_bricks, set.new())
    |> set.size

  list.length(dropped_bricks) - protected_count
  |> int.to_string
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  use bricks <- result.map(
    list.map(lines, parse_line)
    |> result.all,
  )
  // This is sorted from top to bottom, we will want bottom to top
  let sorted_bricks =
    list.sort(bricks, fn(b1, b2) { int.compare(b1.zmin, b2.zmin) })

  let dropped_bricks = drop_all_bricks(sorted_bricks, [])

  let bricks_to_destroy = protected_bricks(dropped_bricks, set.new())

  let brick_set = set.from_list(dropped_bricks)

  // This is slow, but it removes the one brick, then sorts the bricks
  // and counts the number that drop with that brick removed
  set.to_list(bricks_to_destroy)
  |> list.map(fn(destroyed_brick) {
    set.delete(brick_set, destroyed_brick)
    |> set.to_list
    |> list.sort(fn(b1, b2) { int.compare(b1.zmin, b2.zmin) })
    |> count_dropped_bricks([], 0)
  })
  |> int.sum
  |> int.to_string
}

type Point {
  Point(x: Int, y: Int, z: Int)
}

type Brick {
  Brick(xmin: Int, xmax: Int, ymin: Int, ymax: Int, zmin: Int, zmax: Int)
}

fn make_brick(p1: Point, p2: Point) -> Brick {
  let xmin = int.min(p1.x, p2.x)
  let xmax = int.max(p1.x, p2.x)
  let ymin = int.min(p1.y, p2.y)
  let ymax = int.max(p1.y, p2.y)
  let zmin = int.min(p1.z, p2.z)
  let zmax = int.max(p1.z, p2.z)

  Brick(xmin, xmax, ymin, ymax, zmin, zmax)
}

fn parse_line(ln: String) -> Result(Brick, String) {
  let parts =
    string.split(ln, "~")
    |> list.map(parse_point)

  case parts {
    [Ok(p1), Ok(p2)] -> Ok(make_brick(p1, p2))
    _ -> Error("Unable to parse " <> ln)
  }
}

fn parse_point(pt: String) -> Result(Point, String) {
  let parts =
    string.split(pt, ",")
    |> list.map(int.parse)
    |> result.all

  case parts {
    Ok([x, y, z]) -> Ok(Point(x, y, z))
    Error(Nil) -> Error("Unable to parse integers in point " <> pt)
    _ -> Error("Unable to parse " <> pt)
  }
}

fn overlaps(b: Brick, below: List(Brick)) -> List(Brick) {
  case below {
    [first, ..rest] -> {
      case overlap(b, first) {
        True -> [first, ..overlaps(b, rest)]
        False -> overlaps(b, rest)
      }
    }
    [] -> []
  }
}

fn overlap(a: Brick, b: Brick) -> Bool {
  int.max(a.xmin, b.xmin) <= int.min(a.xmax, b.xmax)
  && int.max(a.ymin, b.ymin) <= int.min(a.ymax, b.ymax)
}

// sort floaters from lowest to highest zmin
fn drop_all_bricks(floating: List(Brick), dropped: List(Brick)) -> List(Brick) {
  case floating {
    [] -> dropped
    [lowest, ..rest] -> {
      let newpos = case overlaps(lowest, dropped) {
        [] ->
          Brick(
            lowest.xmin,
            lowest.xmax,
            lowest.ymin,
            lowest.ymax,
            1,
            lowest.zmax - lowest.zmin + 1,
          )
        lappers -> {
          let maxz =
            list.fold(lappers, 0, fn(acc, brick) { int.max(acc, brick.zmax) })
          Brick(
            lowest.xmin,
            lowest.xmax,
            lowest.ymin,
            lowest.ymax,
            maxz + 1,
            lowest.zmax - lowest.zmin + maxz + 1,
          )
        }
      }
      drop_all_bricks(rest, [newpos, ..dropped])
    }
  }
}

// Bricks that cannot be disintegrated without structural issues
// Resting bricks are sorted from top to bottom
fn protected_bricks(
  resting_bricks: List(Brick),
  protected_set: set.Set(Brick),
) -> set.Set(Brick) {
  case resting_bricks {
    [] -> protected_set
    [first, ..rest] -> {
      let supporters =
        overlaps(first, rest)
        // Filter only those directly below
        |> list.filter(fn(b) { b.zmax == first.zmin - 1 })
      case supporters {
        // Add the sole supporter
        [s] -> protected_bricks(rest, set.insert(protected_set, s))
        // there are no or more than 1 support
        _ -> protected_bricks(rest, protected_set)
      }
    }
  }
}

// sort floaters from lowest to highest zmin
fn count_dropped_bricks(
  floating: List(Brick),
  dropped: List(Brick),
  count: Int,
) -> Int {
  case floating {
    [] -> count
    [lowest, ..rest] -> {
      let newpos = case overlaps(lowest, dropped) {
        [] ->
          Brick(
            lowest.xmin,
            lowest.xmax,
            lowest.ymin,
            lowest.ymax,
            1,
            lowest.zmax - lowest.zmin + 1,
          )
        lappers -> {
          let maxz =
            list.fold(lappers, 0, fn(acc, brick) { int.max(acc, brick.zmax) })
          Brick(
            lowest.xmin,
            lowest.xmax,
            lowest.ymin,
            lowest.ymax,
            maxz + 1,
            lowest.zmax - lowest.zmin + maxz + 1,
          )
        }
      }
      let newcount = case lowest == newpos {
        True -> count
        False -> count + 1
      }
      count_dropped_bricks(rest, [newpos, ..dropped], newcount)
    }
  }
}
