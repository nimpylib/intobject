
# import ../numobjects_comm
import ./[decl_private, decl, utils, signbit, ops_basic_private]

const
  intZero* = newInt(0)
  intOne*  = newInt(1)
  intTwo*  = newInt(2)
  intTen*  = newInt(10)

using self: IntObject

proc doCompare(a, b: IntObject): IntSign {. cdecl .} =
  ## ignore sign, return `|a| - |b|`
  if a.digits.len < b.digits.len:
    return Negative
  if a.digits.len > b.digits.len:
    return Positive
  for i in countdown(a.digits.len-1, 0):
    let ad = a.digits[i]
    let bd = b.digits[i]
    if ad < bd:
      return Negative
    elif ad == bd:
      continue
    else:
      return Positive
  return Zero

proc doAdd(a, b: IntObject): IntObject =
  ## ignore sign, return `|a| + |b|`
  if a.digits.len < b.digits.len:
    return doAdd(b, a)
  var carry = TwoDigits(0)
  result = newIntSimple()
  for i in 0..<a.digits.len:
    if i < b.digits.len:
      # can't use inplace-add, gh-10697
      carry = carry + TwoDigits(b.digits[i])
    carry += TwoDigits(a.digits[i])
    result.digits.add truncate(carry)
    carry = carry.demote
  if TwoDigits(0) < carry:
    result.digits.add truncate(carry)

proc doSub(a, b: IntObject): IntObject =
  ## ignore sign, return `|a| - |b|`
  result = newIntSimple()
  result.sign = IntSign.Positive

  var borrow = false #Digit(0)

  # Ensure `a` is the larger of the two
  var larger = a
  var smaller = b
  var sizeA = larger.digits.len
  var sizeB = smaller.digits.len
  if sizeA < sizeB or (sizeA == sizeB and doCompare(a, b) == Negative):
    result.sign = Negative
    larger = b
    smaller = a
    swap sizeA, sizeB
  result.digits.setLen(sizeA)

  # Perform subtraction digit by digit
  for i in 0..<sizeB:
    let diff = TwoDigits(larger.digits[i]) - TwoDigits(smaller.digits[i]) - TwoDigits(borrow)
    result.digits[i] = truncate(diff)
    borrow = diff < 0

  for i in sizeB..<sizeA:
    let diff = TwoDigits(larger.digits[i]) - TwoDigits(borrow)
    result.digits[i] = truncate(diff)
    borrow = diff < 0

  # Normalize the result to remove leading zeros
  result.normalize()

  # Handle the sign of the result
  if result.digits.len == 0:
    result.sign = Zero

proc doMul(a: IntObject, b: Digit): IntObject =
  ## ignore sign, return `|a| * |b|`
  result = newIntOfLen(a.digits.len)
  result.doMulImpl(b, i, 0..<a.digits.len, a.digits[i], result.digits[i])


proc doMul(a, b: IntObject): IntObject =
  if a.digits.len < b.digits.len:
    return doMul(b, a)
  var ints: seq[IntObject]
  for i, db in b.digits:
    var c = a.doMul(db)
    let zeros = newSeq[Digit](i)
    c.digits = zeros & c.digits
    ints.add c
  result = ints[0]
  for intObj in ints[1..^1]:
    result = result.doAdd(intObj)

proc `<`*(a, b: IntObject): bool =
  case a.sign
  of Negative:
    case b.sign
    of Negative:
      return doCompare(a, b) == IntSign.Positive
    of Zero, Positive:
      return true
  of Zero:
    return b.sign == IntSign.Positive
  of Positive:
    case b.sign
    of Negative, Zero:
      return false
    of Positive:
      return doCompare(a, b) == Negative

proc `==`*(a, b: IntObject): bool =
  if a.sign != b.sign:
    return false
  return doCompare(a, b) == Zero

proc `<=`*(a, b: IntObject): bool =
  #TODO:opt
  a < b or a == b

proc `+`*(a, b: IntObject): IntObject =
  case a.sign
  of Negative:
    case b.sign
    of Negative:
      result = doAdd(a, b)
      result.sign = Negative
      return
    of Zero:
      return a
    of Positive:
      return doSub(b, a)
  of Zero:
    return b
  of Positive:
    case b.sign
    of Negative:
      return doSub(a, b)
    of Zero:
      return a
    of Positive:
      result = doAdd(a, b)
      result.sign = IntSign.Positive
      return

proc `-`*(a, b: IntObject): IntObject =
  case a.sign
  of Negative:
    case b.sign
    of Negative:
      return doSub(b, a)
    of Zero:
      return a
    of Positive:
      result = doAdd(a, b)
      result.sign = Negative
      return
  of Zero:
    case b.sign
    of Negative:
      result = b.copyOnlyDigits()
      result.sign = IntSign.Positive
      return
    of Zero:
      return a
    of Positive:
      result = b.copyOnlyDigits()
      result.sign = Negative
      return
  of Positive:
    case b.sign
    of Negative:
      result = doAdd(a, b)
      result.sign = IntSign.Positive
      return
    of Zero:
      return a
    of Positive:
      return doSub(a, b)


proc `-`*(a: IntObject): IntObject =
  result = a.copyOnlyDigits()
  result.sign = a.sign
  result.flipSign

proc abs*(self): IntObject =
  if self.isNegative: -self
  else: self

proc `*`*(a, b: IntObject): IntObject =
  case a.sign
  of Negative:
    case b.sign
    of Negative:
      result = doMul(a, b)
      result.sign = IntSign.Positive
      return
    of Zero:
      return intZero
    of Positive:
      result = doMul(a, b)
      result.sign = Negative
      return
  of Zero:
    return intZero
  of Positive:
    case b.sign
    of Negative:
      result = doMul(a, b)
      result.sign = Negative
      return
    of Zero:
      return intZero
    of Positive:
      result = doMul(a, b)
      result.sign = IntSign.Positive
      return
