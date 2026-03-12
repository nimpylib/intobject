
from std/math import ceilDiv
import ./bit_length_util
import ./[decl_private, decl]
proc digitCount*(v: IntObject): int{.inline.} = v.digits.len  ## `_PyLong_DigitCount`
proc numbits*(v: IntObject): int64 =
  ## `_PyLong_NumBits`
  ## 
  ## returns the number of bits necessary to represent
  ##   the absolute value of the integer in binary,
  ##   excluding the sign and leading zeros.
  let ndigits = v.digitCount
  #assert ndigits == 0 or 
  if ndigits > 0:
    let ndigits1 = int64 ndigits-1
    let msd = v.digits[ndigits1]
    result = ndigits1 * digitBits
    result += bit_length(msd)

proc byteCount*(v: IntObject): int64 =
  ## returns the number of bytes necessary to represent
  ##   the absolute value of the integer in binary.
  ceilDiv(v.numbits, 8)

proc bit_length*(self: IntObject): IntObject =
  ## int_bit_length_impl
  let nbits = self.numbits
  assert nbits >= 0
  return newInt nbits

proc bit_count*(self: IntObject): IntObject =
  ## equiv to `countSetBits`/`popcount` in std/bitops, but for IntObject
  var res = int64 0
  for d in self.digits:
    res += popcount(d)
  newInt res
