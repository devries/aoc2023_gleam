import gleam/io
import gleam/int
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import aoc2023_gleam

pub fn main() {
  let filename = "inputs/day04.txt"

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
  list.map(lines, parse_line)
  |> list.map(result.map(_, score))
  |> result.all
  |> result.map(int.sum)
  |> result.map(int.to_string)
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  list.map(lines, parse_line)
  |> result.all
  |> result.map(initialize_count)
  |> result.map(expand_and_count(_, 0))
  |> result.map(int.to_string)
}

// Parse a line of the input
fn parse_line(line: String) -> Result(#(List(Int), List(Int)), String) {
  // Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
  case string.split(line, on: ": ") {
    [_, scratch_numbers] -> {
      let nls =
        string.split(scratch_numbers, on: " | ")
        |> list.map(parse_numberlist)
      case nls {
        [Ok(a), Ok(b)] -> Ok(#(a, b))
        [Error(a), ..] -> Error(a)
        [Ok(_), Error(b), ..] -> Error(b)
        _ -> Error(scratch_numbers <> " has no number lists in it")
      }
    }
    _ -> Error("unable to split '" <> line <> "' on colon")
  }
}

// Parse a space separated list of numbers
fn parse_numberlist(numberlist: String) -> Result(List(Int), String) {
  string.split(numberlist, " ")
  |> list.filter(fn(s: String) { s != "" })
  |> list.map(int.parse)
  |> result.all
  |> result.replace_error(
    numberlist <> " is not a space separated list of integers",
  )
}

// Find the intersection of two lists (converts to sets and
// back again)
fn intersection(a: List(Int), b: List(Int)) -> List(Int) {
  let a_set = set.from_list(a)
  let b_set = set.from_list(b)

  set.to_list(set.intersection(a_set, b_set))
}

// Score a card using the logic from part 1
fn score(card: #(List(Int), List(Int))) -> Int {
  case count_matches(card) {
    0 -> 0
    n -> int.bitwise_shift_left(1, n - 1)
  }
}

// Count the number of matching values on a card
fn count_matches(card: #(List(Int), List(Int))) -> Int {
  let match_numbers = intersection(card.0, card.1)
  list.length(match_numbers)
}

// For each card count the matches and make a list of tuples of
// the number of matches on a card and the number of cards in the deck
fn initialize_count(cards: List(#(List(Int), List(Int)))) -> List(#(Int, Int)) {
  list.map(cards, count_matches)
  |> list.map(fn(i: Int) -> #(Int, Int) { #(i, 1) })
}

// Expand the list of matches and card counts with the cards won for
// each scratch card, counting the cards as you iterate through the list
fn expand_and_count(card_values: List(#(Int, Int)), acc: Int) -> Int {
  case card_values {
    [] -> acc
    [first, ..rest] -> {
      let matches = first.0
      let copies = first.1
      let #(head, tail) = list.split(rest, matches)
      let newhead =
        list.map(head, fn(a: #(Int, Int)) -> #(Int, Int) {
          #(a.0, a.1 + copies)
        })
      let newlist = list.append(newhead, tail)
      expand_and_count(newlist, copies + acc)
    }
  }
}
