#!/bin/bash

FvwmCommand "Restart"

. /etc/profile.d/lmod.sh
module use /nfs/gpfs/PZS0645/local-ruby/share/modulefiles
module load wine
module use /nfs/gpfs/PZS0645/local-ruby/emc2/share/modulefiles
module load vft/i686

cd ${VFT_HOME}
VFTHOME="Z:\\${PBS_O_WORKDIR}" MATDIR="${MATDIR}" wine Project2.exe
