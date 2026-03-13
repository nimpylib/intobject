
import ./[
  decl, decl_private, ops_basic_arith, ops_bitwise, ops_toint,

]
from std/math import divmod
import std/random

proc randbits*(r: var Rand; k: Natural): IntObject =
  ## Returns a non-negative Python integer with `k` random bits.
  if k == 0:
    return intZero
  if k < 8 * sizeof(int):
    return newInt(r.rand(int(1) shl k - 1))

  result.sign = IntSign.Positive

  let (numDigits, remBits) = divmod(cast[int](k), digitBits)
  let L = numDigits + (if remBits > 0: 1 else: 0)
  result.digits.setLen(L)

  for i in 0 ..< L:
    result.digits[i] = r.rand(Digit)
  # Clear the unused bits in the most significant digit
  if remBits > 0:
    result.digits[^1] = result.digits[^1] shr (digitBits - remBits)

proc randbits*(k: Natural): IntObject = randState().randbits k
