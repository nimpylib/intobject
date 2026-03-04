
import ./[
  decl, signbit,
  ops_basic_arith, ops_divmod,
]

# a**b
proc pow*(a, b: IntObject): IntObject =
  assert(not b.negative)
  if b.zero:
    return intOne
  # we have checked b is not zero
  let new_b = b.floorDivNonZero intTwo
  let half_c = pow(a, new_b)
  if b.digits[0] mod 2 == 1:
    return half_c * half_c * a
  else:
    return half_c * half_c



