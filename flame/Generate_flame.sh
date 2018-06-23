#!/bin/bash

# perf record -F 99 -a -g --call-graph dwarf -C 100-115
perf script > out2.perf
/root/xinghong/FlameGraph/stackcollapse-perf.pl out2.perf > out2.floded
/root/xinghong/FlameGraph/flamegraph.pl out2.floded > out2.svg