#!/bin/sh
rm charsets.d64
nix build .#charsets
cp result/charsets.d64 .
chmod 755 charsets.d64
x64sc charsets.d64