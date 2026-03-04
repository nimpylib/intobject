
import ./decl
import ./[ops, ops_bitwise]
#[ XXX:NIM-BUG: not works:
import std/macros
macro private_mixOpIntWithNim*{(`+`|`-`|`*`|`div`|`mod`){op}(a, b)}(
  a: IntObject, op: untyped, b: SomeInteger): untyped =
  quote do: `op` `a`, newInt(`b`)
]#

template private_gen_mix*(mix; prim, pyT: typedesc; do1, do2){.dirty.} =
  template mix(op){.dirty.} =
    template `op`*(a: pyT, b: prim): untyped = do1
    template `op`*(a: prim, b: pyT): untyped = do2

private_gen_mix mix, SomeInteger, IntObject:
  bind op, newInt
  op(a, newInt(b))
do:
  bind op, newInt
  op(newInt(a), b)

template private_mixOpPyWithNim*(mixb, mix){.dirty.} =
  mixb `==`
  mixb `<`
  mixb `<=`

  mix `+`
  mix `-`
  mix `*`
  # mix `div`
  # mix `mod`
  mix `%`
  mix `//`

  mix divmod
  mix pow

template private_mixOpPyWithNim_with_div_mod_bitwise*(mixb, mix){.dirty.} =
  private_mixOpPyWithNim mixb, mix
  mix `div`
  mix `mod`

  mix `and`
  mix `or`
  mix `xor`
  mix `shl`
  mix `shr`

private_mixOpPyWithNim_with_div_mod_bitwise mix, mix

when isMainModule:
  let t = newInt(10)
  discard t * 2
  discard t <= 2
  discard t shl 2
  discard t mod 3
