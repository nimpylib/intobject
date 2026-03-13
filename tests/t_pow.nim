
import std/strutils
import std/macros

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

  proc intNode(s: NimNode): NimNode = nnkCallStrLit.newTree(ident"newInt", s)
  proc intNode(s: string): NimNode = intNode newLit s
  proc addLine(result: NimNode, base, exp, modu, expected: string|NimNode) =
    let
      base = intNode(base)
      exp =  intNode(exp)
      modu = intNode(modu)
      expected = intNode(expected)
    let call = newCall("pow", base, exp, modu)
    let eq = infix(call, "==", expected)
    result.add newCall("check", eq)
  template testLinesImpl(i; iter; loopDo) =
    result = newStmtList()
    for i in iter:
      loopDo
    result = quote do:
      test `title`:
        `result`

  macro testLines(title: static string, lines) =
    testLinesImpl i, lines:
      i.expectKind nnkCommand
      let expected = i[0]
      result.addLine(i[1], i[2], i[3], expected)

  macro testLinesS(title, s: static string) =
    testLinesImpl i, s.splitLines():
      let line = i.strip()
      if line.len == 0: continue
      let argsRes = line.split(' ')
      let expected = argsRes[0]
      let parts = argsRes[1].split(',')
      result.addLine(parts[0], parts[1], parts[2], expected)

  testLines "pow with modulus":
    8 5,3,13
    -2 2,3,-5
    0 2,3,2

  testLines "pow with negative exponent and modulus":
    4 3,-1,11
    5 3,-2,11

  testLinesS "pow with huge exponent": """
    76 2,1000000000000000000000000000000,100
    1 2,1000000000000000000000000000000,101
    52 2,1000000000000000000000000000000,102
    19 2,1000000000000000000000000000000,103
"""

  test "pow modulus errors":
    expect ValueError:
      discard pow(2, 3, 0)
    expect ValueError:
      discard pow(2, -1, 4)
