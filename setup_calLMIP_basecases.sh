# ===============================================
# instructions for setting up default basecases for calLMIP PLUMBER sites
# Basecases start from an initial spun up state with default parameter set. 
# We modify the paramfile then perform additional spinup, 1850-tower start year, tower years
# (just instructions, this is not meant to be executed)

# ===============================================
# check out codebase
# ===============================================
work='/glade/work/linnia/'
tag='ctsm5.4.004'

# ===============================================
# create spin up base cases for DK-Sor
# ===============================================

casedir='/glade/work/linnia/calLMIP/basecases/'
user_mods_dir=/glade/work/linnia/calLMIP/usermods_dirs/
site='DK-Sor'
export PROJECT=P93300041
chargenum=P93300041

module load conda
conda activate ctsm_pylib

# ===============================================
# setup AD spinup (accelerated decomposition)
# ===============================================

AD_casename='ctsm54004_bgc_'${site}'_AD_basecase'

cd ${work}${tag}/cime/scripts/

./create_newcase --case ${casedir}${AD_casename} --res CLM_USRDAT --compset 1850_DATM%1PT_CLM60%BGC_SICE_SOCN_SROF_SGLC_SWAV_SESP --project ${chargenum} --run-unsupported --user-mods-dirs ${user_mods_dir}${site}

cd ${casedir}${AD_casename}
./case.setup --reset

# user_nl_clm mods
echo "reseed_dead_plants = .true." >> user_nl_clm

# env_run.xml
./xmlchange STOP_N=180
./xmlchange CLM_ACCELERATED_SPINUP=on
./xmlchange CLM_FORCE_COLDSTART=off

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

SASU_casename='ctsm54004_bgc_'${site}'_SASU_basecase'

cd ${work}${tag}/cime/scripts/

./create_clone --case ${casedir}${SASU_casename} --clone ${casedir}${AD_casename} --project ${chargenum}

cd ${casedir}${SASU_casename}
./case.setup --reset

# user_nl_clm mods
echo "reseed_dead_plants = .false." >> user_nl_clm
echo "clm_start_type='startup'" >> user_nl_clm
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

pSASU_casename='ctsm54004_bgc_'${site}'_pSASU_basecase'

cd ${work}${tag}/cime/scripts/

./create_clone --case ${casedir}${pSASU_casename} --clone ${casedir}${AD_casename} --project ${chargenum}

cd ${casedir}${pSASU_casename}
./case.setup --reset

# user_nl_clm mods
echo "reseed_dead_plants = .false." >> user_nl_clm
echo "clm_start_type='startup'" >> user_nl_clm
finidat=$(ls ${SCRATCH}/${SASU_casename}'/run/'${SASU_casename}".clm2.r."*".nc" | tail -n 1)
finidat=$(echo $finidat) #expands wildcard
echo "finidat = '$finidat'" >> user_nl_clm

./xmlchange STOP_N=120 
./xmlchange CLM_ACCELERATED_SPINUP=off
./xmlchange CLM_FORCE_COLDSTART=off

./preview_namelists
./case.build

# Submit case
#./case.submit

# ===============================================
# create transient pre-tower case (1850-1997)
# ===============================================

casename='ctsm54004_bgc_'${site}'_pretower_basecase'

cd ${work}${tag}/cime/scripts/

./create_newcase --case ${casedir}${casename} --res CLM_USRDAT --compset HIST_DATM%1PT_CLM60%BGC_SICE_SOCN_SROF_SGLC_SWAV_SESP --project ${chargenum} --run-unsupported --user-mods-dirs ${user_mods_dir}${site}

cd ${casedir}${casename}

echo "reseed_dead_plants = .false." >> user_nl_clm
echo "clm_start_type='startup'" >> user_nl_clm
finidat=$(ls ${SCRATCH}/${pSASU_casename}'/run/'${pSASU_casename}".clm2.r."*".nc" | tail -n 1)
finidat=$(echo $finidat) #expands wildcard
echo "finidat = '$finidat'" >> user_nl_clm

echo "presaero.SSP3-7.0:year_first=1850" >> user_nl_datm_streams 
echo "presaero.SSP3-7.0:year_last=2014" >> user_nl_datm_streams 
echo "presaero.SSP3-7.0:year_align=1850" >> user_nl_datm_streams 

echo "presndep.SSP3-7.0:year_first=1850" >> user_nl_datm_streams 
echo "presndep.SSP3-7.0:year_last=2014" >> user_nl_datm_streams 
echo "presndep.SSP3-7.0:year_align=1850" >> user_nl_datm_streams 

echo "co2tseries.SSP3-7.0:year_first=1850" >> user_nl_datm_streams 
echo "co2tseries.SSP3-7.0:year_last=2014" >> user_nl_datm_streams 
echo "co2tseries.SSP3-7.0:year_align=1850" >> user_nl_datm_streams 

#? ./xmlchange CLM_NML_USE_CASE="2018-PD_transient"

# env_run.xml
./xmlchange RUN_STARTDATE=1850-01-01
./xmlchange STOP_OPTION=nyears
./xmlchange STOP_N=99
./xmlchange CLM_ACCELERATED_SPINUP=off
./xmlchange DATM_YR_ALIGN=1
./xmlchange DATM_YR_START=1901
./xmlchange DATM_YR_END=2023
./xmlchange PIO_REARRANGER_LND=2
./xmlchange DOUT_S=FALSE

./xmlchange DATM_PRESAERO=SSP3-7.0
./xmlchange DATM_CO2_TSERIES=SSP3-7.0
./xmlchange DATM_PRESNDEP=SSP3-7.0

./case.setup
./preview_namelists
./case.build

./xmlchange JOB_WALLCLOCK_TIME=06:00:00
#./xmlchange JOB_QUEUE=main  
#./xmlchange JOB_PRIORITY=regular

# ./case.submit


# ===============================================
# create tower case (DK-Sor 1997-2014)
# ===============================================

casename='/glade/work/linnia/calLMIP/US-MMS/cases/ctsm53085_bgc_USMMS_tower'

cd ${work}${tag}/cime/scripts/

./create_newcase --case ${casename} --res CLM_USRDAT --compset HIST_DATM%CRUJRA2024_CLM60%BGC_SICE_SOCN_SROF_SGLC_SWAV_SESP --project ${chargenum} --run-unsupported --user-mods-dirs ${user_mods_dir}user_mods/

cd ${casename}

finidat='/glade/derecho/scratch/linnia/ctsm53085_bgc_USMMS_transient/run/ctsm53085_bgc_USMMS_transient.clm2.r.2000-01-01-00000.nc'
echo "finidat = '$finidat'" >> user_nl_clm

echo "flanduse_timeseries = ''" >> user_nl_clm
echo "reseed_dead_plants = .false." >> user_nl_clm

echo "presaero.SSP3-7.0:year_first=1997" >> user_nl_datm_streams 
echo "presaero.SSP3-7.0:year_last=2014" >> user_nl_datm_streams 
echo "presaero.SSP3-7.0:year_align=1997" >> user_nl_datm_streams 

echo "presndep.SSP3-7.0:year_first=1997" >> user_nl_datm_streams 
echo "presndep.SSP3-7.0:year_last=2014" >> user_nl_datm_streams 
echo "presndep.SSP3-7.0:year_align=1997" >> user_nl_datm_streams 

echo "co2tseries.SSP3-7.0:year_first=1997" >> user_nl_datm_streams 
echo "co2tseries.SSP3-7.0:year_last=2014" >> user_nl_datm_streams 
echo "co2tseries.SSP3-7.0:year_align=1997" >> user_nl_datm_streams 

# env_run.xml
./xmlchange RUN_STARTDATE=2000-01-01
./xmlchange STOP_OPTION=nyears
./xmlchange STOP_N=23
./xmlchange PIO_REARRANGER_LND=2
./xmlchange DOUT_S=FALSE

./case.setup
./preview_namelists
./case.build

./xmlchange JOB_WALLCLOCK_TIME=06:00:00
#./xmlchange JOB_QUEUE=develop 
#./xmlchange JOB_PRIORITY=regular

# ./case.submit



