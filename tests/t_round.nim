import std/unittest
import intobject

suite "round":

  test "round with non-negative ndigits returns self":
    let x = 987654321'iobj
    check round(x, 0) == x
    check round(x, 2) == x
    check round(x, newInt(5)) == x

  test "round with negative ndigits":
    check round(149'iobj, -2) == 100
    check round(150'iobj, -2) == 200
    check round(151'iobj, -2) == 200
    check round(-149'iobj, -2) == -100
    check round(-150'iobj, -2) == -200
    check round(-151'iobj, -2) == -200

    let x = 12345'iobj
    check round(x, -2'iobj) == 12300
    check round(x, -3'iobj) == 12000

  test "round ties to even":
    check round(15'iobj, -1) == 20
    check round(25'iobj, -1) == 20
    check round(35'iobj, -1) == 40
    check round(-15'iobj, -1) == -20
    check round(-25'iobj, -1) == -20
    check round(-35'iobj, -1) == -40
