import datetime
from pathlib import Path, PurePath

from snobedo.lib.dask_utils import start_cluster

import matplotlib.dates as mdates
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import xarray as xr

plt.rcParams.update(
    {
        'axes.labelsize': 10
    }
)
