import std/unittest
import intobject

let thirty = newInt 30
let f = newInt 5
suite "factorial":
  test "small values":
    check factorial(newInt 0) == 1
    check factorial(newInt 1) == 1
    check factorial(newInt 5) == 120
    check factorial(newInt 20) == 2432902008176640000'iobj

  test "large value":
    check factorial(thirty) == 265252859812191058636308480000000'iobj

  test "negative":
    expect ValueError:
      discard factorial(newInt -1)

suite "perm":
  test "small values":
    check perm(f) == 120
    check perm(f, 0) == 1
    check perm(f, 1) == 5
    check perm(f, 2) == 20
    check perm(f, 6) == 0

  test "large value":
    check perm(thirty, 10) == 109027350432000'iobj

  test "negative":
    expect ValueError:
      discard perm(-1, intOne)
    expect ValueError:
      discard perm(intOne, -1)

suite "comb":
  test "small values":
    check comb(f, 0) == 1
    check comb(f, 1) == 5
    check comb(f, 2) == 10
    check comb(f, 3) == 10
    check comb(f, 6) == 0

  test "large value":
    check comb(100'iobj, 50) == 100891344545564193334812497256'iobj

  test "negative":
    expect ValueError:
      discard comb(-1, intOne)
    expect ValueError:
      discard comb(intOne, -1)
