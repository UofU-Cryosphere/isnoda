#!/usr/bin/env python

import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from mpl_toolkits.axes_grid1 import make_axes_locatable
from palettable.colorbrewer.diverging import RdBu_5 as RedBlueCmap

from raster_file import RasterFile

RED_BLUE_CMAP = RedBlueCmap.mpl_colormap
plt.rcParams.update(
    {
        'axes.labelsize': 10,
        'xtick.labelsize': 10,
        'ytick.labelsize': 10,
    }
)

# Values above 25m are considered outlier
OUTLIER = 25


def violin_plot(ax, data, color):
    vp = ax.violinplot(
        data,
        showmeans=False, showextrema=False, showmedians=True,
    )
    ax.set_xticks([])
    ax.axhline(0, c='black', ls=':')

    for pc in vp['bodies']:
        pc.set_facecolor(color)
        pc.set_edgecolor('black')

    vp['cmedians'].set_color('black')


def area_plot(file, title='', save=False):
    differences = RasterFile(file.as_posix())

    data = differences.band_values()
    data[data > OUTLIER] = np.ma.masked
    data[np.isnan(data)] = np.ma.masked

    fig, (ax1, ax2) = plt.subplots(
        1, 2, figsize=(11.5, 9),
        gridspec_kw={'width_ratios': [82, 18], 'wspace': 0.1},
        dpi=300,
    )
    fig.set_facecolor('lightgrey')
    ax1.set_facecolor('slategrey')

    plt_data = ax1.imshow(
        data,
        vmin=-2,
        vmax=2,
        cmap=RED_BLUE_CMAP
    )

    ax1.tick_params(
        axis='both', direction='inout', length=7, labelsize=9, pad=0
    )
    ax1.tick_params(axis='y', labelrotation=45)
    ax1.ticklabel_format(axis='both', style='plain')
    ax1.xaxis.set_ticks_position('both')
    ax1.yaxis.set_ticks_position('both')

    cax = make_axes_locatable(ax1).append_axes('right', size='5%', pad=0.15)
    fig.colorbar(
        plt_data,
        cax=cax,
        shrink=0.9,
        extend='both',
        label=r'$\Delta$ Depth (m)'
    )
    fig.suptitle(title, y=0.94)

    violin_plot(ax2, data.compressed(), 'orange')

    ax2.set_ylabel(None)
    ax2.set_ylim([-3, 4])
    ax2.tick_params(axis='y', labelsize=9)

    ax2.text(
        0.05, 0.01,
        f'Median: {np.median(data):.2f}',
        transform=ax2.transAxes,
        verticalalignment='bottom',
        bbox=dict(
            facecolor='whitesmoke',
            alpha=0.4,
            pad=.3,
            boxstyle='round'
        ),
    )

    if save:
        plt.savefig(file.with_suffix('.png'))
    else:
        plt.show()

    plt.clf()


def argument_parser():
    parser = argparse.ArgumentParser(
        description='Plot given GeoTIFF values as area with '
                    'violin distribution plot'
    )
    parser.add_argument(
        '--file', '-f',
        required=True,
        type=Path,
        help='Path to file'
    )
    parser.add_argument(
        '--title', '-t',
        required=True,
        type=str,
        help='Title for the plot'
    )
    parser.add_argument(
        '--save-figure', '-sf',
        required=False,
        action='store_true',
        help='Saves plot output to a given path- Optional'
    )

    return parser


if __name__ == '__main__':
    arguments = argument_parser().parse_args()

    print(f'Processing file: {arguments.file.as_posix()}')
    area_plot(arguments.file, arguments.title, arguments.save_figure)
