
import std/bitops
export popcount
const BitPerByte = 8
proc bit_length*(self: SomeInteger): int =
  when defined(noUndefinedBitOpts):
    1 + fastLog2(
      when self is SomeSignedInt: abs(self)
      else: self
    )
  else:
    sizeof(self) * BitPerByte - bitops.countLeadingZeroBits self
