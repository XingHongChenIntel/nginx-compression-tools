#!/bin/bash

# perf record -F 99 -a -g --call-graph dwarf -C 50-85
perf script > out2.perf
./FlameGraph/stackcollapse-perf.pl out2.perf > out2.floded
./FlameGraph/flamegraph.pl out2.floded > out2.svg