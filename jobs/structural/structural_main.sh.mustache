#!/bin/bash
#SBATCH --job-name structural
#SBATCH --time={{structural_walltime}}:00:00
#SBATCH --nodes=1
#SBATCH --tasks-per-node=28
#SBATCH -o {{{structural_log_file}}}

# Global Settings
WORKSPACE="${SLURM_SUBMIT_DIR}"
STAGEDDIR="${SLURM_SUBMIT_DIR}"
LOGDIR="{{{log_root}}}"
ERRORFILE="{{{structural_error_file}}}"

# WARP3D Settings
PATTERN="*.wrp"

########################################################
# Don't edit below unless you know what you are doing
########################################################

echo "---Job started at:"
date
echo ""

# Clean up and copy back workspace
clean_up ()
{
  paraview
  echo "Cleaning up temporary workspace (${WORKSPACE})..."
  time rsync -avu "${WORKSPACE}/" "${STAGEDDIR}"
  echo "Done cleaning up"
}

# Kill batch script and clean up
die ()
{
  echo "ERROR: $1" 1>&2
  echo "$1" >> ${ERRORFILE}
  clean_up
  exit 1
}

# Check the exit status code of program
check_status ()
{
  if [[ $1 -ne 0 ]]; then
    die "Failed on '$2'"
  fi
}

# Initialize workspace
init ()
{
  echo "Creating temporary workspace (${WORKSPACE})..."
  time rsync -av "${STAGEDDIR}/" "${WORKSPACE}"
  echo "Done creating temporary workspace"
  cd "${WORKSPACE}"
}

# Run paraview output
paraview ()
{
  # Only ever call this once
  [[ -n ${RAN_PARAVIEW} ]] && return
  RAN_PARAVIEW="true"

  # Generate Paraview files
  # First find the flat file
  FLATFILE="{{{warp3d_flat_file_name}}}"
  if [[ ! -f "${FLATFILE}" ]]; then
    die "Unable to find the flat file (${FLATFILE})"
  fi

  # Execute warp3d2exii
  echo "Generating Paraview input files"
  echo "" >> "${LOGFILE}"
  time cat <<EOF | warp3d2exii &>> "${LOGFILE}"
wrp
1
${FLATFILE}
.
n
y
EOF
  check_status $? warp3d2exii
}

# Rotate a file
rotate () {
  [[ -e "$1" ]]
  local suffix=0
  while [[ -e "$1.$((++suffix))" ]]; do true; done
  mv -v "$1" "$1.${suffix}"
}

module load python/2.7

# Set up WARP3D environment (use default WARP3D module)
module use /users/PZS0645/wiag/local-owens/emc2/share/modulefiles
module load intel/19.0.5 intelmpi/2019.7
module load warp3d
source $WARP3D_VENV/bin/activate



# Set up trap function
# Note: must be defined after `module load`
trap "die 'Unexpected termination'" TERM

# Create workspace in tmp directory
init

# Create common log file
LOGFILE="${LOGDIR}/warp3d.log"
rotate "${LOGFILE}"
> "${LOGFILE}"

# WARP3D execution
echo "Running WARP3D"
time timeout $((SLURM_TIME_LIMIT-600)) warp3d.omp < "{{#restart_file}}restart_wrp{{/restart_file}}{{^restart_file}}{{{warp3d_input_file_name}}}{{/restart_file}}" &>> "${LOGFILE}"
check_status $? warp3d.omp

# Simple error checking

# - counting "Errors:" in logfile
ECOUNT=$(awk -F: 'BEGIN{e=0;} /Errors:/{e+=$2;} END{print e;}' "${LOGFILE}")
if [[ ${ECOUNT} -ne 0 ]]; then
  die "Errors were detected in the WARP3D calculation"
fi

# - check for "FATAL ERRORS" in logfile
if grep -aq "FATAL ERROR:" "${LOGFILE}"; then
  die "A fatal error was detected in the WARP3D calculation"
fi

# Always clean up after yourself
clean_up

echo ""
echo "---Job finished at:"
date

exit 0
