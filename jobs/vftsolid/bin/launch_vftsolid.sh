#!/bin/bash

FvwmCommand "Restart"

. /etc/profile.d/lmod.sh


# module load wine/5.1
module use /users/PZS0645/wiag/local-ruby/share/modulefiles
module load wine/1.8.6

module use /users/PZS0645/wiag/local-owens/emc2/share/modulefiles
module load ctsp    # necessary for writing out WARP3D cut
module load vft/i686

cd ${VFT_HOME}
VFTHOME="Z:\\${SLURM_SUBMIT_DIR}" MATDIR="${MATDIR}" TEMP_CONVERT="$(command -v temp_convert.x)" wine Project2.exe
