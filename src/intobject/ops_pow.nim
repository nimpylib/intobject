
import ./[
  decl_private, signbit, ops_bitwise,
  ops_basic_arith, ops_divmod,
]

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

const
  hugeExpCutoff = 60
  expWindowSize = 5
  expTableLen = 1 shl (expWindowSize - 1)

proc reducePowTerm(x, modulus: IntObject): IntObject {.inline.} =
  if modulus.digits.len == 1:
    x mod modulus.digits[0]
  else:
    x % modulus

proc mulReduce(x, y, modulus: IntObject): IntObject {.inline.} =
  reducePowTerm(x * y, modulus)

proc invMod(a, modulus: IntObject): IntObject =
  ##[ if exponent is negative, negate the exponent and
        replace the base with a modular inverse ]##
  var t = intZero
  var newT = intOne
  var r = modulus
  var newR = a % modulus

  while not newR.isZero:
    let (q, rem) = divmodNonZero(r, newR)
    let nextT = t - q * newT
    t = newT
    newT = nextT
    r = newR
    newR = rem

  if r != intOne:
    raise newException(ValueError, "base is not invertible for the given modulus")

  if t.isNegative:
    t = t + modulus
  t

template absorbPending(z, pending, blen, table, modulus) =
  block:
    var ntz = 0
    #[ number of trailing zeroes in `pending` ]#
    assert pending != 0 and blen != 0
    assert (pending shr (blen - 1)) != 0
    assert (pending shr blen) == 0
    while (pending and 1) == 0:
      inc ntz
      pending = pending shr 1
    assert ntz < blen
    blen -= ntz
    while blen > 0:
      z = mulReduce(z, z, modulus)
      dec blen
    z = mulReduce(z, table[pending shr 1], modulus)
    while ntz > 0:
      z = mulReduce(z, z, modulus)
      dec ntz
    assert blen == 0
    pending = 0

proc powMod*(v, w, x: IntObject): IntObject =
  var a = v
  var b = w
  var c = x
  var negativeOutput = false

  #[ if modulus == 0:
            raise ValueError() ]#
  if c.isZero:
    raise newException(ValueError, "pow() 3rd argument cannot be 0")

  #[ if modulus < 0:
            negativeOutput = True
            modulus = -modulus ]#
  if c.isNegative:
    negativeOutput = true
    c = -c

  #[ if modulus == 1:
            return 0 ]#
  if c == intOne:
    return intZero

  if b.isNegative:
    b = -b
    a = invMod(a, c)

  #[ Reduce base by modulus in some cases:
        1. If base < 0. Forcing the base non-negative makes things easier.
        2. If base is obviously larger than the modulus.
  ]#
  if a.isNegative or a.digits.len > c.digits.len:
    a = reducePowTerm(a, c)

  #[ At this point a, b, and c are guaranteed non-negative. ]#
  var z = intOne
  var i = b.digits.len
  var bi: Digit = (if i > 0: b.digits[i - 1] else: Digit(0))
  var bit: Digit

  if i <= 1 and bi <= 3:
    #[ aim for minimal overhead ]#
    if bi >= 2:
      z = mulReduce(a, a, c)
      if bi == 3:
        z = mulReduce(z, a, c)
    elif bi == 1:
      #[ Multiplying by 1 serves two purposes: if `a` is of an int
            subclass, makes the result an int, and potentially reduces
            `a` by the modulus. ]#
      z = mulReduce(a, z, c)
    #[ else bi is 0, and z==1 is correct ]#
  elif i <= hugeExpCutoff div PyLong_SHIFT:
    #[ Left-to-right binary exponentiation (HAC Algorithm 14.79)
          https://cacr.uwaterloo.ca/hac/about/chap14.pdf ]#

    #[ Find the first significant exponent bit. Search right to left
          because we're primarily trying to cut overhead for small powers. ]#
    assert bi != 0
    z = a
    bit = 2
    while true:
      if bit > bi:
        #[ found the first bit ]#
        assert (bi and bit) == 0
        bit = bit shr 1
        assert (bi and bit) != 0
        break
      bit = bit shl 1

    dec i
    bit = bit shr 1
    while true:
      while bit != 0:
        z = mulReduce(z, z, c)
        if (bi and bit) != 0:
            z = mulReduce(z, a, c)
        bit = bit shr 1
      dec i
      if i < 0:
        break
      bi = b.digits[i]
      bit = Digit(1) shl (PyLong_SHIFT - 1)
  else:
    #[ Left-to-right k-ary sliding window exponentiation
          (Handbook of Applied Cryptography (HAC) Algorithm 14.85) ]#
    var table = newSeq[IntObject](expTableLen)
    table[0] = a
    let a2 = mulReduce(a, a, c)

    #[ table[i] == a**(2*i + 1) % c ]#
    for tableIdx in 1..<expTableLen:
      table[tableIdx] = mulReduce(table[tableIdx - 1], a2, c)

    #[ Repeatedly extract the next (no more than) expWindowSize bits
          into `pending`, starting with the next 1 bit. The current bit
          length of `pending` is `blen`. ]#
    var pending = 0
    var blen = 0

    for digitIdx in countdown(b.digits.len - 1, 0):
      let biDigit = b.digits[digitIdx]
      for j in countdown(PyLong_SHIFT - 1, 0):
        let bitValue = int((biDigit shr j) and Digit(1))
        pending = (pending shl 1) or bitValue
        if pending != 0:
          inc blen
          if blen == expWindowSize:
            absorbPending(z, pending, blen, table, c)
        else:
          #[ absorb strings of 0 bits ]#
          z = mulReduce(z, z, c)

      if pending != 0:
        absorbPending(z, pending, blen, table, c)

  if negativeOutput and not z.isZero:
    z = z - c

  z

template toIntObj(x: IntObject): IntObject = x
template toIntObj(x: SomeInteger): IntObject = newInt x
proc pow*[V, W, X: SomeIntegerOrObj](v: V, w: W, x: X): IntObject = powMod(toIntObj(v), toIntObj(w), toIntObj(x))

proc divmodNear*(a, b: IntObject): tuple[q, r: IntObject] =
  ## `_PyLong_DivmodNear`.
  ##
  ## where q is the nearest integer to the quotient a / b (the
  ## nearest even integer in the case of a tie) and r == a - q * b.
  ##
  ## Hence q * b = a - r is the nearest multiple of b to a,
  ## preferring even multiples in the case of a tie.
  ##
  ## This assumes b is positive.
  var (q, r) = divmod(a, b)
  let twiceR = r * intTwo
  if twiceR > b or (twiceR == b and q.isOdd):
    q = q + intOne
    r = r - b
  (q, r)

proc roundImpl(self, oNdigits: IntObject): IntObject{.raises: [].} =
  ## Rounding with an ndigits argument also returns an integer.
  ##
  ## To round an integer m to the nearest 10**n (n positive), we make use of
  ## the divmod_near operation, defined by:
  ##
  ##   divmod_near(a, b) = (q, r)
  ##
  ## where q is the nearest integer to the quotient a / b (the
  ## nearest even integer in the case of a tie) and r == a - q * b.
  ## Hence q * b = a - r is the nearest multiple of b to a,
  ## preferring even multiples in the case of a tie.
  ##
  ## So the nearest multiple of 10**n to m is:
  ##
  ##   m - divmod_near(m, 10**n)[1].

  ## if ndigits >= 0 then no rounding is necessary; return self unchanged
  if not oNdigits.isNegative:
    return self

  ## result = self - divmod_near(self, 10 ** -ndigits)[1]
  let ndigits = -oNdigits
  let scale = powPos(intTen, ndigits)
  let (_, rem) = divmodNear(self, scale)
  self - rem

proc round*(self: IntObject; oNdigits: SomeIntegerOrObj): IntObject =
  ## this is like Python's built-in round() for integers, which accepts an optional second argument ndigits.
  ## 
  ## If ndigits is negative, it rounds to the nearest multiple of 10**(-ndigits).
  ## If two multiples are equally close, rounding is done toward the even choice.
  roundImpl(self, toIntObj(oNdigits))
