#!/bin/bash

# ===============================================
# Example for performing initial spin up
# for calLMIP PLUMBER sites

# ===============================================
# config
# ===============================================

work='/glade/work/linnia/'
tag='ctsm5.4.004'

casedir='/glade/work/linnia/calLMIP/spinup/'
user_mods_dir='/glade/work/linnia/calLMIP/usermods_dirs/'
site='DK-Sor'
export PROJECT=P93300041
chargenum=P93300041

module load conda
conda activate ctsm_pylib

AD_casename='ctsm54004_bgc_'${site}'_AD_spin'
postAD_casename='ctsm54004_bgc_'${site}'_postAD_spin'

# ==============================================
# do these one at a time, wait until each stage completes
# ===============================================

checkout_codebase=0
do_AD=0
do_postAD=1

# ===============================================
# check out codebase
# ===============================================

if [ "$checkout_codebase" -eq 1 ]; then
    cd $work
    git clone --branch ${tag} https://github.com/ESCOMP/CTSM.git $tag
    cd $tag
    ./bin/git-fleximod update
fi

# ===============================================
# setup AD spinup (accelerated decomposition)
# ===============================================

if [ "$do_AD" -eq 1 ]; then

    cd ${work}${tag}/cime/scripts/

    ./create_newcase --case ${casedir}${AD_casename} --res CLM_USRDAT --compset 1850_DATM%1PT_CLM60%BGC_SICE_SOCN_SROF_SGLC_SWAV_SESP --project ${chargenum} --run-unsupported --user-mods-dirs ${user_mods_dir}${site}

    cd ${casedir}${AD_casename}
    ./case.setup --reset

    # env_run.xml
    ./xmlchange STOP_N=180 
    ./xmlchange CLM_ACCELERATED_SPINUP=on
    ./xmlchange CLM_FORCE_COLDSTART=on

    ./xmlchange JOB_WALLCLOCK_TIME=06:00:00
    ./xmlchange JOB_QUEUE=develop
    ./xmlchange JOB_PRIORITY=regular

    ./preview_namelists
    ./case.build
    ./case.submit
fi

# ==============================================
# setup postAD spinup 
# ==============================================

if [ "$do_postAD" -eq 1 ]; then
    cd ${work}${tag}/cime/scripts/

    ./create_clone --case ${casedir}${postAD_casename} --clone ${casedir}${AD_casename} --project ${chargenum}

    cd ${casedir}${postAD_casename}
    ./case.setup --reset

    # user_nl_clm mods
    echo "clm_start_type = 'startup'" >> user_nl_clm

    finidat=$(ls ${SCRATCH}/archive/${AD_casename}'/rest/0'*'/'*".clm2.r."*".nc" | tail -n 1)
    finidat=$(echo $finidat) #expands wildcard
    echo "finidat = '$finidat'" >> user_nl_clm

    ./xmlchange STOP_N=240
    ./xmlchange RESUBMIT=1
    ./xmlchange CLM_ACCELERATED_SPINUP=off
    ./xmlchange CLM_FORCE_COLDSTART=off

    ./xmlchange JOB_WALLCLOCK_TIME=06:00:00

    ./preview_namelists
    ./case.build
    ./case.submit

fi