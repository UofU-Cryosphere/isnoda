import numpy as np
from topocalc.shade import shade

from snobedo.data import WriteNC
from snobedo.shortwave.load_topo import Topo
from snobedo.shortwave.sunang import sunang


class TopoShade:
    def __init__(self, topo_file_path):
        self._illumination_angels = {}
        self._topo_file = topo_file_path

    @property
    def illumination_angles(self):
        return self._illumination_angels

    @property
    def topo_file(self):
        return self._topo_file

    def calculate(self, time_range):
        topo = Topo({
            'filename': self._topo_file,
            'northern_hemisphere': True,
            'gradient_method': 'gradient_d8'
        })

        for timestep in time_range:
            timestep = timestep
            cosz, azimuth, rad_vec = sunang(
                timestep,
                topo.lat,
                topo.long
            )

            if cosz > 0:
                illumination_angle = shade(
                    topo.sin_slope,
                    topo.aspect,
                    azimuth,
                    cosz
                )
            else:
                illumination_angle = np.zeros(topo.x.shape)

            self.illumination_angles[timestep] = illumination_angle

    def save_illumination_angles(self, out_file_path):
        time_range = list(self.illumination_angles.keys())

        with WriteNC.for_topo(out_file_path, self.topo_file) as outfile:
            field = outfile.createVariable(
                'illumination_angle', 'f8', ('time', 'y', 'x',), zlib=True
            )
            field.setncattr('long_name', 'Local illumination angle')
            field.setncattr(
                'description',
                'Cosine of the local illumination angle over a DEM'
            )
            field.setncattr(
                'units', '1: no illumination; 0: full illumination'
            )

            counter = 0

            for key in time_range:
                outfile['time'][counter] = WriteNC.date_to_number(
                    key, outfile, counter == 0
                )
                field[counter, :, :] = self.illumination_angles[key]
                counter += 1
