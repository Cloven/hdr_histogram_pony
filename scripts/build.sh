#!/bin/bash

if [ ! -d lib ]; then
  mkdir lib
fi

if [ ! -d build ]; then
  mkdir build 
fi

if [ ! -d bin ]; then
  mkdir bin
fi

# Build HDR Histogram dependency
if [ ! -f lib/libhdr_histogram_static.a ]; then
  echo "HdrHistogram_c: Fetching"
  stable fetch
  echo "HdrHistogram_c: Building"
  mkdir .deps/HdrHistogram/HdrHistogram_c/build
  cd .deps/HdrHistogram/HdrHistogram_c/build && cmake .. && make
  cd ../../../..
  cp .deps/HdrHistogram/HdrHistogram_c/build/src/libhdr_histogram_static.a lib
else
  echo "HdrHistogram_c: Already built"
fi

# Build native helper code
if [ ! -f lib/libhdr_histogram_pony_helper.a ]; then
  echo "HdrPonyHelper_c: Building"
  clang -I.deps/HdrHistogram/build/src -Iinclude -c c_src/hdr_histogram_pony_helper.c -o hdr_histogram_pony_helper.o
  ar -rcs lib/libhdr_histogram_pony_helper.a hdr_histogram_pony_helper.o
  rm -f hdr_histogram_pony_helper.o
else
  echo "HdrPonyHelper_c: Already built"
fi

# Build the tests
if [ ! -f ./bin/hdr_tests ]; then
  echo "Hdr_pony_tests: Building"
  ponyc -p lib --docs packages/hdr -o build/hdr_unit_tests
  cp build/hdr_unit_tests/hdr bin/hdr_tests
  mv build/hdr_unit_tests/hdr-docs docs
  if hash mkdocs 2> /dev/null ; then
    echo "Generating doc site"
    cd docs && mkdocs build
  fi
else
  echo "Hdr_pony_tests: Already built"
fi

if [ ! -f ./test_report.txt ]; then
  echo "Hdr_pony_tests: Running tests"
  bin/hdr_tests | tee test_report.txt
  if [ "$#" == "0" ]; then
    echo "All tests passed"
  else
    echo "Tests failed"
  fi
fi

if [ ! -f ./bin/examples_simple ]; then
    echo "Building example"
    mkdir -p build/examples
    ponyc -p lib -p packages examples/simple -o build/examples_simple
    cp build/examples_simple/simple bin/examples_simple
else
  echo "Example already built"
fi

if [ -x ./bin/examples_simple ]; then
    ./bin/examples_simple
fi

echo "Done!"
