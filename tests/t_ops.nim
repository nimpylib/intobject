

import std/unittest
import intobject

suite "ops":
  test "bitwise":
    const hi = uint64.high
    let oneWithZeros = (hi.newInt + 1)
    check (oneWithZeros and hi) == 0
    check (oneWithZeros shr 64) == 1

    template t(x) =
      check x.not == -x-1
    for i in countup(hi.newInt, 100+hi.newInt):
      t i

