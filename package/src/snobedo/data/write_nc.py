from contextlib import contextmanager
from datetime import timezone

import netCDF4
from spatialnc.proj import add_proj, add_proj_from_file


class WriteNC:
    VARIABLE_X = 'x'
    VARIABLE_Y = 'y'
    VARIABLE_TIME = 'time'

    @staticmethod
    @contextmanager
    def for_topo(output_path, topo_file):
        """
        Prepare a new NetCDF file for given input file with topographic data.
        Adds a dimension for time, x, y, and projection info.

        Yields the created file to the calling block

        Example:
            with WriteNC.for_topo('out.nc', topo.nc') as file:
                file.createVariable(...)

        Arguments:
        :arg output_path: String - Full file path to save
        :arg topo_file: NetCDF file with topographic information
        """

        with netCDF4.Dataset(output_path, 'w') as outfile:
            with netCDF4.Dataset(topo_file) as topo:
                outfile.createDimension(
                    WriteNC.VARIABLE_X,
                    topo.variables[WriteNC.VARIABLE_X].size
                )
                x = outfile.createVariable(
                    WriteNC.VARIABLE_X, 'f4', (WriteNC.VARIABLE_X,)
                )
                x.setncattr('units', 'meters')
                x.setncattr('description', 'UTM, east west')
                x.setncattr('long_name', 'x coordinate')

                outfile.createDimension(
                    WriteNC.VARIABLE_Y,
                    topo.variables[WriteNC.VARIABLE_Y].size
                )
                y = outfile.createVariable(
                    WriteNC.VARIABLE_Y, 'f4', (WriteNC.VARIABLE_Y,)
                )
                y.setncattr('units', 'meters')
                y.setncattr('description', 'UTM, north south')
                y.setncattr('long_name', 'y coordinate')

                x[:] = topo.variables[WriteNC.VARIABLE_X][:]
                y[:] = topo.variables[WriteNC.VARIABLE_Y][:]

            outfile.createDimension(WriteNC.VARIABLE_TIME)
            time = outfile.createVariable(
                WriteNC.VARIABLE_TIME, 'f8', (WriteNC.VARIABLE_TIME,)
            )
            time.setncattr('calendar', 'standard')
            time.setncattr('time_zone', str(timezone.utc))
            time.setncattr('long_name', WriteNC.VARIABLE_TIME)

            yield outfile

            add_proj(outfile, map_meta=add_proj_from_file(topo_file))

    @staticmethod
    def date_to_number(date, outfile, add_units=False):
        if add_units:
            outfile[WriteNC.VARIABLE_TIME].setncattr(
                'units',
                'hours since {}'.format(str(date))
            )

        return netCDF4.date2num(
            date,
            outfile[WriteNC.VARIABLE_TIME].units,
            outfile[WriteNC.VARIABLE_TIME].calendar
        )
