
when defined(nimPreviewSlimSystem): import std/assertions
import ../bit_length_util

const approximate_isqrt_tab: array[192, uint8] = [
    128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139,
    140, 141, 142, 143, 144, 144, 145, 146, 147, 148, 149, 150,
    151, 151, 152, 153, 154, 155, 156, 156, 157, 158, 159, 160,
    160, 161, 162, 163, 164, 164, 165, 166, 167, 167, 168, 169,
    170, 170, 171, 172, 173, 173, 174, 175, 176, 176, 177, 178,
    179, 179, 180, 181, 181, 182, 183, 183, 184, 185, 186, 186,
    187, 188, 188, 189, 190, 190, 191, 192, 192, 193, 194, 194,
    195, 196, 196, 197, 198, 198, 199, 200, 200, 201, 201, 202,
    203, 203, 204, 205, 205, 206, 206, 207, 208, 208, 209, 210,
    210, 211, 211, 212, 213, 213, 214, 214, 215, 216, 216, 217,
    217, 218, 219, 219, 220, 220, 221, 221, 222, 223, 223, 224,
    224, 225, 225, 226, 227, 227, 228, 228, 229, 229, 230, 230,
    231, 232, 232, 233, 233, 234, 234, 235, 235, 236, 237, 237,
    238, 238, 239, 239, 240, 240, 241, 241, 242, 242, 243, 243,
    244, 244, 245, 246, 246, 247, 247, 248, 248, 249, 249, 250,
    250, 251, 251, 252, 252, 253, 253, 254, 254, 255, 255, 255,
]  ##[The approximate_isqrt_tab table provides approximate square roots for
    16-bit integers. For any n in the range 2**14 <= n < 2**16, the value

        a = approximate_isqrt_tab[(n >> 8) - 64]

    is an approximate square root of n, satisfying (a - 1)**2 < n < (a + 1)**2.

    The table was computed in Python using the expression:

        [min(round(sqrt(256*n + 128)), 255) for n in range(64, 256)]

    Or in Nim using the expression:

    ```Nim
    import std/sugar
    import std/math
    collect:
      for n in 64..255:
        min(round(sqrt(float(256*n + 128))), 255)
    ```
]##

func approximate_isqrt*(n: uint64 #[range[2u64 shl 62 .. uint64.high-1]]#): uint32{.inline.} =
  ##[ EXT. unstable.
  Approximate square root of a large 64-bit integer.

   Given `n` satisfying `2**62 <= n < 2**64`, return `a`
   satisfying `(a - 1)**2 < n < (a + 1)**2`.
  ]##
  assert n in 2u64 shl 61 .. uint64.high  # 2**62 ..< 2**64
  {.push boundChecks: off.}
  let idx = (n shr 56) - 64
  assert idx in (approximate_isqrt_tab.low.uint64 .. approximate_isqrt_tab.high.uint64)
  var u = uint32 approximate_isqrt_tab[cast[int](idx)]
  {.pop.}
  u = (u shl 7) + cast[uint32](n shr 41) div u
  (u shl 15) + cast[uint32]((n shr 17) div u)

func isqrtPositive*(n: Positive|uint64): int{.inline.} =
  ## EXT: isqrt for Positive only,
  ## as we all know, in Python:
  ##    - `isqrt(0)` == 0
  ##    - `isqrt(-<positive int>)` raises ValueError

  let nBits = n.bit_length()
  assert 0 < nBits

  let c = (nBits - 1) div 2

  assert c <= 31

  let shift = 31 - int c
  let m = uint64 n
  var u = approximate_isqrt(m shl (2*shift)) shr shift
  if uint64(u) * u > m:
    u.dec
  cast[int](u)

  #[slow impl:
  let c = (n.bit_lengthUsingBitops() - 1) div 2
  var
    a = 1
    d = 0
  if c != 0:
    for s in countdown(c.bit_lengthUsingBitops() - 1, 0):
      # Loop invariant: (a-1)**2 < (n >> 2*(c - d)) < (a+1)**2
      let e = d
      d = c shr s
      a = (a shl d - e - 1) + (n shr (2*c) - e - d + 1) div a

  result = a
  if (a*a > n):
    result.dec
  ]#

func isqrt*(n: Natural): int{.raises: [].} =
  runnableExamples:
    assert 2 == isqrt 5
  #[ the following is from CPython 3.10.5 source `Modules/mathmodule.c`:

    Here's Python code: 

    def isqrt(n):
        """
        Return the integer part of the square root of the input.
        """
        n = operator.index(n)

        if n < 0: raise ValueError("isqrt() argument must be nonnegative")
        if n == 0: return 0

        c = (n.bit_length() - 1) // 2
        a = 1
        d = 0
        for s in reversed(range(c.bit_length())):
            # Loop invariant: (a-1)**2 < (n >> 2*(c - d)) < (a+1)**2
            e = d
            d = c >> s
            a = (a << d - e - 1) + (n >> 2*c - e - d + 1) // a

        return a - (a*a > n)]#
  if n == 0: 0
  else: isqrtPositive(cast[Positive](n))


func isqrt*[T: SomeFloat](x: T): int{.raises: [].} =
  ## .. hint:: assuming x > 0 (raise `RangeDefect` otherwise (if not danger build))
  ## use math.isqrt if expecting raising `ValueError`
  let i = Natural(x)
  isqrt i
