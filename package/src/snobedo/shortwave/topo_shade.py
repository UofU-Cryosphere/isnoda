import math

import numpy as np
from topocalc.shade import shade

from snobedo.data import WriteNC
from snobedo.shortwave.load_topo import Topo
from snobedo.shortwave.sunang import sunang


class TopoShade:
    def __init__(self, topo_file_path):
        self._illumination_angels = {}
        self._azimuth = {}
        self._zenith = {}
        self.topo = topo_file_path

    @property
    def azimuth(self):
        return self._azimuth

    @property
    def illumination_angles(self):
        return self._illumination_angels

    @property
    def zenith(self):
        return self._zenith

    @property
    def topo(self):
        return self._topo

    @topo.setter
    def topo(self, file_path):
        self._topo = Topo(file_path)

    def calculate(self, time_range):

        for timestep in time_range:
            timestep = timestep
            cosine_zenith, azimuth, rad_vec = sunang(
                timestep,
                self.topo.lat,
                self.topo.lon
            )

            if cosine_zenith > 0:
                illumination_angle = shade(
                    self.topo.sin_slope,
                    self.topo.aspect,
                    azimuth,
                    cosine_zenith
                )
            else:
                illumination_angle = np.zeros(self.topo.x.shape)
                azimuth = 0
                cosine_zenith = 1

            self.azimuth[timestep] = azimuth
            self.zenith[timestep] = math.degrees(math.acos(cosine_zenith))
            self.illumination_angles[timestep] = illumination_angle

    @staticmethod
    def add_illumination_angle(outfile):
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
        return field

    @staticmethod
    def add_time_variable(name, description, units, outfile):
        field = outfile.createVariable(name, 'f8', 'time', zlib=True)
        field.setncattr('long_name', description)
        field.setncattr('units', units)
        return field

    def save_illumination_angles(self, out_file_path):
        time_range = list(self.illumination_angles.keys())

        with WriteNC.for_topo(out_file_path, self.topo.topo_file) as outfile:
            illumination_field = self.add_illumination_angle(outfile)
            azimuth_field = self.add_time_variable(
                'azimuth', 'Solar azimuth angle; 0 -> South', 'degrees',
                outfile
            )
            zenith_field = self.add_time_variable(
                'zenith', 'Solar zenith angle; 90 -> Horizon', 'degrees',
                outfile
            )

            counter = 0

            for key in time_range:
                outfile['time'][counter] = WriteNC.date_to_number(
                    key, outfile, counter == 0
                )
                illumination_field[counter, :, :] = \
                    self.illumination_angles[key]
                azimuth_field[counter] = self.azimuth[key]
                zenith_field[counter] = self.zenith[key]
                counter += 1
