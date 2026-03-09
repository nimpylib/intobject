
# intobject

[![Test](https://github.com/nimpylib/intobject/actions/workflows/ci.yml/badge.svg)](https://github.com/nimpylib/intobject/actions/workflows/ci.yml)
[![Docs](https://github.com/nimpylib/intobject/actions/workflows/docs.yml/badge.svg)](https://github.com/nimpylib/intobject/actions/workflows/docs.yml)
<!--[![Commits](https://img.shields.io/github/last-commit/nimpylib/intobject?style=flat)](https://github.com/nimpylib/intobject/commits/)-->

---

[Docs](https://nimpylib.github.io/intobject/)

big integer library for Nim, a.k.a. arbirary precision ineger or bignums

This library is initially used for implementing python's `int` (a.k.a. npyhon's)

## why not use existing library?
python's `int` object has too many methods/relative functions, none of existing supports all as of now.

For example, `pkg/bigints` lacks `int.to_bytes`, `int.from_bytes`

## Features
- mix Nim builtin integers (`SomeInteger`)
  e.g. `1'iobj + 3 == 4`

