when defined(nimPreviewSlimSystem):
  import std/assertions
  export assertions
func unreachableProc{.noReturn.} = doAssert false, "unreachable"
template unreachable* =
  bind unreachableProc
  unreachableProc()
