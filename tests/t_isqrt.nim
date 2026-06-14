
import std/unittest
import std/sugar
import std/sequtils
import intobject/math
import intobject

template range(st, ed): untyped = st ..< ed
template `**`(a, b): untyped = pow(newInt(a), b)
suite "isqrt":
  test "neg ValueError":
    expect ValueError:
      discard -1'iobj.isqrt
  test "small":
    check 1'iobj.isqrt == 1
    check 82'iobj.isqrt == 9
  test "big":
    # Test a variety of inputs, large and small.
    let test_values = (
      toSeq(0'iobj .. 1000'iobj) &
       toSeq(range(10**6 - 1000, 10**6 + 1000)) &
       collect(
         for e in range(60, 200):
           for i in range(-40, 40):
             2**e + i
       ) &
       @[3**9999, 10**5001]
    )

    for value in test_values:
        let s = isqrt(value)
        check s*s <= value
        check value < (s+1)*(s+1)

