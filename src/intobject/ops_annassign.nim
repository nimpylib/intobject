
import std/macros
import ./[decl, ops_mix_nim]

template genAnnAssignAux(inplaceop, op){.dirty.} =
  proc inplaceop*(a: var IntObject; b: SomeIntegerOrObj){.inline.} =
    a = op(a, b)

macro genAnnAssign(op: static[string]) =
  let iop = op & '='
  getAst genAnnAssignAux(ident iop, ident op)

genAnnAssign "+"
genAnnAssign "-"
genAnnAssign "*"
genAnnAssign "//"
genAnnAssign "%"
# genAnnAssign "**"

template genIncDec(incOrDec, plusOrMinus){.dirty.} =
  genAnnAssignAux incOrDec, plusOrMinus
  template incOrDec*(a: var IntObject) =
    incOrDec(a, 1)
genIncDec `inc`, `+`
genIncDec `dec`, `-`

when isMainModule:
  block:
    var t = newInt(10)
    t += 2
    t.inc
    t.dec
    t -= 2
    t *= 2
    t //= 3
    t %= 3
