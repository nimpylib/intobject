import std/[
  tables, macros, strutils, math]
from std/unicode import Rune, `==`
# import ../numobjects_comm
import ./[decl_private, decl]
export decl except Digit, TwoDigits, SDigit, digitBits, truncate,
 IntSign
import ./[
  bit_length, bit_length_util, signbit,
  fromStrUtils, utils,
  ops_basic_private, ops_basic_arith, ops_toint,
  ops_divmod, ops_pow, ops_dollar, ops_tofloat
]
export bit_length, signbit,
  ops_basic_arith, ops_toint, ops_divmod, ops_pow,
  ops_dollar, ops_tofloat
# import ../../stringobject/strformat
import pkg/unicode_space_decimal/[decimal, space]
# from ../../../Utils/utils import unreachable
from ./private/utils import unreachable
import ./Include/pycore_int
export PY_INT_MAX_STR_DIGITS_THRESHOLD, PY_INT_DEFAULT_MAX_STR_DIGITS
{.pragma: pyCFuncPragma, raises: [].} 

export intZero, intOne, intTen

using self: IntObject

#[
proc newInt(i: int): IntObject =
  var ii: int
  if i < 0:
    result = newIntSimple()
    result.sign = Negative
    ii = (not i) + 1
  elif i == 0:
    return intZero
  else:
    result = newIntSimple()
    result.sign = Positive
    ii = i
  result.digits.add uint32(ii)
  result.digits.add uint32(ii shr 32)
  result.normalize
]#

type IntObjectFromStrError*{.pure.} = enum
  Ok
  InvalidBase = "int() arg 2 must be >= 2 and <= 36"
  InvalidLiteral = "invalid literal for int() with base"
  ExceedsMaxStrDigits = "exceeds maximum string digits allowed in int() conversion"

const PyLongBaseSet* = {0, 2..36}

template check_max_str_digits_with_msg(fail_cond; errMsg){.dirty.} =
  bind get_intobject_state, IntObjectFromStrError
  let max_str_digits = get_intobject_state().max_str_digits
  if max_str_digits > 0 and fail_cond:
    return IntObjectFromStrError.ExceedsMaxStrDigits #newValueError newPyAscii errMsg

template digitsAdd0(res: IntObject) =
  res.digits.add 0

template fromStrAux[C: char|Rune](result: var IntObject; s: openArray[C]; i: var int; base: uint8#[PyLongBase]#; checkThreshold: static[bool]; cToDigit) {.dirty.} =
  bind inplaceMul, inplaceAdd, normalize, newIntSimple, digitsAdd0
  bind check_max_str_digits_with_msg, PY_INT_MAX_STR_DIGITS_THRESHOLD, MAX_STR_DIGITS_errMsg_to_int
  result = newIntSimple()
  # assume s not empty
  digitsAdd0(result)
  var pre = C '\0'
  while i < s.len:
    when checkThreshold:
      if i > PY_INT_MAX_STR_DIGITS_THRESHOLD:
        check_max_str_digits_with_msg i > max_str_digits, MAX_STR_DIGITS_errMsg_to_int(max_str_digits, i)
    let c = s[i]
    if c == C'_':
      # Double underscore not allowed.
      if pre == C'_':
        break
    else:
      inplaceMul(result, base)
      inplaceAdd(result, cToDigit)
    pre = c
    i.inc

  normalize(result)

template isspace(c: char): bool = c.isSpaceAscii

template zeroDigits(res: IntObject): bool =
  res.digitCount == 0

template fromStrImpl[C: char|Rune](result: var IntObject; s: openArray[C]; i: var int; base: var uint8#[PyLongBase]#; checkThreshold: static[bool]; errInvStr; cToDigit) {.dirty.} =
  bind fromStrAux, isspace, intZero, zeroDigits
  bind decl_private.`sign=`
  var sign: IntSign = Positive
  let L = s.len
  template chkIdx =
    if system.`==`(i, L): return
  
  template incIdx =
    i.inc
    chkIdx
  chkIdx
  # strip leading whitespace
  while isspace s[i]: incIdx

  var error_if_nonzero = false
  var cur: C
  template stcur = cur = s[i]
  stcur
  if cur == C'+': incIdx
  elif cur == C'-':
    incIdx
    sign = Negative

  template curIs(a, b): bool = cur == a or cur == b
  template preHex: bool = curIs(C'x', C'X')
  template preOct: bool = curIs(C'o', C'O')
  template preBin: bool = curIs(C'b', C'B')
  stcur

  var pre0 = cur == C'0'

  res = intZero
  if base == 0:
    if not pre0: base = 10
    else:
      # may be a simple "0"
      incIdx  # may `return` here, if is "0"
      stcur
      base = if preHex: 16
      elif preOct: 8
      elif preBin: 2
      else:
        #["old" (C-style) octal literal, now invalid.
              it might still be zero though]#
        error_if_nonzero = true
        10
      dec i

  if pre0 and (incIdx; stcur; (  # may `return` here, if is "0"
    base == 16 and preHex or
    base == 8  and preOct or
    base == 2  and preBin
  )):
    incIdx
    # One underscore allowed here.
    stcur
    if cur == C'_':
      incIdx

  fromStrAux(result, s, i, base, checkThreshold, cToDigit)

  # Allow only trailing whitespace after `end`
  while true:
    if i < L and isspace s[i]:
      i.inc
    else:
      break

  let zero = zeroDigits(result)
  if error_if_nonzero:
    #[reset the base to 0, else the exception message
      doesn't make too much sense]#
    base = 0
    if not zero:
      errInvStr
    #[there might still be other problems, therefore base
    remains zero here for the same reason]#
  decl_private.`sign=`(result, if zero: IntSign.Zero else: sign)


proc parseInt*[C: char|Rune](s: openArray[C]; res: var IntObject): int =
  ## with `base = 0` (a.k.a. support prefix like 0b)
  ## and ignore `get_intobject_state().max_str_digits`
  template err = return
  var base = 0u8
  res.fromStrImpl(s, result, base, false, err):
    when C is char:
      if c not_in Digits: err
      Digit(c) - Digit('0')
    else:
      var d: Digit
      c.decimalItOr:
        d = cast[Digit](it)
      do: err
      d
proc parseIntObject*[C: char|Rune](s: openArray[C]): IntObject{.raises: [ValueError].} =
  ## This ignores `get_intobject_state().max_str_digits`
  if s.parseInt(result) != s.len:
    raise newException(ValueError, "could not convert string to int")


template invBaseRet =
  return IntObjectFromStrError.InvalidBase

template retInvIntCall(s, base){.dirty.} =
  return IntObjectFromStrError.InvalidLiteral

proc fromStrWithValidBase*[C: char](res: var IntObject; s: openArray[C]; nParsed: var int; base: int): IntObjectFromStrError =
  template err{.dirty.} =
    retInvIntCall s, base
  var base = cast[uint8](base)
  res.fromStrImpl(s, nParsed, base, true, err):
    Digit c.digitOr(base, err)

proc fromStr*[C: char](res: var IntObject; s: openArray[C]; nParsed: var int): IntObjectFromStrError =
  res.fromStrWithValidBase s, nParsed, 10

proc fromStr*[C: char](res: var IntObject; s: openArray[C]; nParsed: var int; base: int): IntObjectFromStrError =
  if base != 0 and base < 2 or base > 36:
    invBaseRet
  res.fromStrWithValidBase(s, nParsed, base)

proc format_binary*(a: IntObject, base: uint8, alternate: bool, v: var string): bool =
  ## long_format_binary
  ## 
  ## returns if not overflow
  assert base in {2u8, 8, 16}

  let
    size_a = a.digitCount
    high_a = size_a - 1
  let bits = case base
  of 16: 4
  of 8: 3
  of 2: 1
  else: unreachable
  let negative = a.negative
  var sz: int
  if size_a == 0:
    v = "0"
    return true
  else:
    # Ensure overflow doesn't occur during computation of sz.
    if size_a > int.high - 3 div PyLong_SHIFT:
      return #newOverflowError newPyAscii"int too large to format"
    {.push overflowChecks: off.}
    let size_a_in_bits = (high_a) * PyLong_SHIFT + bit_length(a.digits[high_a])
    # Allow 1 character for a '-' sign.
    sz = negative.int + (size_a_in_bits + (bits - 1)) div bits
    {.pop.}
  if alternate: sz += 2
  v = (when declared(newStringUninit): newStringUninit else: newString)(sz)

  template WRITE_DIGITS(p) =
    # JRH: special case for power-of-2 bases
    var accum = TwoDigits 0
    var accumbits = 0  # # of bits in accum
    for i in 0..<size_a:
      accum = accum or ((TwoDigits a.digits[i]) shl accumbits)
      accumbits += PyLong_SHIFT
      assert accumbits >= bits
      while true:
        var cdigit = cast[uint8](accum and (base - 1))
        cdigit += (if cdigit < 10: uint8'0' else: 87#[uint8('a')-10]#)
        *--cast[char](cdigit)
        accumbits -= bits
        accum = accum shr bits
        if not (
          if i < high_a: accumbits >= bits
          else: accum > 0): break
    if alternate:
      case bits
      of 4: *--'x'
      of 3: *--'o'
      else: *--'b' # base == 2
      *--'0'
    if negative: *--'-'

  var p = sz
  template `*--`(c) =
    p.dec
    v[p] = c

  WRITE_DIGITS p
  assert p == 0


proc toStringCheckThreshold*(a: IntObject, v: var string): bool{.raises: [].} =
  ## this respects `get_intobject_state().max_str_digits`
  ## 
  ## returns if exceeds threshold, but does not raise, instead returns false
  result = true
  template check_max_str_digits(fail_cond){.dirty.} =
    # check_max_str_digits_with_msg fail_cond, MAX_STR_DIGITS_errMsg_to_str(max_str_digits)
    return false
  let size_a = a.digitCount
  if size_a >= 10 * PY_INT_MAX_STR_DIGITS_THRESHOLD div (3 * PyLong_SHIFT) + 2:
    check_max_str_digits(
       max_str_digits div (3 * PyLong_SHIFT) <= ((size_a - 11) div 10)
    )
  #let size_hint = size_a.length_hint
  #let scratch = newIntOfLen size_hint
  v = $a
  let strlen = v.len
  if strlen > PY_INT_MAX_STR_DIGITS_THRESHOLD:
    check_max_str_digits strlen - int(a.negative) > max_str_digits

proc format*(i: IntObject, base: uint8, s: var string): bool =
  # `_PyLong_Format`
  # `s` is a `out` param
  if base == 10: toStringCheckThreshold(i, s)
  else: format_binary(i, base, true, s)


proc newInt*[C: char](smallInt: C): IntObject =
  newInt int smallInt  # TODO

proc newInt*[C: Rune|char](str: openArray[C]): IntObject = 
  parseIntObject(str)

proc `'iobj`*[C: Rune|char](str: openArray[C]): IntObject = 
  parseIntObject(str)

proc newIntFromNormalFloat*(dval: float): IntObject =
  ## `PyLong_FromDouble`, but assumes dval is normal (not inf or nan)
  #[
	  Try to get out cheap if this fits in a long. When a finite value of real
    floating type is converted to an integer type, the value is truncated
    toward zero. If the value of the integral part cannot be represented by
    the integer type, the behavior is undefined. Thus, we must check that
    value is in range (LONG_MIN - 1, LONG_MAX + 1). If a long has more bits
    of precision than a double, casting LONG_MIN - 1 to double may yield an
    approximation, but LONG_MAX + 1 is a power of two and can be represented
    as double exactly (assuming FLT_RADIX is 2 or 16), so for simplicity
    check against (-(LONG_MAX + 1), LONG_MAX + 1).
	]#
  # case dval.classify
  # of fcInf, fcNegInf:
  #   return newOverflowError(newPyAscii"cannot convert float infinity to integer")
  # of fcNan:
  #   return newValueError(newPyAscii"cannot convert float NaN to integer")
  # else: discard
  assert dval.classify not_in {fcInf, fcNegInf, fcNan}

  const int_max = float int.high.uint + 1
  if -int_max <= dval and dval <= int_max:
    return newInt(int dval)

  var dval = dval
  var neg = false
  if dval < 0.0:
    neg = true
    dval = -dval

  var expo: int
  var frac = frexp(dval, expo)  # dval = frac*2**expo; 0.0 <= frac < 1.0
  assert expo > 0
  let expo1s = expo - 1

  let ndig = expo1s div PyLong_SHIFT + 1
  var res = newIntOfLenUninit(ndig)

  when not declared(ldexp) and not defined(js):
    proc ldexp(arg: cdouble, exp: cint): cdouble{.importc, header: "<math.h>".}
    proc ldexp(arg: cdouble, exp: int): cdouble = ldexp(arg, cint(exp))
  when declared(ldexp):
    # NIMPYLIB:ldexp
    {.define: npythonGoodIntFromBigFloat.}
    frac = ldexp(frac, expo1s mod PyLong_SHIFT + 1)
    for i in countdown(ndig-1, 0):
      let bits = Digit(frac)
      res.digits[i] = bits
      frac -= float(bits)
      frac = ldexp(frac, PyLong_SHIFT)
  else:
    discard frac
    let fmaxValue = float high Digit
    #while dval >= 1.0:
    for i in countup(0, ndig-1):
      let digit = Digit(dval mod fmaxValue)

      #res.digits.add digit
      res.digits[i] = digit
      dval = dval / fmaxValue
    res.normalize()

  res.sign = if neg:
    Negative
  else:
    Positive
  res

when isMainModule:
  #let a = fromStr("-1234567623984672384623984712834618623")
  let aa = parseIntObject([Rune'1'])
  discard aa
  #let a = fromStr("3234567890")
  #[
  echo a
  echo a + a
  echo a + a - a
  echo a + a - a - a
  echo a + a - a - a - a
  ]#
  #let a = fromStr("88888888888888")
  let a = 100000000000'iobj
  echo a.pow(intTen)
  echo a
  #echo a * intTen
  #echo a.pow intTen
  #let a = fromStr("100000000000")
  #echo a
  #echo a * fromStr("7") - a - a - a - a - a - a - a
  #let b = newInt(2)
  #echo intTen
  #echo -intTen
  #echo a
  #echo int(a)
  #echo -int(a)
  #echo IntSign(-int(a))
  #echo newInt(3).pow(intTwo) - intOne + intTwo
  #echo a div b
  #echo a div b * newInt(2)
