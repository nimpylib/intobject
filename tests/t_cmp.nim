
import std/unittest
import intobject

suite "cmp":
  # thanks to Nim's `>` -> not `<`, etc.
  #  we only need to test `<`/`>` and `==`
  test "cmp of small ints":
    let i1 = newInt(5)
    let i2 = newInt(10)
    check i1 < i2
    check i1 <= i2
    check i1 != i2
  test "cmp of equal ints":
    let i1 = newInt(5)
    let i2 = newInt(5)
    check not (i1 < i2)
    check i1 <= i2
    check i1 >= i2
    check i1 == i2
  test "cmp of large ints":
    let i1 = 12345678901234567891234567890'iobj
    let i2 = 12345678901234567891234567891'iobj
    check i1 < i2
    check i1 <= i2
    check i1 != i2
  test "cmp of negative ints":
    let i1 = newInt(-5)
    let i2 = newInt(-10)
    check i1 > i2
    check i1 >= i2
    check i1 != i2
