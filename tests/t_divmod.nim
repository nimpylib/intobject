

import std/unittest
import intobject

suite "divmod":
  template tCeilDiv(a, b): untyped =
    ceilDiv(newInt(a), newInt(b))
  test "divmod of small ints":
    check tCeilDiv( 12,  3) ==  4
    check tCeilDiv( 13,  3) ==  5
    check tCeilDiv(-13,  3) == -4
    check tCeilDiv( 13, -3) == -4
    check tCeilDiv(-13, -3) ==  5
