# Package

version       = "0.1.0"
author        = "litlighilit"
description   = "bigint (arbitrary precision integers) library, more ops/methods defined"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.8"
var pylibPre = "https://github.com/nimpylib"
let envVal = getEnv("NIMPYLIB_PKGS_BARE_PREFIX")
if envVal != "": pylibPre = ""
elif pylibPre[^1] != '/':
  pylibPre.add '/'
template pylib(x, ver) =
  requires if pylibPre == "": x & ver
           else: pylibPre & x
pylib "nimpatch", " ^= 0.1.0"
pylib "unicode_space_decimal", " ^= 0.1.0"
pylib "handy_sugars", " ^= 0.1.0"
