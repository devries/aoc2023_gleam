import gleam/list

pub opaque type Tree(element) {
  Null
  Node(
    key: Int,
    payload: element,
    s: Int,
    left: Tree(element),
    right: Tree(element),
  )
}

fn merge(a: Tree(element), b: Tree(element)) -> Tree(element) {
  case a, b {
    Null, Null -> Null
    Null, _ -> b
    _, Null -> a
    Node(a_key, a_payload, _, a_left, a_right), Node(b_key, _, _, _, _) -> {
      case a_key > b_key {
        True -> merge(b, a)
        False -> {
          let newright = merge(a_right, b)
          case a_left, newright {
            Null, Node(_, _, _, _, _) ->
              Node(
                key: a_key,
                payload: a_payload,
                s: 1,
                left: newright,
                right: a_left,
              )
            Node(_, _, l_s, _, _), Node(_, _, r_s, _, _) if l_s < r_s ->
              Node(
                key: a_key,
                payload: a_payload,
                s: l_s + 1,
                left: newright,
                right: a_left,
              )
            _, Node(_, _, r_s, _, _) ->
              Node(
                key: a_key,
                payload: a_payload,
                s: r_s + 1,
                left: a_left,
                right: newright,
              )
            _, _ -> Null
          }
        }
      }
    }
  }
}

pub fn new() -> Tree(element) {
  Null
}

pub fn push(a: Tree(element), value: Int, payload: element) -> Tree(element) {
  let b = Node(value, payload, 1, Null, Null)
  merge(a, b)
}

pub fn push_list(
  a: Tree(element),
  values: List(#(Int, element)),
) -> Tree(element) {
  case values {
    [] -> a
    [first, ..rest] -> {
      let n = push(a, first.0, first.1)
      push_list(n, rest)
    }
  }
}

pub fn pop(a: Tree(element)) -> Result(#(Tree(element), Int, element), Nil) {
  case a {
    Null -> Error(Nil)
    Node(val, payload, _, left, right) ->
      Ok(#(merge(left, right), val, payload))
  }
}

pub fn getall(a: Tree(element)) -> List(#(Int, element)) {
  popall(a, [])
}

fn popall(a: Tree(element), acc: List(#(Int, element))) -> List(#(Int, element)) {
  let r = pop(a)
  case r {
    Error(_) -> list.reverse(acc)
    Ok(#(t, v, p)) -> {
      popall(t, [#(v, p), ..acc])
    }
  }
}
