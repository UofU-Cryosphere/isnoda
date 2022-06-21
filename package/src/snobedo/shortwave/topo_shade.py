import math

import numpy as np
import pytz
from topocalc.shade import shade

from snobedo.data import WriteNC
from snobedo.shortwave.load_topo import Topo
from snobedo.shortwave.sunang import sunang
from snobedo.shortwave.sun_position import SunPosition


class TopoShade:
    class SolarMethods:
        SMRF = 'SMRF'
        SKYFIELD = 'skyfield'

    def __init__(self, topo_file_path, solar_method=SolarMethods.SKYFIELD):
        """
        Calculate topographic shading

        :param topo_file_path: Topo instance
        :param solar_method: Method to use for solar angles
                             Options:
                             * skyfield (default)
                             * SMRF
        """
        self._illumination_angels = {}
        self._azimuth = {}
        self._zenith = {}
        self.topo = topo_file_path
        self._solar_method = solar_method

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
        if self._solar_method == self.SolarMethods.SKYFIELD:
            self.solar_skyfield(time_range)
        elif self._solar_method == self.SolarMethods.SMRF:
            self.solar_smrf(time_range)

    def solar_skyfield(self, time_range):
        sun_position = SunPosition(
            self.topo.lat, self.topo.lon, self.topo.dem.mean(),
        )

        sun_angles = sun_position.for_day(time_range[0])

        for timestep, (zenith, azimuth) in sun_angles.items():
            # Convert to TopoLib expected values:
            # * Cosine for zenith
            # * Azimuth with 0 pointing to the South
            if zenith is not None:
                zenith = math.cos(math.radians(90 - zenith.degrees))
                if azimuth.degrees > 180:
                    azimuth = -(azimuth.degrees % 180)
                else:
                    azimuth = 180 - azimuth.degrees

                illumination_angle = shade(
                    self.topo.sin_slope,
                    self.topo.aspect,
                    azimuth,
                    zenith
                )
            else:
                illumination_angle = 0
                azimuth = -181
                zenith = 0

            self.azimuth[timestep] = azimuth
            self.zenith[timestep] = math.degrees(math.acos(zenith))
            self.illumination_angles[timestep] = illumination_angle

    def solar_smrf(self, time_range):
        for timestep in time_range:
            timestep = timestep.astimezone(pytz.UTC)
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
                azimuth = -181
                cosine_zenith = 1

            self.azimuth[timestep] = azimuth
            self.zenith[timestep] = math.degrees(math.acos(cosine_zenith))
            self.illumination_angles[timestep] = illumination_angle

    @staticmethod
    def add_illumination_angle(outfile):
        field = outfile.createVariable(
            'illumination_angle', 'f', ('time', 'y', 'x',), zlib=True
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
        field = outfile.createVariable(name, 'f', 'time', zlib=True)
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
