
import ./isqrt_utils
include ./comm
imp [
  decl, ops_basic_arith, ops_mix_nim, ops_toint,
  ops_divmod,
]

proc isqrtPositive*(n: IntObject): IntObject =
  let c = (n.numbits() - 1) div 2
  #[Fast path: if c <= 31 then n < 2**64 and we can compute directly with a
       fast, almost branch-free algorithm.]#
  if c <= 31:
    let m = n.toSomeUnsignedIntUnsafe[:uint64]
    let res = isqrtPositive m
    return newInt res

  #[ Slow path: n >= 2**64. We perform the first five iterations in C integer
arithmetic, then switch to using Python long integers]#

  # From n >= 2**64 it follows that c.bit_length() >= 6.
  var c_bit_length = 6
  while (c shr c_bit_length) > 0:
    c_bit_length.inc

  # Initialise d and a.
  var d = c shr (c_bit_length - 5)
  let b = n shr BiggestUInt(2*c - 62)

  var m: uint64
  let notOvf = b.absToUInt(m)
  if not notOvf:
    raise newException(OverflowDefect, "int cannot fit into a BiggestUInt")
  let u = approximate_isqrt(m) shr (31 - d)
  var a = newInt u
  for s in countdown(c_bit_length - 6, 0):
    var q: IntObject
    var e = int64 d
    d = c shr s

    q = (n shr BiggestUInt(2*c - e - d + 1)) // a
    a = (a shl BiggestUInt(d - e - 1)) + q

  #[ The correct result is either a or a - 1. Figure out which, and
  decrement a if necessary. ]#

  let a_too_large = n < a*a
  if a_too_large:
    a = a - 1
  return a

proc isqrt*(n: IntObject): IntObject =
  case n.sign
  of IntSign.Negative:
    raise newException(ValueError, "isqrt() argument must be nonnegative")
  of IntSign.Zero: return intZero
  of IntSign.Positive:
    return isqrtPositive n
