
import ./decl
proc setSignNegative*(self: var PyIntObject){.inline.} =
  self.sign = Negative

proc negative*(intObj: PyIntObject): bool {. inline .} =
  intObj.sign == Negative

proc zero*(intObj: PyIntObject): bool {. inline .} =
  intObj.sign == Zero

proc positive*(intObj: PyIntObject): bool {. inline .} =
  intObj.sign == IntSign.Positive

proc flipSign*(intObj: var PyIntObject) =
  ## `_PyLong_FlipSign`
  ## inner
  intObj.sign = IntSign(-int(intObj.sign))

proc negate*(self: var PyIntObject){.inline.} =
  ## currently the same as `flipSign`_ as we didn't have small int
  self.flipSign
