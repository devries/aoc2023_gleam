import day22/solution
import gleam/string
import gleeunit/should

const testinput = "1,0,1~1,2,1
0,0,2~2,0,2
0,2,3~2,2,3
0,0,4~0,2,4
2,0,5~2,2,5
0,1,6~2,1,6
1,1,8~1,1,9"

pub fn part1_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p1(lines)
  |> should.equal(Ok("5"))
}

pub fn part2_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p2(lines)
  |> should.equal(Ok("7"))
}
