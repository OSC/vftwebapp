#!/bin/bash

FvwmCommand "Restart"

. /etc/profile.d/lmod.sh
module use /users/PZS0645/wiag/local-ruby/share/modulefiles
module load wine
module use /users/PZS0645/wiag/local-ruby/emc2/share/modulefiles
module load ctsp    # necessary for writing out WARP3D cut
module load vft/i686

cd ${VFT_HOME}
VFTHOME="Z:\\${PBS_O_WORKDIR}" MATDIR="${MATDIR}" TEMP_CONVERT="$(command -v temp_convert.x)" wine Project2.exe
