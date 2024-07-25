#!/usr/bin/env python
"""This script generates PNG files from a list of NetCDF files created from daily iSnobal runs and creates a GIF from the PNG files."""

import xarray as xr
import argparse
import matplotlib.pyplot as plt
import numpy as np
import pathlib
import glob
import imageio

def parse_args():
    """
    Parse command line arguments.

    Returns:
        argparse.Namespace: Parsed arguments.
    """
    parser = argparse.ArgumentParser(description='Generate pngs from netcdf files')
    parser.add_argument('workdir', type=str, default="./", help='working directory')
    return parser.parse_args()

def fn_list(thisDir: str, fn_pattern: str, verbose=False) -> list:
    """
    Match and sort filenames based on a regex pattern in specified directory.

    Parameters:
        thisDir (str): Directory path to search.
        fn_pattern (str): Regex pattern to match files.
        verbose (bool): Print filenames.

    Returns:
        list: List of filenames matched and sorted.
    """
    fns=[]
    for f in glob.glob(thisDir + "/" + fn_pattern):
        fns.append(f)
    fns.sort()
    if verbose: print(fns)
    return fns

def generate_png(nc_list: list, workdir: str, dt: bool, bbox=False):
    """
    Generate PNG files from a list of NetCDF files, resampling to two hour means.

    Parameters:
        nc_list (list): List of NetCDF files.
        workdir (str): Working directory.
        bbox (bool): Flag to indicate whether to include bounding box in the saved image.

    Returns:
        None
    TODO: add date and location info to output png, no need if stored in the same dir of creation, but otherwise useful
    """
    for idx, nc_fn in enumerate(nc_list):
        if (idx == 4) | (idx == 9):
            pass
        else:
            ds = xr.open_dataset(nc_fn, chunks={})
            keyvar = list(ds.data_vars.keys())[0]
            h = ds[keyvar].resample(time='2h').reduce(np.mean).plot.imshow(col='time', 
                                                                        col_wrap=6,
                                                                        figsize=(18, 6)
                                                                        )
            plt.suptitle(f'{dt}: {ds[keyvar].attrs["long_name"]}\n[{ds[keyvar].attrs["units"]}]', y=1.1)

            for _, ax in enumerate(h.axs.flat):
                ax.set_aspect('equal')

            if bbox is False:
                plt.savefig(fname=f'{workdir}/{dt}_{keyvar}.png', dpi=300)
            else:
                plt.savefig(fname=f'{workdir}/{dt}_{keyvar}.png', dpi=300, bbox_inches='tight')
            plt.close()
            
def generate_gif(workdir: str, outgif_fn='test_outputs.gif'):
    """
    Generate a GIF from a list of PNG files in a directory.

    Parameters:
        workdir (str): Working directory.
        outgif_fn (str): Output GIF filename.

    Returns:
        None
    """
    images = []
    for png in fn_list(workdir, '*png'):
        images.append(imageio.v2.imread(png))
    imageio.mimsave(f'{workdir}/{outgif_fn}', images)

def main():
    """
    Main function to execute the script.
    """
    args = parse_args()
    workdir = args.workdir
    p = pathlib.Path(workdir)
    outname = p.resolve().name.split('run')[1]
    nc_list = fn_list(workdir, '*nc')
    generate_png(nc_list, workdir, outname)
    generate_gif(workdir, f'{outname}_isnobalout.gif')

if __name__ == "__main__":
    main()
