#!/bin/bash

if [ -d lib ]; then
  rm -rf lib
fi

if [ -d build ]; then
  rm -rf build 
fi

if [ -d bin ]; then
  rm -rf bin
fi

if [ -d docs ]; then
  rm -rf docs
fi

if [ -d .deps ]; then
  rm -rf .deps
fi

if [ -f test_report.txt ]; then
  rm -f test_report.txt
fi

