
import std/algorithm
import ./[
  decl_private, decl, utils,
  ops_toint, ops_divmod,
]

proc fill(result: var string, i: IntObject) =
  if i.isZero:
    result = "0"
    return
  var ii = i.copyOnlyDigits()
  var r: Digit
  while true:
    ii = ii.divRem(10, r)
    result.add(char(r + Digit('0')))
    if ii.digits.len == 0:
      break
  #strSeq.add($i.digits)
  if i.isNegative:
    result.add '-'
  result.reverse
  #TODO:opt

proc length_hint(a: IntObject): int = a.digitCount * PyLong_DECIMAL_SHIFT

proc `$`*(i: IntObject): string{.raises: [].} =
  ## this ignores `get_intobject_state().max_str_digits`,
  ##  and may raises `OverflowDefect` if `i` contains too many digits
  result = newStringOfCap(i.length_hint)
  result.fill i
