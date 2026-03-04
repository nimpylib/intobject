
import std/unittest
import intobject

test "int from bytes simply":
  let b = "\xFF\xFF\xFF"
  let i = newInt(b, littleEndian, signed=true)
  check i == -1

test "int from bytes with more digits":
  let b2 = "\x01\x02\x03\x04"
  let i2 = newInt(b2, bigEndian)
  check i2 == 0x01020304
  check i2.to_bytes(4, bigEndian) == @b2

  let b3 = "\x05\x04\x03\x02\x01"
  check newInt(b3, littleEndian) == 0x0102030405
  check newInt(b3, bigEndian) ==    0x0504030201
  check newInt(b3, littleEndian).to_bytes(5, littleEndian) == @b3

test "int from bytes with signed and negative value":
  let b4 = "\x80\x00"
  let i4 = newInt(b4, bigEndian, signed=true)
  check i4 == -0x8000

  let b5 = "\x00\x00\x01"
  let i5 = newInt(b5, bigEndian, signed=false)
  check i5 == 1

  let b6 = "\xFF\xFF\x80"
  let i6 = newInt(b6, littleEndian, signed=true)
  check i6 == -0x7F0001
