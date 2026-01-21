# ===============================================
# instructions for setting up default basecases for calLMIP PLUMBER sites
# Basecases start from an initial spun up state with default parameter set. 
# We modify the paramfile then perform additional spinup, 1850-tower start year, tower years

# ===============================================
# create basecases for DK-Sor
# ===============================================
work='/glade/work/linnia/'
tag='ctsm5.4.004'

casedir='/glade/work/linnia/calLMIP/base_cases/'
user_mods_dir=/glade/work/linnia/calLMIP/usermods_dirs/
site='DK-Sor'
export PROJECT=P93300041
chargenum=P93300041

module load conda
conda activate ctsm_pylib

AD_casename='ctsm54004_bgc_'${site}'_AD'
postAD_casename='ctsm54004_bgc_'${site}'_postAD'
pretower_casename='ctsm54004_bgc_'${site}'_pretower'
tower_casename='ctsm54004_bgc_'${site}'_tower'

# ===============================================
# setup AD spinup (accelerated decomposition)
# ===============================================

cd ${work}${tag}/cime/scripts/

./create_newcase --case ${casedir}${AD_casename} --res CLM_USRDAT --compset 1850_DATM%1PT_CLM60%BGC_SICE_SOCN_SROF_SGLC_SWAV_SESP --project ${chargenum} --run-unsupported --user-mods-dirs ${user_mods_dir}${site}

cd ${casedir}${AD_casename}
./case.setup --reset

# user_nl_clm mods
echo "reseed_dead_plants = .true." >> user_nl_clm
echo "clm_start_type = 'startup'" >> user_nl_clm
echo "finidat='/glade/work/linnia/calLMIP/initial_conditions/ctsm54004_bgc_DK-Sor_postAD_spin_timefix.clm2.r.0481-01-01-82800.nc'" >> user_nl_clm

# env_run.xml
./xmlchange STOP_N=180
./xmlchange CLM_ACCELERATED_SPINUP=on
./xmlchange CLM_FORCE_COLDSTART=off

./xmlchange JOB_WALLCLOCK_TIME=06:00:00
./xmlchange JOB_QUEUE=develop
./xmlchange JOB_PRIORITY=regular

./preview_namelists
./case.build

# ===============================================
# setup postAD spinup 
# ==============================================

cd ${work}${tag}/cime/scripts/

./create_newcase --case ${casedir}${postAD_casename} --res CLM_USRDAT --compset 1850_DATM%1PT_CLM60%BGC_SICE_SOCN_SROF_SGLC_SWAV_SESP --project ${chargenum} --run-unsupported --user-mods-dirs ${user_mods_dir}${site}

cd ${casedir}${postAD_casename}
./case.setup --reset

# user_nl_clm mods
echo "reseed_dead_plants = .false." >> user_nl_clm
echo "clm_start_type = 'startup'" >> user_nl_clm

./xmlchange STOP_N=240 
./xmlchange CLM_ACCELERATED_SPINUP=off
./xmlchange CLM_FORCE_COLDSTART=off

./xmlchange JOB_WALLCLOCK_TIME=06:00:00
./xmlchange JOB_QUEUE=develop
./xmlchange JOB_PRIORITY=regular

./preview_namelists
./case.build

# ===============================================
# create transient pre-tower case (1850-1997)
# ===============================================
#: <<'END_COMMENT'
cd ${work}${tag}/cime/scripts/

./create_newcase --case ${casedir}${pretower_casename} --res CLM_USRDAT --compset HIST_DATM%1PT_CLM60%BGC_SICE_SOCN_SROF_SGLC_SWAV_SESP --project ${chargenum} --run-unsupported --user-mods-dirs ${user_mods_dir}${site}

cd ${casedir}${pretower_casename}
./case.setup --reset

echo "reseed_dead_plants = .false." >> user_nl_clm
echo "clm_start_type='startup'" >> user_nl_clm
echo "use_init_interp = .true." >> user_nl_clm
finidat_casename='ctsm54004_bgc_DK-Sor_postAD_spin2'
finidat=$(ls ${SCRATCH}/archive/${finidat_casename}'/rest/0'*'/'*".clm2.r."*".nc" | tail -n 1)
#finidat=$(ls ${SCRATCH}/${pSASU_casename}'/run/'${pSASU_casename}".clm2.r."*".nc" | tail -n 1)
finidat=$(echo $finidat) #expands wildcard
echo "finidat = '$finidat'" >> user_nl_clm
echo " " >> user_nl_clm
echo "CLM_USRDAT.PLUMBER2:taxmode=cycle" >> user_nl_datm_streams
echo "CLM_USRDAT.PLUMBER2:dtlimit=1e30" >> user_nl_datm_streams

echo "presaero.SSP3-7.0:year_first=1850" >> user_nl_datm_streams 
echo "presaero.SSP3-7.0:year_last=2014" >> user_nl_datm_streams 
echo "presaero.SSP3-7.0:year_align=1850" >> user_nl_datm_streams 
echo "presaero.SSP3-7.0:taxmode = extend" >> user_nl_datm_streams

echo "presndep.SSP3-7.0:year_first=1850" >> user_nl_datm_streams 
echo "presndep.SSP3-7.0:year_last=2014" >> user_nl_datm_streams 
echo "presndep.SSP3-7.0:year_align=1850" >> user_nl_datm_streams 
echo "presndep.SSP3-7.0:taxmode = extend" >> user_nl_datm_streams

echo "co2tseries.SSP3-7.0:year_first=1850" >> user_nl_datm_streams 
echo "co2tseries.SSP3-7.0:year_last=2014" >> user_nl_datm_streams 
echo "co2tseries.SSP3-7.0:year_align=1850" >> user_nl_datm_streams 
echo "co2tseries.SSP3-7.0:taxmode = extend" >> user_nl_datm_streams

echo "stream_fldfilename_ndep = '/glade/campaign/cesm/cesmdata/inputdata/lnd/clm2/ndepdata/fndep_clm_SSP370_b.e21.BWSSP370cmip6.f09_g17.CMIP6-SSP3-7.0-WACCM.002_1849-2101_monthly_0.9x1.25_c211216.nc'" >> user_nl_clm
echo "model_year_align_ndep = 1850" >> user_nl_clm
echo "stream_year_first_ndep = 1850" >> user_nl_clm
echo "stream_year_last_ndep = 2025" >> user_nl_clm
echo "ndep_taxmode='extend'" >> user_nl_clm

# env_run.xml
# in usermods_dir/default do: 
#./xmlchange CLM_NML_USE_CASE="2018-PD_transient" # default is 20thC_transient
./xmlchange CLM_FORCE_COLDSTART=off

./xmlchange RUN_STARTDATE=1850-01-01
./xmlchange STOP_OPTION=nyears
./xmlchange STOP_N=148
./xmlchange CLM_ACCELERATED_SPINUP=off
./xmlchange DATM_YR_ALIGN=1850
./xmlchange DATM_YR_START=1997
./xmlchange DATM_YR_END=2014
./xmlchange CALENDAR=NO_LEAP
./xmlchange PIO_REARRANGER_LND=2
./xmlchange DOUT_S=FALSE

./xmlchange DATM_PRESAERO=SSP3-7.0
./xmlchange DATM_CO2_TSERIES=SSP3-7.0
./xmlchange DATM_PRESNDEP=SSP3-7.0

./xmlchange JOB_WALLCLOCK_TIME=06:00:00
#./xmlchange JOB_QUEUE=main  
#./xmlchange JOB_PRIORITY=regular

./preview_namelists
./case.build

# ./case.submit


# ===============================================
# create tower case (DK-Sor 1997-2014)
# ===============================================

cd ${work}${tag}/cime/scripts/

./create_newcase --case ${casedir}${tower_casename} --res CLM_USRDAT --compset HIST_DATM%1PT_CLM60%BGC_SICE_SOCN_SROF_SGLC_SWAV_SESP --project ${chargenum} --run-unsupported --user-mods-dirs ${user_mods_dir}${site}

cd ${casedir}${tower_casename}
./case.setup --reset

finidat='/glade/derecho/scratch/linnia/ctsm53085_bgc_USMMS_transient/run/ctsm53085_bgc_USMMS_transient.clm2.r.2000-01-01-00000.nc'
echo "finidat = '$finidat'" >> user_nl_clm

#? ./xmlchange CLM_NML_USE_CASE="2018-PD_transient" 
#./xmlchange RUN_STARTDATE=1996-12-31

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
#END_COMMENT

