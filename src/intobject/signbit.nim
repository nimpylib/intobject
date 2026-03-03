
import ./decl
proc setSignNegative*(self: var IntObject){.inline.} =
  self.sign = Negative

proc negative*(intObj: IntObject): bool {. inline .} =
  intObj.sign == Negative

proc zero*(intObj: IntObject): bool {. inline .} =
  intObj.sign == Zero

proc positive*(intObj: IntObject): bool {. inline .} =
  intObj.sign == IntSign.Positive

proc flipSign*(intObj: var IntObject) =
  ## `_PyLong_FlipSign`
  ## inner
  intObj.sign = IntSign(-int(intObj.sign))

proc negate*(self: var IntObject){.inline.} =
  ## currently the same as `flipSign`_ as we didn't have small int
  self.flipSign
