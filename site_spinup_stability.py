# script to evaluate spin up stability for calLMIP PLUMBER sites
# script assumes input directory has annual variables in .h0a. streams
# Linnia Hawkins 1/13/2026 lh3194@columbia.edu
# Usage: python script.py <input_dir> <nyears>"

import xarray as xr
import numpy as np
import glob, sys, os

def calc_drift(da,nyears):
    # only use for carbon pool variables (e.g., TOTECOSYSC, TOTVEGC, TOTSOMC)
    dx=(da - da.shift(time=nyears)).squeeze()
    drift = dx.isel(time=slice(-nyears, None)).mean(dim='time')/nyears
    return drift

def preprocess(ds):
    dvs = ['TOTECOSYSC','TOTVEGC','TOTSOMC']
    return ds[dvs]

def load_spinup(in_dir,preprocess=None):
    
    all_files = sorted(glob.glob(os.path.join(in_dir, '*.h0a.*')))

    ds = xr.open_mfdataset(
        all_files,
        combine='nested',
        concat_dim=['time'],
        preprocess=preprocess,
        decode_times=True,
        combine_attrs='override',
        parallel=True,
    )
    return ds

def main():
    if len(sys.argv) < 3:
        print("Usage: python script.py <input_dir> <nyears>")
        sys.exit(1)
        
    in_dir = sys.argv[1] #e.g., '/glade/derecho/scratch/linnia/archive/ctsm54004_bgc_DK-Sor_pSASU_test22/lnd/hist'
    nyears = int(sys.argv[2]) # e.g., 16
    ds = load_spinup(in_dir,preprocess=preprocess)

    drift_ds = calc_drift(ds, nyears).compute()

    print(f'--- Drift in last met cycle ({nyears} years) (gC/m2/year) ---')
    print('TOTECOSYSC=',drift_ds.TOTECOSYSC.values)
    print('TOTSOMC=',drift_ds.TOTSOMC.values)
    print('TOTVEGC=',drift_ds.TOTVEGC.values)

if __name__ == '__main__':
    main()