import numpy as np
from numba import njit, prange

ORIGINAL_RESOLUTION = 50
X_RESOLUTION_OFFSET = 39


@njit(cache=True, parallel=True)
def reduce_x(x_dim):
    mask_x = np.zeros(x_dim, dtype=np.byte)

    for x in prange(x_dim):
        if x % ORIGINAL_RESOLUTION == 0 or \
                ((x % ORIGINAL_RESOLUTION) % X_RESOLUTION_OFFSET == 0):
            mask_x[x] = 1
        else:
            mask_x[x] = 0

    return mask_x


@njit(cache=True, parallel=True)
def reduce_y(y_dim):
    mask_y = np.zeros(y_dim, dtype=np.byte)

    for y in prange(y_dim):
        if y % ORIGINAL_RESOLUTION == 0:
            mask_y[y] = 1
        else:
            mask_y[y] = 0

    return mask_y


@njit(cache=True, parallel=True)
def reduce_x_y(x, y):
    return np.nonzero(x & y)


def get_mask(y_dim, x_dim):
    mask_x = np.tile(reduce_x(x_dim), (y_dim, 1))
    mask_y = np.tile(reduce_y(y_dim), (x_dim, 1)).T

    return reduce_x_y(mask_x, mask_y)
