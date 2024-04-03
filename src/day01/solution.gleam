import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import aoc2023_gleam

pub fn main() {
  let filename = "inputs/day01.txt"

  let lines_result = aoc2023_gleam.read_lines(from: filename)
  case lines_result {
    Ok(lines) -> {
      // If the file was converting into a list of lines
      // successfully then run each part of the problem
      io.println("Part 1: " <> solve_p1(lines))
      io.println("Part 2: " <> solve_p2(lines))
    }
    Error(_) -> io.println("Error reading file")
  }
}

// Part 1
pub fn solve_p1(lines: List(String)) -> String {
  // Get list of digits in file as ints
  list.map(lines, extract_numerals)
  // Create a two digit number from first and last digits (Result)
  |> list.map(two_digit_result)
  // Turn list of results into result of list
  |> result.all
  // Sum up list
  |> result.map(list.fold(_, from: 0, with: fn(b, a) { b + a }))
  // Turn sum into string
  |> result.map(int.to_string)
  // If there was an Error report it
  |> result.unwrap("error running part 1")
}

// Part 2
pub fn solve_p2(lines: List(String)) -> String {
  // Extract digits and number words as list of integers
  list.map(lines, extract_numbers)
  // Create a two digit number from first and last digits (Result)
  |> list.map(two_digit_result)
  // Turn list of results into result of list
  |> result.all
  // Sum up list
  |> result.map(list.fold(_, from: 0, with: fn(b, a) { b + a }))
  // Turn sum into string
  |> result.map(int.to_string)
  // If there was an Error report it
  |> result.unwrap("error running part 2")
}

pub fn extract_numerals(line: String) -> List(Int) {
  // Take all the UTF codepoints and only keep those for the integers 0-9
  let characters = string.to_utf_codepoints(line)
  let codepoints =
    list.filter(characters, keeping: fn(g) {
      string.utf_codepoint_to_int(g) >= 48
      && string.utf_codepoint_to_int(g) <= 57
    })

  // Convert to integers and subtract off 48 (codepoint of 0)
  list.map(codepoints, fn(g) { string.utf_codepoint_to_int(g) - 48 })
}

pub fn two_digit_result(numbers: List(Int)) -> Result(Int, Nil) {
  // Get the first and last elements of list (may be the same)
  // and create a two digit number from them
  use f <- result.try(list.first(numbers))
  use l <- result.try(list.last(numbers))
  Ok(f * 10 + l)
}

pub fn extract_numbers(line: String) -> List(Int) {
  // This is a hack to put digits within the number words while allowing
  // for these words to overlap, such as oneight or eighthree.
  let line = string.replace(line, "one", "o1e")
  let line = string.replace(line, "two", "t2o")
  let line = string.replace(line, "three", "t3ree")
  let line = string.replace(line, "four", "f4ur")
  let line = string.replace(line, "five", "f5ve")
  let line = string.replace(line, "six", "s6x")
  let line = string.replace(line, "seven", "s7ven")
  let line = string.replace(line, "eight", "e8ght")
  let line = string.replace(line, "nine", "n9ne")
  extract_numerals(line)
}
