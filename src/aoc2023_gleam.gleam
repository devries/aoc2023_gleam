import gleam/io
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  io.println(
    "Use \"gleam run -m dayXX/solution\" to run the solution\nfrom a particular day.\n\nFor example:\n    gleam run -m day01/solution",
  )
}

/// Read Advent of Code input file and split into a list of lines.
pub fn read_lines(
  from filepath: String,
) -> Result(List(String), simplifile.FileError) {
  simplifile.read(from: filepath)
  // Be sure to get rid of final newline
  |> result.map(string.trim)
  |> result.map(string.split(_, "\n"))
}

pub fn solution_or_error(v: Result(String, String)) -> String {
  case v {
    Ok(solution) -> solution
    Error(error) -> "ERROR: " <> error
  }
}
