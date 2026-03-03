
import ./decl


proc newIntOfLen*(L: int): IntObject =
  ## `long_alloc`
  ## 
  ## result sign is `Positive` if l != 0; `Zero` otherwise
  result = newIntSimple()
  result.digits.setLen(L)
  if L != 0:
    result.sign = Positive

when declared(setLenUninit):
  template setLenUninit*(intObj: IntObject, L: int) =
    intObj.digits.setLenUninit(L)
else:
  template setLenUninit*(intObj: IntObject, L: int) =
    intObj.digits.setLen(L)

proc newIntOfLenUninit*(L: int): IntObject =
  result = newIntSimple()
  result.setLenUninit(L)
  if L != 0:
    result.sign = Positive

proc setSignAndDigitCount*(intObj: var IntObject, sign: IntSign, digitCount: int) =
  ## `_PyLong_SetSignAndDigitCount`
  intObj.sign = sign
  intObj.digits.setLen(digitCount)

proc copy*(intObj: IntObject): IntObject =
  ## XXX: copy only digits (sign uninit!)
  result = newIntSimple()
  result.digits = intObj.digits
proc normalize*(a: var IntObject) =
  for i in 0..<a.digits.len:
    if a.digits[^1] == 0:
      discard a.digits.pop()
    else:
      break
