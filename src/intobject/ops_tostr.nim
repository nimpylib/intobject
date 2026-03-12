
import ./[
  decl_private, bit_length, bit_length_util, signbit,
  ops_dollar,
]
import ./Include/pycore_int
from ./private/utils import unreachable


proc format_binary*(a: IntObject, base: uint8, alternate: bool, v: var string): bool =
  ## long_format_binary
  ## 
  ## returns if not overflow
  assert base in {2u8, 8, 16}
  result = true

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
    return
    # Ensure overflow doesn't occur during computation of sz.
    if size_a > int.high - 3 div PyLong_SHIFT:
      return false #newOverflowError newPyAscii"int too large to format"
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
  #TODO:opt
  v = $a
  let strlen = v.len
  if strlen > PY_INT_MAX_STR_DIGITS_THRESHOLD:
    check_max_str_digits strlen - int(a.negative) > max_str_digits

proc format*(i: IntObject, base: uint8, s: var string): bool =
  # `_PyLong_Format`
  # `s` is a `out` param
  if base == 10: toStringCheckThreshold(i, s)
  else: format_binary(i, base, true, s)
