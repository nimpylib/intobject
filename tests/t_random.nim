
import std/unittest
import std/random
import intobject

randomize()

suite "random":
  test "random int":
    for i in [0, 1, 9, 32, 33, 64, 65,]:
      let io = randbits(i)
      check io.numbits <= i
