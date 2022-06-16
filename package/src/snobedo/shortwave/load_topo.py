import numpy as np
from netCDF4 import Dataset
from topocalc import gradient
from utm import to_latlon


class Topo:
    """
    Copied elements from SMRF to feed into TopoLib shade calculation.

    See smrf.data.load_topo for the full version.
    """
    def __init__(self, topo_config):
        self.topoConfig = topo_config
        self.read_file()
        self.gradient()

    def read_file(self):
        with Dataset(self.topoConfig['filename']) as dem:
            self.dem = dem['dem'][:].astype(np.float64)

            self.x, self.y = np.meshgrid(
                dem.variables['x'][:],
                dem.variables['y'][:]
            )
            self.dx = np.mean(np.diff(self.x))
            self.dy = np.abs(np.diff(self.y, axis=0)).mean()

            self.x = np.ma.masked_array(self.x, dem.variables['mask'][:] == 0)
            self.y = np.ma.masked_array(self.y, dem.variables['mask'][:] == 0)

            # Lat, Lon for the center of the DEM
            self.lat, self.lon = to_latlon(
                self.x.mean(),
                self.y.mean(),
                int(dem.variables['projection'].utm_zone_number),
                northern=self.topoConfig['northern_hemisphere'],
            )

    def gradient(self):
        """
        Calculate the gradient and aspect
        """
        func = self.topoConfig['gradient_method']

        # calculate the gradient and aspect
        g, a = getattr(gradient, func)(
            self.dem, self.dx, self.dy, aspect_rad=True
        )

        # following IPW convention for slope as sin(Slope)
        self.sin_slope = np.sin(g)
        self.aspect = a
