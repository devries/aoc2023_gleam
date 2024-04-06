import gleeunit/should
import gleam/string
import day03/solution

const testinput = "467..114..
...*......
..35..633.
......#...
617*......
.....+.58.
..592.....
......755.
...$.*....
.664.598.."

pub fn part1_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p1(lines)
  |> should.equal(Ok("4361"))
}

pub fn part2_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p2(lines)
  |> should.equal(Ok("2286"))
}
