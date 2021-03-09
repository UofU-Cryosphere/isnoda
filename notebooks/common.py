import datetime
import numpy as np
import pandas as pd
import xarray as xr

import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import matplotlib.patches as mpatches
import matplotlib.font_manager as font_manager

from pathlib import Path, PurePath

from snobedo.lib.dask_utils import start_cluster

plt.rcParams.update(
    {
        'axes.labelsize': 10
    }
)

LEGEND_TEXT = "{0:10} {1:8}"
LEGEND_DATE = "%Y-%m-%d"

def legend_text(label, value, color='none'):
    return mpatches.Patch(
        color=color, label=LEGEND_TEXT.format(label, value)
    )

def add_legend_box(ax, entries):
    ax.legend(
        handles=entries,
        loc='upper right',
        prop=font_manager.FontProperties(
            family='monospace', style='normal', size=8
        ),
    )
