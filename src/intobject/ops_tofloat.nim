

import ./[
  decl, signbit,
  frexp, ops_dollar
]
include ./private/common_h
import ./private/utils

when not HasLdExp:
  import std/strutils

proc toFloat*(pyInt: IntObject; overflow: var bool): float{.pyCFuncPragma.} =
  ## `PyLong_AsDouble`
  overflow = false
  when not HasLdexp:
    try: parseFloat(ops_dollar.`$` pyInt)  #TODO:opt
    except ValueError: unreachable
  else:
    var exponent: int64
    let x = frexp(pyInt, exponent)
    assert exponent >= 0
    if exponent > DBL_MAX_EXP:
      overflow = true
      return -1.0
    ldexp(x, cint exponent)


proc toFloat*(pyInt: IntObject): float{.pyCFuncPragma.} =
  ## `PyLong_AsDouble` but never OverflowError, just returns `+-Inf`
  var ovf: bool
  result = pyInt.toFloat ovf
  if not ovf: return
  result = if pyInt.negative: NegInf
  else: Inf

proc toFloat*(pyInt: IntObject; res: var float): bool{.pyCFuncPragma.} =
  res = pyInt.toFloat result
