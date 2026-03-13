
import std/bitops
import ./[
  decl_private, ops, ops_mix_nim, ops_annassign,
]

proc succ*(self: IntObject; i: int = 1): IntObject{.inline.} = self + i
proc pred*(self: IntObject; i: int = 1): IntObject{.inline.} = self - i

iterator `..`*(a, b: IntObject): IntObject =
  var current = a
  while current <= b:
    yield current
    current.inc

func fastLog2*(a: IntObject): int =
  ## Computes the logarithm in base 2 of `a`.
  ## If `a` is negative, returns the logarithm of `abs(a)`.
  ## If `a` is zero, returns -1.
  if a.isZero:
    return -1
  bitops.fastLog2(a.digits[^1]) + digitBits*(a.digits.high)
