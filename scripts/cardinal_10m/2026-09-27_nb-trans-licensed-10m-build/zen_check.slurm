#!/bin/bash
#SBATCH --job-name=nbt_zchk
#SBATCH --account=PUOM0008
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/2026-09-27_nb-trans-licensed-10m-build/zen_check_%j.log
cd /users/PUOM0008/crsfaaron/LSOG/products/nb-trans-licensed-10m_2026-09-27/zenodo_upload
export MPLCONFIGDIR=/tmp/mpl_$$
cp -p build_abstract.py code/build_abstract.py
ZPKG=$PWD /usr/bin/python3 build_abstract.py
/usr/bin/python3 check_deposit.py
