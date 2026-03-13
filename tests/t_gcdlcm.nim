import std/unittest
import intobject

template gcd(a, b: int): IntObject = gcd(newInt(a), newInt(b))
template lcm(a, b: int): IntObject = lcm(newInt(a), newInt(b))
suite "gcd":
  test "gcd of positive ints":
    check gcd(48, 18) == 6

  test "gcd handles sign":
    check gcd(-48, 18) == 6
    check gcd(48, -18) == 6
    check gcd(-48, -18) == 6

  test "gcd handles zero":
    check gcd(0, 18) == 18
    check gcd(48, 0) == 48
    check gcd(0, 0) == 0

  test "gcd of large ints":
    let a = 12345678901234567890'iobj
    let b = 9876543210'iobj
    check gcd(a, b) == 90

suite "lcm":
  test "lcm of positive ints":
    check lcm(48, 18) == 144

  test "lcm handles sign":
    check lcm(-48, 18) == 144
    check lcm(48, -18) == 144
    check lcm(-48, -18) == 144

  test "lcm handles zero":
    check lcm(0, 18) == 0
    check lcm(48, 0) == 0
    check lcm(0, 0) == 0

  test "lcm of large ints":
    let a = 12345678901234567890'iobj
    let b = 9876543210'iobj
    check lcm(a, b) == 1354807012498094801236261410'iobj
