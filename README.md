# Sodden - An Olden benchmarks cmake harness

## Introduction

This is a CMake build harness for the [Olden][1] benchmarks.

The actual source files for each benchmark are not included, but use [this][2] instead.


## Features

- Building of all 10 `C` programs of the suite
- Out-of-source builds thanks to [cmake][3]
- Capability to create LLVM bitcode files thanks to [llvm-ir-cmake-utils][4] and LLVM `opt` pass pipelines (see the
  `config/pipelines` subdirectory).
- Capability to configure and build any desired subset of the programs by using the corresponding configuration (see the
  `suite_*` files in the `config` subdirectory).


## Requirements

- cmake 3.0.0 or later
- a sensible C compiler


## How to use

1. `git clone --recursive` this repo and `git clone` the benchmark source [repo][2].
2. Create symlinks to the `src` subdirectory of each benchmark program.
   This can be automated with the relevant script found in the `utils/scripts/source_tree` subdirectory of this repo, 
   for example:

   `create-symlink-bmk-subdir.sh -c suite_all.txt -s [path-to]/olden/ -t [path-to]/sodden/olden/ -l src`

3. Create a directory for an out-of-source build and `cd` into it.
4. Run `cmake` and `cmake --build .` with that appropriate options.
   For examples on the various options have a look at the build scripts (provided for convenience) located in the
   `utils/scripts/source_tree` subdirectory.
5. Optionally, you can install the benchmarks by

   `cmake -DCMAKE_INSTALL_PREFIX=[path-to-install] -P cmake_install.cmake`

   Omitting `CMAKE_INSTALL_PREFIX` will use the `../install/` directory relative to the build directory.


## Benchmark-specific configuration options

### Timing

The harness defines a few macros, using the prefix `OLDEN_` in the `common/timing.h` header, that allow measuring the
execution duration of sections of code. This facility seems to have been present, but was stripped away at some point. 
Currently, these macros require a POSIX compliant system, so the specific detection is left to `cmake` with the use of
the `common/config.h.cmake` generated header. On non-POSIX system the macros have dummy/empty alternatives.

### Source language selection

Typically build tools for `C`/`C++` projects detect the source file language by rules based on the file extension. This
allows to invoke the corresponding compiler for each source file.

However, the programs of this benchmark suite are not very cleanly written, in terms of separation (and as much as this
is possible by `C` and `C++`). So, since one the goals is to rejuvenate the source code and convert it to `C++` while
allowing this to happen independently, the detection of the source language per benchmark happens at the `cmake` level.

Automatic source language detection is set to occur per benchmark program like this:

1. By default the source language is set to `C`.
2. File globbing is used to gather all `C` (`*.c`) and `C++` (`*.cpp`) source files.
3. If there is **at least** 1 `C++` file, the source language is changed to `C++`. 

So, in order to use the `C++` compiler for a benchmark, you need to have at least a `C++` source file in its source
directory.

### more TODO


## How the harness works

For a general description on how this harness operates please have a look [here][5].



[1]: http://www.martincarlisle.com/olden.html
[2]: https://github.com/compor/olden
[3]: https://cmake.org
[4]: https://github.com/compor/llvm-ir-cmake-utils
[5]: doc/harness.md

