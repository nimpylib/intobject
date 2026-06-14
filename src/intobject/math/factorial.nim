import std/bitops
import ../[
  bit_length_util, decl, ops_basic_arith, ops_bitwise, ops_toint, signbit,
]

const smallFactorials: array[21, uint64] = [
  1u64, 1u64, 2u64, 6u64, 24u64, 120u64, 720u64, 5040u64, 40320u64,
  362880u64, 3628800u64, 39916800u64, 479001600u64,
  6227020800u64, 87178291200u64, 1307674368000u64,
  20922789888000u64, 355687428096000u64, 6402373705728000u64,
  121645100408832000u64, 2432902008176640000u64,
]

proc partialProduct(start, stop: uint; maxBits: int): IntObject =
  ## Compute product(range(start, stop, 2)) for odd start/stop.
  let numOperands = (stop - start) div 2
  if numOperands == 0:
    return intOne

  when sizeof(uint) <= sizeof(uint64):
    if numOperands <= uint(8 * sizeof(uint)) and
        numOperands * uint(maxBits) <= uint(8 * sizeof(uint)):
      var total = start
      var j = start + 2
      while j < stop:
        total *= j
        j += 2
      return newInt(total)

  let midpoint = (start + numOperands) or 1u
  partialProduct(start, midpoint, bit_length(midpoint - 2)) *
    partialProduct(midpoint, stop, maxBits)

proc factorialOddPart(n: uint): IntObject =
  var inner = intOne
  var outer = intOne
  var upper = 3u

  for i in countdown(bit_length(n) - 2, 0):
    let v = n shr i
    if v <= 2:
      continue
    let lower = upper
    upper = (v + 1) or 1u
    inner = inner * partialProduct(lower, upper, bit_length(upper - 2))
    outer = outer * inner

  outer

proc factorial*(n: uint): IntObject =
  if n < uint(smallFactorials.len):
    return newInt(smallFactorials[n])

  let oddPart = factorialOddPart(n)
  oddPart shl BiggestUInt(n - uint(countSetBits(n)))

proc factorial*(n: IntObject): IntObject =
  if n.isNegative:
    raise newException(ValueError, "factorial() not defined for negative values")

  var x: uint
  if not n.absToUInt(x):
    raise newException(OverflowDefect, "factorial() argument should not exceed uint.high")

  factorial(x)
