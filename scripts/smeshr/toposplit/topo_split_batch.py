import sys

from topo_split import *

topo_file = '/uufs/chpc.utah.edu/common/home/uvu-group1/olson/snow-data/isnobal-data/ERW_topo.nc'

day = sys.argv[1]
date = day.split('.')[-1]
print(date)
ghi_stack, dsw1_stack, dsw2_stack, dsw3_stack, dsw3h_stack, k_stack, time_list = toposplit_for_day(
    topo_file, day
)
write_nc(
    ghi_stack, dsw1_stack, dsw2_stack, dsw3_stack, dsw3h_stack, k_stack, time_list,
    '/uufs/chpc.utah.edu/common/home/uvu-group1/olson/snow-data/hrrr_toposplit_new/toposplit_' + date + '.nc',
    topo_file,
)
