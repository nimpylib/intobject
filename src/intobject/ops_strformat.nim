
import std/strformat
from std/unicode import `$`, Rune
import ./[
  decl, ops_tostr, ops_toint, ops_tofloat,
]
import ./Include/pycore_int

template raiseValueError(m) =
  raise newException(ValueError, m)

type IntObjectFormatOverflowError* = object of CatchableError ##[
  raised when `formatValue` for `IntObject`,
  and OverflowError would be raised in Python
]##
template raiseOverflowError(m) =
  raise newException(IntObjectFormatOverflowError, m)

proc formatValueInt(res: var string; self: IntObject, format_spec: string,
    spec: StandardFormatSpecifier
) =
  var s: string
  #TODO:NIMPYLIB
  #TODO:format
  when true:
    var base: uint8

    # We will dispatch formatValue via string type
    var sformat_spec = format_spec
    let L = sformat_spec.len
    if L > 0:
      sformat_spec.setLen(L - 1)

    #PY-DIFF: align is '<' by default for all types in Python
    # but in Nim, string defaults in '>' (and only strings, not other types)
    if spec.align == '\0':  # if align is to be defaulted
      # spec starts with `[[fill]align]`
      if spec.fill == ' ':
        sformat_spec = '>' & sformat_spec
      else:
        sformat_spec = spec.fill & '>' & sformat_spec[1..^1]

    case spec.typ
    of 'x', 'X': base = 16
    of 'b': base = 2
    of 'o': base = 8
    else:
      #'\0', 'n', 'd':
      let ret = self.toStringCheckThreshold(s)
      if not ret:
        raiseOverflowError MAX_STR_DIGITS_errMsg_to_str(get_intobject_state().max_str_digits)
      res.formatValue(s, sformat_spec)
      return

    let ret = self.format_binary(base, spec.alternateForm, s)
    if not ret:
      raiseOverflowError "int too large to format"
    res.formatValue(s, sformat_spec)

const SpecFloatTypes = {'f', 'F', 'e', 'E', 'g', 'G', '%'}
template asIs(x): untyped = x
template private_gen_formatValue_impl*(runeMapper, floatMapper; selfToIntObjectMapper: untyped = asIs; bodyWrapper: untyped = asIs){.dirty.} =
  ## private. inner. unstable.
  bind raiseOverflowError, SpecFloatTypes, parseStandardFormatSpecifier
  bind formatValueInt
  bind raiseValueError
  template impl(res, self, format_spec) = bodyWrapper:
    when format_spec is static:
      const spec = parseStandardFormatSpecifier format_spec
      template typeFloatOr(floatDo, elseDo, runeDo) =
        when spec.typ in SpecFloatTypes: floatDo
        elif spec.typ == 'c': runeDo
        else: elseDo
    else:
      let spec = parseStandardFormatSpecifier format_spec
      template typeFloatOr(floatDo, elseDo, runeDo) =
        case spec.typ
        of SpecFloatTypes: floatDo
        of 'c': runeDo
        else: elseDo
    typeFloatOr:
      var ovf: bool
      let flt = toFloat(self, ovf)
      if ovf:
        raiseOverflowError "int too large to convert to float"
      res.formatValue(floatMapper flt, format_spec)
    do:
      formatValueInt(res, selfToIntObjectMapper self, format_spec, spec)
    do:
      # error to specify a sign
      if spec.sign != '\0':
          raiseValueError(
              "Sign not allowed with integer" &
                " format specifier 'c'")
      # error to request alternate format
      if spec.alternateForm:
          raiseValueError(
              "Alternate form (#) not allowed with integer" &
                " format specifier 'c'")

      # taken from unicodeobject.c formatchar()
      # Integer input truncated to a character
      var x: int
      let ovf = self.toInt x
      if ovf or 
        (x < 0 or x > 0x10ffff):
          raiseOverflowError(
                          "%c arg not in range(0x110000)")
      let str = runeMapper(cast[Rune](x))
      # inumeric_chars = 0;
      # n_digits = 1
      #[As a sort-of hack, we tell calc_number_widths that we only
          have "remainder" characters. calc_number_widths thinks
          these are characters that don't get formatted, only copied
          into the output string. We do this for 'c' formatting,
          because the characters are likely to be non-digits.]#
      # n_remainder = 1
      res.formatValue(str, format_spec)

private_gen_formatValue_impl `$`, asIs

proc formatValue*(res: var string, self: IntObject; format_spec: static[string] = "") =
  impl(res, self, format_spec)
proc formatValue*(res: var string, self: IntObject; format_spec: string) =
  impl(res, self, format_spec)

when isMainModule:
  let i = newInt 123
  echo fmt"{i:0>10d}"
