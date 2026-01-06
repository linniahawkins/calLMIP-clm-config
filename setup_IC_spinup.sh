# ===============================================
# instructions for setting up initial spin up 
# for calLMIP PLUMBER sites
# (just instructions, this is not meant to be executed)

# ===============================================
# check out codebase
# ===============================================
work='/glade/work/linnia/'
tag='ctsm5.4.004'

cd $work
git clone --branch ${tag} https://github.com/ESCOMP/CTSM.git $tag
cd $tag
./bin/git-fleximod update

# ===============================================
# create spin up base cases for DK-Sor
# ===============================================

casedir='/glade/work/linnia/calLMIP/basecases/'
user_mods_dir='/glade/work/linnia/calLMIP/usermods_dirs/'
site='DK-Sor'
export PROJECT=P93300041
chargenum=P93300041

module load conda
conda activate ctsm_pylib

# ===============================================
# setup AD spinup (accelerated decomposition)
# ===============================================

AD_casename='ctsm54004_bgc_'${site}'_AD_test'

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

# Submit case
#./case.submit

# ==============================================
# setup SASU spinup (matrix)
# ==============================================

SASU_casename='ctsm54004_bgc_'${site}'_SASU_test'

cd ${work}${tag}/cime/scripts/

./create_clone --case ${casedir}${SASU_casename} --clone ${casedir}${AD_casename} --project ${chargenum}

cd ${casedir}${SASU_casename}
./case.setup --reset

# user_nl_clm mods
echo "clm_start_type = 'startup'" >> user_nl_clm

finidat=$(ls ${SCRATCH}/archive/${AD_casename}'/rest/0'*'/'*".clm2.r."*".nc" | tail -n 1)
finidat=$(echo $finidat) #expands wildcard
echo "finidat = '$finidat'" >> user_nl_clm

./xmlchange STOP_N=180 
./xmlchange CLM_ACCELERATED_SPINUP=sasu
./xmlchange CLM_FORCE_COLDSTART=off

./preview_namelists
./case.build

# Submit case
#./case.submit

# ===============================================
# setup postSASU spinup 
# ==============================================

pSASU_casename='ctsm54004_bgc_'${site}'_pSASU_test'

cd ${work}${tag}/cime/scripts/

./create_clone --case ${casedir}${pSASU_casename} --clone ${casedir}${AD_casename} --project ${chargenum}

cd ${casedir}${pSASU_casename}
./case.setup --reset

# user_nl_clm mods
echo "clm_start_type='startup'" >> user_nl_clm
finidat=$(ls ${SCRATCH}/${AD_casename}'/run/'${AD_casename}".clm2.r."*".nc" | tail -n 1)
finidat=$(echo $finidat) #expands wildcard
echo "finidat = '$finidat'" >> user_nl_clm

./xmlchange STOP_N=180 
./xmlchange RESUBMIT=0
./xmlchange CLM_ACCELERATED_SPINUP=off
./xmlchange CLM_FORCE_COLDSTART=off

./preview_namelists
./case.build

# Submit case
#./case.submit




