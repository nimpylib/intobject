
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
type IntObject* = object
  #v: BigInt
  #v: int
  pri_sign: IntSign
  pri_digits: seq[Digit]

type SomeIntegerOrObj* = SomeInteger | IntObject

{.push inline.}
func sign*(self: IntObject): IntSign = self.pri_sign  ## public api (the only one among these accessors)
func digits*(self: IntObject): seq[Digit] = self.pri_digits  ## inner

func sign*(self: var IntObject): var IntSign = self.pri_sign  ## inner
func digits*(self: var IntObject): var seq[Digit] = self.pri_digits  ## inner

func `sign=`*(self: var IntObject; s: IntSign) = self.pri_sign = s  ## inner
func `digits=`*(self: var IntObject; s: seq[Digit]) = self.pri_digits = s  ## inner
{.pop.}
