import ../[
  decl, ops_basic_arith, ops_divmod, ops_toint, signbit,
]
import ./factorial

proc permCombSmall(n, k: uint; isComb: static[bool]): IntObject =
  if k == 0:
    return intOne
  if k == 1:
    return newInt(n)

  let j = k div 2
  let a = permCombSmall(n, j, isComb)
  let b = permCombSmall(n - j, k - j, isComb)
  when isComb:
    (a * b) // permCombSmall(k, j, true)
  else:
    a * b

proc permCombBig(n: IntObject; k: uint; isComb: static[bool]): IntObject =
  if k == 0:
    return intOne
  if k == 1:
    return n

  let j = k div 2
  let a = permCombBig(n, j, isComb)
  let nMinusJ = n - newInt(j)
  let b = permCombBig(nMinusJ, k - j, isComb)
  when isComb:
    (a * b) // permCombSmall(k, j, true)
  else:
    a * b

proc asUintOrOverflow(n: IntObject; what: string): uint =
  var x: uint
  if not n.absToUInt(x):
    raise newException(OverflowDefect, what & " must not exceed uint.high")
  x

proc perm*(n: IntObject): IntObject = factorial(n)

func check(n, k: IntObject){.inline.} =
  if n.isNegative:
    raise newException(ValueError, "n must be a non-negative integer")
  if k.isNegative:
    raise newException(ValueError, "k must be a non-negative integer")

proc perm*(n, k: IntObject): IntObject =
  check(n, k)
  if n < k:
    return intZero
  if k.isZero:
    return intOne

  let ku = asUintOrOverflow(k, "k")
  var nu: uint
  if n.absToUInt(nu) and ku > 1:
    return permCombSmall(nu, ku, false)
  permCombBig(n, ku, false)

proc comb*(n, k: IntObject): IntObject =
  check(n, k)
  if n < k:
    return intZero

  var kk = k
  let nk = n - k
  if nk < kk:
    kk = nk

  let ku = asUintOrOverflow(kk, "min(n - k, k)")
  var nu: uint
  if n.absToUInt(nu) and ku > 1:
    return permCombSmall(nu, ku, true)
  if ku == 1:
    return n
  permCombBig(n, ku, true)

