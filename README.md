# common
Utilities, written in FreePascal

## bigint.pas
A unit for handling big integers.
- support for basic operation
- Miller Rabin primality test
- factorization routines

## cmdLineParseUtil.pas
Utilities for command line parsing

## diff.pas
A simplified diff.
I found the source somewhere and cleaned it up.

## huffman.pas
Related:
- huffman_model_default.inc
- huffman_model_mnh.inc
- huffman_model_numeric.inc
- huffman_model_wiki.inc
Implementation of a fixed table huffman encoder with a simple markov model.
Intended mainly for compression of short texts.

## mySys.pas
Routines for handling system accesses.

## myGenerics.pas
Simple (partly generic) implementations of (sortable) arrays, maps and sets.
Relies heavily on Macros.

## myStringUtil.pas
String routines including formatting, replacing, etc.

## myCrypto.pas
- ISAAC random generator
- SHA256

## serializationUtil.pas
Utilities for reading to (and writing from) streams.

## httpUtil.pas
Wrapper functions around Synapse to simplify HTTP server functionality.

## myColors.pas
Different color models: RGB, HSV, with and without alpha-channel, 8 bit per channel and single precision float per channel.

## pixMaps.pas
Generic pixel map based on the types in myColors.

## fileHistories.pas
An old implementation for file histories
Currently outdated.

## globalformhandler.pas
Experimental unit for handling alignments of multiple forms in one Lazarus application.
Currently outdated.

## scalableGrafx.pas
Experimental unit for scalable graphics.
Currently outdated.
