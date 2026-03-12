

import std/unittest
import intobject

suite "self assignment operators":
  test "plus or minus":
    var i = newInt(5)
    i += 3
    check i == 8
    i += -2
    check i == 6
    i.inc
    check i == 7
    i.dec 3
    check i == 4

