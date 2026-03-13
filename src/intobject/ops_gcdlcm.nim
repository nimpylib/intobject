
from std/math import gcd
import ./[
  decl_private, decl, ops_toint, ops_bitwise, ops_basic_arith,
  ops_divmod,
  ops_mix_nim,
]

proc gcd*(a, b: IntObject): IntObject =
  var left = abs(a)
  var right = abs(b)

  if left.digits.len == 0:
    return right
  if right.digits.len == 0:
    return left

  var leftU, rightU: BiggestUInt
  if left.absToUInt(leftU) and right.absToUInt(rightU):
    return newInt(gcd(leftU, rightU))

  var shift = 0
  while isEven(left) and isEven(right):
    left = left shr 1
    right = right shr 1
    inc shift

  while isEven(left):
    left = left shr 1

  while right.digits.len != 0:
    while isEven(right):
      right = right shr 1
    if right < left:
      swap left, right
    right = right - left

  left shl shift

proc lcm*(a, b: IntObject): IntObject =
  if a.isZero or b.isZero:
    return intZero
  abs(a // gcd(a, b) * b)
