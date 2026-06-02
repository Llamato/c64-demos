#!/bin/sh
mos-c64-clang -Os main.c gllm/gllm.c -o main.prg
x64sc main.prg