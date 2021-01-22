from common import *
from dask_cluster import start_cluster
from snotel_sites import SNOTEL

start_cluster(4, 8)

home = PurePath(f'{Path.home()}/shared-cyrosphere/')
year = 'wy2019'
snobal = home / 'iSnobal/output' / year / 'initial_run/data'
files_snobal = 'data20190[3-7]*/smrfOutputs/albedo_*.nc'

# Select MST 11 AM; time of MODIS overpass
albedo_snobal = xr.open_mfdataset(
    snobal.joinpath(files_snobal).as_posix(),
    parallel=True,
).sel(time=datetime.time(18))

albedo_snobal = albedo_snobal.sel(
    x=[SNOTEL['Irwin']['lon']],
    y=[SNOTEL['Irwin']['lat']],
    method='nearest',
)
comp = dict(zlib=True, complevel=5)
encoding = {var: comp for var in albedo_snobal.data_vars}

albedo_snobal.to_netcdf(
    home.joinpath('iSnobal/albedo', f"ERW_{year}_Irwin.nc").as_posix(),
    encoding=encoding,
    compute=True,
)

