#!/usr/bin/env bash
# run_s6.sh  Figure 7 render (R on Cardinal), after s4 and s5.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/config.sh"
module purge; module load gcc/12.3.0 gdal/3.7.3 R/4.4.0
Rscript "$HERE/s6_fig7_core4_10m.R"
