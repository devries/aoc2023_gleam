import internal/lheap
import gleam/dict
import gleam/option.{type Option, None, Some}
import gleam/result

// Since reprioritizing nodes is difficult and expensive in a leftist heap
// I track the minimum distance for each element and the previous node.
// If push a value that has a distance greater than or equal to the
// minimum seen, I just drop that element. If I pop one that is not the
// smallest distance seen I discard it and pop another.

pub opaque type Queue(element) {
  Queue(
    heap: lheap.Tree(element),
    minmap: dict.Dict(element, #(Int, Option(element))),
  )
}

pub fn new() -> Queue(element) {
  Queue(heap: lheap.new(), minmap: dict.new())
}

pub fn push(
  queue: Queue(element),
  distance: Int,
  node: element,
  previous_node: Option(element),
) -> Queue(element) {
  case dict.get(queue.minmap, node) {
    Ok(#(n, _)) if n <= distance -> queue
    _ -> {
      let newminmap =
        dict.insert(queue.minmap, node, #(distance, previous_node))
      let newheap = lheap.push(queue.heap, distance, node)
      Queue(heap: newheap, minmap: newminmap)
    }
  }
}

pub fn push_list(
  queue: Queue(element),
  values: List(#(Int, element)),
  previous_node: Option(element),
) -> Queue(element) {
  case values {
    [] -> queue
    [first, ..rest] -> {
      let newqueue = push(queue, first.0, first.1, previous_node)
      push_list(newqueue, rest, previous_node)
    }
  }
}

pub fn pop(
  queue: Queue(element),
) -> Result(#(Queue(element), Int, element), Nil) {
  use #(newheap, distance, node) <- result.try(lheap.pop(queue.heap))

  let newqueue = Queue(heap: newheap, minmap: queue.minmap)

  // check if this is the lowest distance variant of this node
  // if it is not go on to the next one. This eliminates leftover
  // elements which were added before better ones were found.
  let best_result = dict.get(queue.minmap, node)
  case best_result {
    Ok(#(best, _)) if best < distance -> pop(newqueue)
    _ -> Ok(#(newqueue, distance, node))
  }
}

pub fn get_path(
  queue: Queue(element),
  ending: element,
) -> Result(List(element), Nil) {
  get_path_acc(queue, ending, [ending])
}

fn get_path_acc(
  queue: Queue(element),
  ending: element,
  acc: List(element),
) -> Result(List(element), Nil) {
  case dict.get(queue.minmap, ending) {
    Error(Nil) -> Error(Nil)
    Ok(#(_, None)) -> Ok(acc)
    Ok(#(_, Some(node))) -> get_path_acc(queue, node, [node, ..acc])
  }
}
