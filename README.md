# rnim

I have been facing problems with R's memory management profile and will soon need to decouple the most computation intensive parts to other more efficient languages. But I refuse learning cpp and Nim comes as an excellent alternative! This is a complement to the [nim](https://nim-lang.org/) [rnim](https://github.com/SciNim/rnim) package, so to simplify and automate a few steps (like the compiling).

This is right now a simple function to load a Nim library into R memory.

WARNING: alpha quality software, if at all working. Use at your own risk!


# Installation instructions

## Dependencies

You will need first:

- [nim](https://nim-lang.org/)
- [rnim](https://github.com/SciNim/rnim)

## In R


```r
#install.packages("devtools")
devtools::install_github("lf-araujo/rnim")
library("rnim")
```

# Use

It is a simple function at the moment. You just create a nim file containing the functions that will perform any of your heavy computations,
then you declare functions in R using the .Call() syntax as explained in [rnim](https://github.com/SciNim/rnim) and the objects created will
be available in R memory!

# No test units as this is the first commit

But you can for example place the following `tNimFromR.nim` file:

```nim
import rnim
import std / [sequtils, unittest]

#[
Compile this with

nim c --app:lib --gc:arc tNimFromR.nim

and then run the corresponding R test:

Rscript tCallNimFromR.R

If it doesn't throw an error the tests passed.

(ARC is optional)
]#

func addXYInt*(x: SEXP, y: SEXP): SEXP {.exportR.} =
  # assuming x, y are ints
  let
    xNim = x.to(int)
    yNim = y.to(int)
  result = nimToR(xNim + yNim)

proc addXYFloat*(x, y: SEXP): SEXP {.exportR.} =
  # assuming x, y are floats
  let
    xNim = x.to(float)
    yNim = y.to(float)
  result = nimToR(xNim + yNim)

proc addVecs*(x, y: SEXP): SEXP {.exportR.} =
  let
    xNim = x.to(seq[float])
    yNim = y.to(seq[float])
  var res = newSeq[float](xNim.len)
  for i in 0 ..< xNim.len:
    res[i] = (xNim[i] + yNim[i]).float
  result = nimToR(res)

proc printVec*(v: SEXP) {.exportR.} =
  let nv = initNumericVector[float](v)
  for i in 0 .. nv.high:
    echo nv[i]

  for x in nv:
    echo x

  for i, x in nv:
    echo "index ", i, " contains ", x

proc modifyVec*(v: SEXP) {.exportR.} =
  var nv = initRawVector[float](v)
  for x in mitems(nv):
    x = x + 1.0

proc checkVector[T](v: NumericVector[T]) =
  ## checks the given vector to be our expectation
  test "Checking vector of type " & $typeof(v):
    let exp = @[1, 2, 3, 4, 5].mapIt(it.T)
    check v.len == exp.len
    for i in 0 ..< v.len:
      check v[i] == exp[i]

proc checkSexp*(s: SEXP) {.exportR.} =
  suite "NumericVector tests":
    proc checkType[T](s: SEXP) =
      let nv = initNumericVector[T](s)
      checkVector(nv)
    checkType[int32](s)
    checkType[cint](s)
    checkType[int](s)
    checkType[int64](s)
    checkType[float](s)
    checkType[float32](s)
    checkType[cdouble](s)
    checkType[cfloat](s)
    #checkType[uint8](s)

proc checkVector[T](v: RawVector[T]) =
  ## checks the given vector to be our expectation
  test "Checking vector of type " & $typeof(v):
    let exp = @[1, 2, 3, 4, 5].mapIt(it.T)
    check v.len == exp.len
    for i in 0 ..< v.len:
      check v[i] == exp[i]

proc checkSexpRaw*(s: SEXP) {.exportR.} =
  suite "RawVector tests":
    proc checkType[T](s: SEXP) =
      let nv = initRawVector[T](s)
      checkVector(nv)
    checkType[int32](s)
    checkType[cint](s)
    checkType[float](s)
    checkType[cdouble](s)


#[
I think the below is only relevant for complicated modules
let callMethods* = [
  R_CallMethodDef(name: "addXY".cstring,
                  fun: cast[DL_FUNC](addXY),
                  numArgs: 2.cint),
  R_CallMethodDef(name: nil, fun: nil, numArgs: 0)
]

proc updateStackBottom() {.inline.} =
  when not defined(gcDestructors):
    var a {.volatile.}: int
    nimGC_setStackBottom(cast[pointer](cast[uint](addr a)))
    when compileOption("threads") and not compileOption("tlsEmulation"):
      if not gcInited:
        gcInited = true
        setupForeignThreadGC()

proc R_init_tNimFromR*(info: ptr DllInfo) {.exportc: "R_init_tNimFromR", cdecl, dynlib.} =
  updateStackBottom()
  echo "now"
  echo callMethods[0].unsafeAddr.isNil
  R_RegisterRoutines(info, nil, callMethods[0].unsafeAddr, nil, nil)
  echo ":("

proc R_unload_tNimFromR*(info: ptr DllInfo) {.exportc: "R_unload_tNimFromR", cdecl, dynlib.} =
  # what to do?
  discard

]#
```


Then load it from an R file using `loadNim()`:

```r
library(rnim)
loadNim("tNimFromR")


addXYInt <- function(x, y) {
      return(.Call("addXYInt", x, y))

}


addXYFloat <- function(x, y) {
      return(.Call("addXYFloat", x, y))

}


addVecs <- function(x, y) {
      return(.Call("addVecs", x, y))

}


printVec <- function(v) {
      invisible(.Call("printVec", v))

}


modifyVec <- function(v) {
      invisible(.Call("modifyVec", v))

}


checkSexp <- function(s) {
      invisible(.Call("checkSexp", s))

}


checkSexpRaw <- function(s) {
      invisible(.Call("checkSexpRaw", s))

}



check <- function(arg) {
    if (!all(arg)){
        stop(paste("Failed to run ", deparse(arg)))
    }
}


check(addXYInt(1L, 1L) == 1L + 1L)
check(addXYFloat(1L, 1L) == 1.0 + 1.0)

check(addXYInt(1.0, 1.0) == 1L + 1L)
check(addXYFloat(1.0, 1.0) == 1.0 + 1.0)

x <- 1:5

check(addVecs(x, x) == x + x)

y <- c(1.0, 2.0, 3.5, 4.0, 5.2)

check(addVecs(y, y) == y + y)

check(addVecs(x, y) == x + y)

yOrig <- c(1.0, 2.0, 3.5, 4.0, 5.2)
modifyVec(y)
check(y == yOrig + 1.0)

printVec(y)


checkSexp(x)
checkSexpRaw(x)

```
