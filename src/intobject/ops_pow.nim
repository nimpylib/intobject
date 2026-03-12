
import ./[
  decl_private, signbit, ops_bitwise,
  ops_basic_arith, ops_divmod,
]

proc isOdd*(i: IntObject): bool =
  not i.isZero and (i.digits[0] mod 2 == 1)

proc isEven*(i: IntObject): bool =
  i.isZero or (i.digits[0] mod 2 == 0)

proc posShr1(posI: IntObject): IntObject =
  #TODO:opt
  return posI.floordivNonZero intTwo

template posFloordiv2(posI: IntObject): IntObject = posI.posShr1

func pow2(i: IntObject): IntObject =
  ## i**2
  #TODO:opt
  i*i

# a**b
proc powNatural*(a, b: IntObject): IntObject{.raises: [].} =
  ## assuming b is Positive or zero (Natural)
  assert not b.isNegative
  if b.isZero:
    return intOne
  # we have checked b is not zero
  let new_b = b.posFloordiv2
  let half_c = powNatural(a, new_b)
  result = half_c.pow2
  if isOdd(b):
    return result * a

proc pow*(a: IntObject; b: Natural|SomeUnsignedInt): IntObject =
  if b == 0:
    return intOne
  let new_b = b div 2
  let half_c = pow(a, new_b)
  result = half_c.pow2
  if b mod 2 == 1:
    return result * a

proc powPos*(a, b: IntObject): IntObject{.raises: [].} =
  ## assuming b is Positive
  assert b.isPositive
  # we have checked b is not zero
  let new_b = b.posFloordiv2
  if new_b.isZero:
    assert b == intOne
    return a
  let half_c = powPos(a, new_b)
  result = half_c.pow2
  if isOdd(b):
    return result * a

proc pow*(a, b: IntObject): IntObject =
  ## raises ValueError when `b` is negative
  if b.isNegative:
    raise newException(ValueError, "negative exponent will result in float")
  powNatural(a, b)
