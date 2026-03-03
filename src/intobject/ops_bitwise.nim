
# import ../numobjects_comm
from std/math import divmod
import ./private/utils
import ./decl
export decl except Digit, TwoDigits, SDigit, digitBits, truncate,
 IntSign
import ./[
  signbit,
  utils,
]
import ./[ops_toint, ops_basic_arith,]

using self: IntObject
proc `not`*(self): IntObject =
  ## long_invert
  result = self + intOne
  result.negate


const PyLong_MASK = Digit.high #(Digit(1) shl (sizeof(Digit)*8)) - 1
proc vComplement(z: var openArray[Digit], a: openArray[Digit], m: int) =
  ## Compute two's complement of digit vector a[0:m], writing result to
  ## z[0:m]. The digit vector a need not be normalized, but should not
  ## be entirely zero. a and z may point to the same digit vector.
  var carry: Digit = 1
  let hi = m - 1
  for i in 0..hi:
    z[i] = not a[i] + carry
    if z[i] < carry:  # Check for overflow to propagate carry
      carry = 1
    else:
      carry = 0

proc longBitwise(a: IntObject, op: static[char], b: IntObject): IntObject =
  ## Bitwise and/xor/or operations
  var
    a = a
    b = b
    sizeA = digitCount(a)
    sizeB = digitCount(b)
    nega = a.negative()
    negb = b.negative()
    sizeZ: int
    negz: bool
    z: IntObject

  # Convert arguments from sign-magnitude to two's complement
  if nega:
    z = newIntOfLen(sizeA)
    vComplement(z.digits, a.digits, sizeA)
    a = z

  if negb:
    z = newIntOfLen(sizeB)
    vComplement(z.digits, b.digits, sizeB)
    b = z

  # Swap a and b if necessary to ensure sizeA >= sizeB
  if sizeA < sizeB:
    swap(a, b)
    swap(sizeA, sizeB)
    swap(nega, negb)

  # Determine size and sign of result
  case op:
  of '^':
    negz = nega xor negb
    sizeZ = sizeA
  of '&':
    negz = nega and negb
    sizeZ = if negb: sizeA else: sizeB
  of '|':
    negz = nega or negb
    sizeZ = if negb: sizeB else: sizeA
  else: unreachable

  # Allocate result
  z = newIntOfLen(sizeZ + int negz)

  template doOp(op) =
    for i in 0..<sizeB:
      z.digits[i] = op(a.digits[i], b.digits[i])
  # Compute digits for overlap of a and b
  case op
  of '&': doOp `and`
  of '|': doOp `or`
  of '^': doOp `xor`
  else: unreachable

  # Copy remaining digits of a, inverting if necessary
  if op == '^' and negb:
    for i in sizeB..<sizeZ:
      z.digits[i] = a.digits[i] xor PyLong_MASK
  elif sizeB < sizeZ:
    z.digits[sizeB..<sizeZ] = a.digits[sizeB..<sizeZ]

  # Complement result if negative
  if negz:
    flipSign(z)
    z.digits[sizeZ] = PyLong_MASK
    vComplement(z.digits, z.digits, sizeZ + 1)
  z.normalize
  return z #maybeSmallLong(longNormalize(z))


template genBOp(op; cop){.dirty.} =
  proc `op`*(a, b: IntObject): IntObject = longBitwise(a, cop, b)

genBOp(`and`, '&')
genBOp(`or`, '|')
genBOp(`xor`, '^')


template tooManyShiftErr =
  # newOverflowError newPyAscii"too many digits in integer"
  raise newException(OverflowDefect, "too many digits in integer")


proc long_rshift1(a: IntObject, wordshift: int, remshift: uint8): IntObject =
  let a_negative = a.negative()
  var
    remshift = remshift
    wordshift = wordshift
  if a_negative:
    #[For negative 'a', adjust so that 0 < remshift <= PyLong_SHIFT,
    while keeping PyLong_SHIFT*wordshift + remshift the same. This
    ensures that 'newsize' is computed correctly below.]#
    if remshift == 0:
      if wordshift == 0:
        # Can only happen if the original shift was 0.
        return a
      remshift = digitBits
      dec wordshift
  
  let oldsize = a.digitCount
  var newsize = oldsize - wordshift

  if newsize <= 0:
    return newInt -int8(a_negative)

  var z = newIntOfLenUninit(newsize)

  let hishift = digitBits - remshift

  var i = 0
  var accum = TwoDigits a.digits[wordshift]

  if a_negative:
    #[For a positive integer a and nonnegative shift, we have:

    (-a) >> shift == -((a + 2**shift - 1) >> shift).

    In the addition `a + (2**shift - 1)`, the low `wordshift` digits of
    `2**shift - 1` all have value `PyLong_MASK`, so we get a carry out
    from the bottom `wordshift` digits when at least one of the least
    significant `wordshift` digits of `a` is nonzero. Digit `wordshift`
    of `2**shift - 1` has value `PyLong_MASK >> hishift`.]#
    z.setSignAndDigitCount(Negative, newsize)
    var sticky = Digit 0
    for j in 0..<wordshift:
      sticky = sticky or a.digits[j]
    accum += (PyLong_MASK shr hishift) + Digit(sticky != 0)
  accum = accum shr remshift

  for j in (wordshift+1)..<oldsize:
    accum = accum +
      TwoDigits(a.digits[j]) shl remshift
    z.digits[i] = cast[Digit](accum)
    accum = accum shr digitBits
    i.inc
  #if hasRemshift:
  assert accum <= PyLong_MASK
  z.digits[newsize-1] = cast[Digit](accum)
  z.normalize()
  z

proc long_lshift1(a: IntObject, wordshift: int, remshift: uint8): IntObject =
  let oldsize = a.digitCount
  var newsize = oldsize + wordshift

  let hasRemshift = remshift != 0
  if hasRemshift:
    inc newsize

  var z = newIntOfLenUninit(newsize)
  if a.negative:
    #assert(Py_REFCNT(z) == 1);
    z.flipSign()
  for i in 0..<wordshift:
    z.digits[i] = 0
  var i = wordshift
  var accum = TwoDigits 0
  for j in 0..<oldsize:
    accum = accum or
      TwoDigits(a.digits[j]) shl remshift
    z.digits[i] = cast[Digit](accum)
    accum = accum shr digitBits
    i.inc
  if hasRemshift:
    z.digits[newsize-1] = cast[Digit](accum)
  else:
    assert accum == 0
  z.normalize()
  z

const ShiftMayOvf = int.high.BiggestUInt <= (BiggestUInt.high div digitBits)

template genShift(sh, implname; doOnShiftbyOverflow){.dirty.} =
  proc sh*(a: IntObject, shiftby: BiggestUInt, shiftMayOvf: static[bool] = ShiftMayOvf): IntObject =
    # long_lshift_int64
    if a.sign == Zero: return intZero
    when shiftMayOvf:
      if shiftby > BiggestUInt(int.high) * digitBits:
        doOnShiftbyOverflow

    let tup = divmod(shiftby, digitBits)
    let
      wordshift = int(tup[0])
      remshift = cast[uint8](tup[1])
    return implname(a, wordshift, remshift)


  proc sh*(a, b: IntObject): IntObject =
    if b.negative:
      raise newException(ValueError, "negative shift count")
    var overflow: IntSign
    let shiftby = b.toSomeUnsignedInt[:BiggestUInt](overflow)
    if overflow != Zero:
      doOnShiftbyOverflow
    sh(a, shiftby)

genShift `shl`, long_lshift1:
  tooManyShiftErr()

genShift `shr`, long_rshift1:
  if a.negative: return newInt -1
  else: return intZero

when isMainModule:
  import ./ops
  let
    a = newInt "0b10"
  echo a shr 1
  echo a shr 2
