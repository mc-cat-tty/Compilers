#!/bin/bash

FLAGS='-I/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include -Wno-nullability-completeness'
alias clang="clang $FLAGS"
export PATH=~/Documents/llvm17_compilers/install/bin:$PATH
