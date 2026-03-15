
import std/hashes; export Hash
import ./[decl_private, decl]

const PyHASH_BITS = when sizeof(pointer) >= 8: 61 else: 31
const PyHASH_MODULUS = (1 shl PyHASH_BITS) - 1

type
  Py_uhash_t = uint

proc hash*(obj: IntObject): Hash =
  static:doAssert PyHASH_BITS > PyLong_SHIFT

  let digits = obj.digits
  var i = digits.len
  if i == 0:
    return 0

  let sign = int(obj.sign)

  dec i
  var x = Py_uhash_t(digits[i])
  assert x < Py_uhash_t(PyHASH_MODULUS)

  when PyHASH_BITS >= 2 * PyLong_SHIFT:
    assert i >= 1
    dec i
    x = x shl PyLong_SHIFT
    x += Py_uhash_t(digits[i])
    assert x < Py_uhash_t(PyHASH_MODULUS)

  while i > 0:
    dec i
    x = ((x shl PyLong_SHIFT) and Py_uhash_t(PyHASH_MODULUS)) or
      (x shr (PyHASH_BITS - PyLong_SHIFT))
    x += Py_uhash_t(digits[i])
    if x >= PyHASH_MODULUS:
      x -= PyHASH_MODULUS

  var signedX = Hash(x)
  signedX *= Hash(sign)
  if signedX == Hash(-1):
    signedX = Hash(-2)
  result = signedX
