
import std/unittest
import intobject

suite "pow":
  test "pow of small ints":
    let i = newInt(5)
    check pow(i, 0) == 1
    check pow(i, 1) == 5
    check pow(i, 2) == 25
    check pow(i, 3) == 125

  test "pow of large ints":
    let i = 12345678901234567891234567890'iobj
    check pow(i, 0) == 1
    check pow(i, 1) == i
    check pow(i, 2) == i*i
    check pow(i, 3) == i*i*i
