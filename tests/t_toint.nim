
import std/unittest
import intobject
import std/options

suite "toint":
  test "to option":
    let i = 1234567890'iobj
    check toInt[int](i) == some 1234567890

    let j = -12345678901234567890'iobj
    # check toInt[int](j) == none(int)
    check toInt[uint](j) == none(uint)
