

# Why reinvent such a bad wheel?
# because we seriously need low level control on our modules
#
# import ../../pyobject

import ./decl_private
# We do export `sign` (getter), which is public api
export decl_private except digits, `sign=`, `digits=`

when defined(nimPreviewSlimSystem):
  import std/assertions
  export assertions


# declarePyType Int(tpToken):
when isMainModule:
  var a: IntObject
  a.sign = a.sign

proc isNil*(self: IntObject): bool {.inline.} = false
proc newIntSimple*(): IntObject =
  result = IntObject()
  result.sign = Zero

#proc compatSign(op: IntObject): SDigit{.inline.} = cast[SDigit](op.sign)
# NOTE: CPython uses 0,1,2 for IntSign, so its `_PyLong_CompactSign` is `1 - sign`

#proc newInt(i: Digit): IntObject
proc newInt*(o: IntObject): IntObject =
  ## deep copy, returning a new object
  result = newIntSimple()
  result.sign = o.sign
  result.digits = o.digits

proc newInt*(i: Digit): IntObject =
  result = newIntSimple()
  if i != 0:
    result.digits.add i
    result.sign = IntSign.Positive
  # can't be negative
  else:
    result.sign = Zero

const sMaxValue = SDigit(high(Digit)) + 1
func fill[I: SomeInteger](digits: var seq[Digit], ui: I){.cdecl.} =
  var ui = ui
  while ui != 0:
    digits.add Digit(
      when sizeof(I) <= sizeof(SDigit): ui
      else: ui mod I(sMaxValue)
    )
    ui = ui shr digitBits

proc newInt*[I: SomeSignedInt](i: I): IntObject =
  result = newIntSimple()
  result.digits.fill abs(i)

  if i < 0:
    result.sign = Negative
  elif i == 0:
    result.sign = Zero
  else:
    result.sign = IntSign.Positive

proc newInt*[I: SomeUnsignedInt and not Digit](i: I): IntObject =
  result = newIntSimple()
  if i == 0:
    result.sign = Zero
    return
  result.sign = IntSign.Positive
  result.digits.fill i

const bigintErr = defined(js) and compileOption("jsBigInt64")
when bigintErr:
  import std/hashes

proc newIntFromPtr*(p: pointer): IntObject =
  ## `PyLong_FromVoidPtr`
  newInt(
    when bigintErr: hash(p)
    else: cast[int](p)
  )
proc newIntFromPtr*[I: ref | ptr](i: I): IntObject =
  newIntFromPtr cast[pointer](i)
