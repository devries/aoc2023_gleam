import day24/solution
import gleam/string
import gleeunit/should

const testinput = "19, 13, 30 @ -2,  1, -2
18, 19, 22 @ -1, -1, -2
20, 25, 34 @ -2, -2, -4
12, 31, 28 @ -1, -2, -1
20, 19, 15 @  1, -5, -3"

pub fn part1_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p1_with_limits(lines, 7.0, 27.0)
  |> should.equal(Ok("2"))
}

pub fn part2_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p2(lines)
  |> should.equal(Ok("47"))
}
