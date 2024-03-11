#!/bin/bash

if [ -z $1 ]; then
  echo "Missing first positional argument";
  exit 1;
fi

FLAGS='-I/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include -Wno-nullability-completeness'
clang $FLAGS $3 -emit-llvm -S -c $1 -o ${2:-out.ll}

# clang -print-resource-dir