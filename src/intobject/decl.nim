

when defined(nimPreviewSlimSystem):
  import std/assertions
  export assertions

# Why reinvent such a bad wheel?
# because we seriously need low level control on our modules
#
# import ../../pyobject

# js can't process 64-bit int although nim has this type for js
when defined(js):
  type
    Digit = uint16
    TwoDigits = uint32
    SDigit = int32

  const
    digitBits = 16
    PyLong_DECIMAL_SHIFT = 5
    PyLong_DECIMAL_BASE = TwoDigits 100_000
    
  template truncate(x: TwoDigits): Digit =
    const mask = 0x0000FFFF
    Digit(x and mask)

else:
  type
    Digit = uint32
    TwoDigits = uint64
    SDigit = int64

  const
    digitBits = 32
    PyLong_DECIMAL_SHIFT = 10
    PyLong_DECIMAL_BASE = TwoDigits 10_000_000_000

  template truncate(x: TwoDigits): Digit =
    Digit(x)

type IntSign = enum
  Negative = -1
  Zero = 0
  Positive = 1

const
  PyLong_SHIFT = digitBits

# only export for ./intobject
export Digit, TwoDigits, SDigit, digitBits, truncate,
 IntSign, PyLong_SHIFT, PyLong_DECIMAL_SHIFT, PyLong_DECIMAL_BASE
# const digitPyLong_DECIMAL_BASE* = Digit PyLong_DECIMAL_BASE

# declarePyType Int(tpToken):
#TODO:intobject  ren to IntObject
#TODO:intobject  make attr private
type IntObject* = object
  #v: BigInt
  #v: int
  sign*: IntSign
  digits*: seq[Digit]

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
    result.sign = Positive
  # can't be negative
  else:
    result.sign = Zero

const sMaxValue = SDigit(high(Digit)) + 1
func fill[I: SomeInteger](digits: var typeof(IntObject.digits), ui: I){.cdecl.} =
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
    result.sign = Positive

proc newInt*[I: SomeUnsignedInt and not Digit](i: I): IntObject =
  result = newIntSimple()
  if i == 0:
    result.sign = Zero
    return
  result.sign = Positive
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
