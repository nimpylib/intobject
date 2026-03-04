
from std/math import floorDiv, floorMod
import ./[decl_private, decl,
  bit_length_util, shift, signbit,
  utils,
  ops_basic_arith, ops_toint
]
include ./private/common_h

using self: IntObject
type STwoDigit = SDigit
const maxValue = TwoDigits(high(Digit)) + 1

func fastExtract1(a: IntObject): SDigit =
  # assert a.digits.len == 1
  result = SDigit a.digits[0]
  if a.negative:
    result = -result

template fastExtract(a, b){.dirty.} =
  let
    left = a.fastExtract1
    right = b.fastExtract1
  when check:
    assert a.digits.len == 1
    assert b.digits.len == 1

template genFast(op){.dirty.} =
  proc `fast op`(a, b: IntObject; check: static[bool] = true): IntObject =
    fastExtract a, b
    newInt op(left, right)

proc fast_div(a, b: IntObject; check: static[bool] = true): IntObject =
  fastExtract a, b
  newInt `div`(left, right)

genFast floordiv
genFast floormod


proc inplaceDivRem1(pout: var openArray[Digit], pin: openArray[Digit], size: int, n: Digit): Digit =
  ## Perform in-place division with remainder for a single digit
  var remainder: TwoDigits = 0
  assert n > 0 and n < maxValue

  for i in countdown(size - 1, 0):
    let dividend = (remainder shl digitBits) or TwoDigits(pin[i])
    let quotient = truncate(dividend div n)
    remainder = dividend mod n
    pout[i] = quotient

  return Digit(remainder)

proc divRem*(a: IntObject, n: Digit, remainder: var Digit): IntObject =
  ## divRem1.
  ## Divide an integer by a single digit, returning both quotient and remainder
  ## The sign of a is ignored; n should not be zero.
  ## 
  ## the result's sign is always positive
  assert n > 0 and n < maxValue
  let size = a.digits.len
  var quotient = newIntOfLen(size)
  remainder = inplaceDivRem1(quotient.digits, a.digits, size, n)
  quotient.normalize()
  return quotient

proc inplaceRem1(pin: openArray[Digit], size: int, n: TwoDigits): Digit =
  ## Compute the remainder of a multi-digit integer divided by a single digit.
  ## `pin` points to the least significant digit (LSD).
  var rem: TwoDigits = 0
  assert n > 0 and n <= maxValue - 1

  for i in countdown(size - 1, 0):
    rem = ((rem shl digitBits) or TwoDigits(pin[i])) mod n

  return Digit(rem)

proc `mod`*(a: IntObject, n: TwoDigits): IntObject =
  ## `rem1`
  ## Get the remainder of an integer divided by a single digit.
  ## The sign of `a` is ignored; `n` should not be zero.
  ## 
  ## .. hint::
  ##   Other mixin ops against fixed-width integer are implemented in
  ##   [ops_mix_nim.nim](./ops_mix_nim.html)
  assert n > 0 and n <= maxValue - 1
  let size = a.digits.len
  let remainder = inplaceRem1(a.digits, size, n)
  return newInt(remainder)

template genMod(T){.dirty.} =
  type SomeUnsignedIntSmallerThanTwoDigits* = T
when digitBits > 16:
  genMod uint8|uint16|Digit
else:
  genMod uint8|Digit
proc `mod`*(a: IntObject, n: SomeUnsignedIntSmallerThanTwoDigits): IntObject = a mod TwoDigits(n)

proc tryRem(a, b: IntObject, prem: var IntObject): bool{.pyCFuncPragma.}
proc tryFloorMod(v, w: IntObject, modRes: var IntObject): bool{.pyCFuncPragma.} =
  ## `l_mod`
  ## Compute modulus: *modRes = v % w
  ## returns w != 0
  #assert modRes != nil
  if v.digits.len == 1 and w.digits.len == 1:
    modRes = fast_floor_mod(v, w, off)
    return not modRes.isNil

  if not tryRem(v, w, modRes):
    return

  # Adjust signs if necessary
  if (modRes.sign == Negative and w.sign == IntSign.Positive) or
     (modRes.sign == IntSign.Positive and w.sign == Negative):
    modRes = modRes + w


template retZeroDiv =
  raise newException(DivByZeroDefect, "division by zero")

template chkRaiseDivByZero(cond) =
  if not cond:
    retZeroDiv

proc tryDivmod(v, w: IntObject, divRes, modRes: var IntObject): bool {.pyCFuncPragma.}
  ## `l_divmod`
proc tryDivrem(a, b: IntObject, pdiv, prem: var IntObject): bool{.pyCFuncPragma.}

template tryDiv(a, b: IntObject; result): bool =
  if a.digits.len == 1 and b.digits.len == 1:
    return fast_div(a, b, off)
  var unused: IntObject
  tryDivrem(a, b, result, unused)

template tryFloorDiv(a, b: IntObject; result): bool =
  ## `l_div`
  if a.digits.len == 1 and b.digits.len == 1:
    return fast_floor_div(a, b, off)
  var unused: IntObject
  tryDivmod(a, b, result, unused)

# `long_div`
template genDivOrMod(floorOp, pyFloorOp, op, pyOp){.dirty.} =
  proc `floorOp NonZero`*(a, b: IntObject): IntObject =
    ## Integer division
    ## 
    ## assuming b is non-zero
    let ret = `try floorOp`(a, b, result)
    assert ret

  proc `floorOp`*(a, b: IntObject): IntObject{.pyCFuncPragma.} =
    ## .. note:: this raises DivByZeroDefect when b is zero
    chkRaiseDivByZero `try floorOp`(a, b, result)

  proc pyFloorOp*(a, b: IntObject): IntObject =
    ## .. note:: this may raises DivByZeroDefect
    var res: IntObject
    if `try floorOp`(a, b, res):
      return res
    retZeroDiv
  
  proc pyOp*(a, b: IntObject): IntObject =
    ## .. note:: this raises DivByZeroDefect when b is zero
    chkRaiseDivByZero op(a, b, result)

genDivOrMod floordiv, `//`,  tryDiv, `div`
genDivOrMod floormod, `%` ,  tryRem, `mod`

proc divmodNonZero*(a, b: IntObject): tuple[d, m: IntObject] =
  ## export for builtins.divmod
  let ret = tryDivmod(a, b, result.d, result.m)
  assert ret

proc divmod*(a, b: IntObject): tuple[d, m: IntObject] =
  ## .. note::
  ##   this is Python's `divmod`(get division and modulo),
  ##   ref `proc divrem(IntObject, IntObject)`_ for Nim's std/math divmod
  ##
  ## .. hint:: this raises DivByZeroDefect when b is zero
  chkRaiseDivByZero tryDivmod(a, b, result.d, result.m)

proc xDivRem(v1, w1: IntObject, prem: var IntObject): IntObject =
  ## `x_divrem`
  ## Perform unsigned integer division with remainder
  var v, w, a: IntObject
  var sizeV = v1.digits.len
  var sizeW = w1.digits.len
  assert sizeV >= sizeW and sizeW >= 2

  # Allocate space for v and w
  v = newIntSimple()
  v.digits.setLen(sizeV + 1)
  w = newIntSimple()
  w.digits.setLen(sizeW)

  # Normalize: shift w1 left so its top digit is >= maxValue / 2
  let d = digitBits - bitLength(w1.digits[^1])
  let carryW = vLShift(w.digits, w1.digits, sizeW, d)
  assert carryW == 0
  let carryV = vLShift(v.digits, v1.digits, sizeV, d)
  if carryV != 0 or v.digits[^1] >= w.digits[^1]:
    v.digits.add carryV
    inc sizeV

  # Quotient has at most `k = sizeV - sizeW` digits
  let k = sizeV - sizeW
  assert k >= 0
  a = newIntSimple()
  a.digits.setLen(k)

  var v0 = v.digits
  let w0 = w.digits
  let wm1 = w0[^1]
  let wm2 = w0[^2]

  for vk in countdown(k - 1, 0):
    # Estimate quotient digit `q`
    let vtop = v0[vk + sizeW]
    assert vtop <= wm1
    let vv = (TwoDigits(vtop) shl digitBits) or TwoDigits(v0[vk + sizeW - 1])
    var q = Digit(vv div wm1)
    var r = Digit(vv mod wm1)

    while TwoDigits(wm2) * TwoDigits(q) > ((TwoDigits(r) shl digitBits) or TwoDigits(v0[vk + sizeW - 2])):
      dec q
      r += wm1
      if r >= maxValue:
        break
    assert q <= maxValue

    # Subtract `q * w0[0:sizeW]` from `v0[vk:vk+sizeW+1]`
    var zhi: SDigit = 0
    for i in 0..<sizeW:
      let z = (SDigit(v0[vk + i]) + zhi).STwoDigit - STwoDigit(q) * STwoDigit(w0[i])
      v0[vk + i] = truncate(cast[Digit](z))
      zhi = z shr digitBits

    let svtop = SDigit vtop
    assert svtop + zhi == -1 or svtop + zhi == 0
    # Add back `w` if `q` was too large
    if svtop + zhi < 0:
      var carry = Digit 0
      for i in 0..<sizeW:
        carry += v0[vk + i] + w0[i]
        v0[vk + i] = truncate(carry)
        carry = carry shr digitBits
      dec q

    # Store quotient digit
    a.digits[vk] = q

  # Unshift remainder
  let carry = vRShift(w.digits, v0, sizeW, d)
  assert carry == 0
  prem = w
  return a

proc tryRem(a, b: IntObject, prem: var IntObject): bool{.pyCFuncPragma.} =
  ## `long_rem`
  ## Integer reminder.
  ## 
  ## returns if `b` is non-zero  (only false when b is zero)
  let sizeA = a.digits.len
  let sizeB = b.digits.len

  if sizeB == 0:
    #raise newException(ZeroDivisionError, "division by zero")
    return

  result = true
  if sizeA < sizeB or (
      sizeA == sizeB and a.digits[^1] < b.digits[^1]):
      # |a| < |b|
    prem = newInt(a)
    return

  if sizeB == 1:
    prem = a mod b.digits[0]  # `rem1`, get reminder
  else:
    discard xDivRem(a, b, prem)

  #[ Set the sign.]#
  if (a.sign == Negative) and not prem.zero():
    prem.setSignNegative()

proc tryDivrem(a, b: IntObject, pdiv, prem: var IntObject): bool{.pyCFuncPragma.} =
  ## `long_divrem`
  ## Integer division with remainder
  ## 
  ## returns if `b` is non-zero  (only false when b is zero)
  let sizeA = a.digits.len
  let sizeB = b.digits.len

  if sizeB == 0:
    #raise newException(ZeroDivisionError, "division by zero")
    return

  result = true
  if sizeA < sizeB or (
      sizeA == sizeB and a.digits[^1] < b.digits[^1]):
      # |a| < |b|
    prem = newInt(a)
    pdiv = intZero
    return

  if sizeB == 1:
    var remainder: Digit
    pdiv = divRem(a, b.digits[0], remainder)
    prem = newInt(remainder)
  else:
    pdiv = xDivRem(a, b, prem)

  #[ Set the signs.
       The quotient pdiv has the sign of a*b;
       the remainder prem has the sign of a,
       so a = b*z + r.]#
  if (a.sign == Negative) != (b.sign == Negative):
    pdiv.setSignNegative()
  if (a.sign == Negative) and not prem.zero():
    prem.setSignNegative()

proc divrem*(a, b: IntObject): tuple[d, r: IntObject] =
  chkRaiseDivByZero tryDivrem(a, b, result.d, result.r)

proc tryDivmod(v, w: IntObject, divRes, modRes: var IntObject): bool{.pyCFuncPragma.} =
  ## Python's returns -1 on failure, which is only to be Memory Alloc failure
  ## where nim will just `SIGSEGV`
  ## 
  ## returns w != 0
  result = true

  # Fast path for single-digit longs
  if v.digits.len == 1 and w.digits.len == 1:
    divRes = fast_floor_div(v, w, off)
    modRes = fast_floor_mod(v, w, off)
    return

  # Perform long division and remainder
  if not tryDivrem(v, w, divRes, modRes): return false

  # Adjust signs if necessary
  if (modRes.sign == Negative and w.sign == IntSign.Positive) or
     (modRes.sign == IntSign.Positive and w.sign == Negative):
    modRes = modRes + w
    divRes = divRes - intOne
