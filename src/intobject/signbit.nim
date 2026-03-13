
import ./[decl_private, decl]
proc setSignNegative*(self: var IntObject){.inline.} =
  self.sign = Negative

proc isNegative*(intObj: IntObject): bool {. inline .} =
  intObj.sign == Negative

proc isZero*(intObj: IntObject): bool {. inline .} =
  intObj.sign == Zero

proc isPositive*(intObj: IntObject): bool {. inline .} =
  intObj.sign == IntSign.Positive

proc flipSign*(intObj: var IntObject) =
  ## `_PyLong_FlipSign`
  ## inner
  intObj.sign = IntSign(-int(intObj.sign))

proc negate*(self: var IntObject){.inline.} =
  ## `self = -self`
  ##
  ## currently the same as `flipSign`_ as we didn't have small int
  self.flipSign

proc isOdd*(i: IntObject): bool =
  not i.isZero and (i.digits[0] mod 2 == 1)

proc isEven*(i: IntObject): bool =
  i.isZero or (i.digits[0] mod 2 == 0)
