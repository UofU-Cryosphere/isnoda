import pandas as pd


class CsvParser:
    """
    Parses SNOTEL csv data downloaded from USDA with Pandas.
    Also converts units for depth and density to meters and kg/m^3.

    Requires the CSV columns in the following order:
    - Date
    - Snow Depth
    - SWE
    - Snow Density
    - Wind Speed
    - Temperature
    - Precipitation

    """
    DEPTH_COLUMN = 'Depth(m)'
    DENSITY_COLUMN = 'Density(kg/m3)'

    CSV_COLUMN_ORDER = [
        'Date',
        DEPTH_COLUMN,
        'SWE(mm)',
        DENSITY_COLUMN,
        'Wind(km/h)',
        'Air-T(C)',
        'Precipitation (mm)',
    ]

    PD_OPTIONS = dict(
        comment='#',
        parse_dates=True,
        index_col=0,
        names=CSV_COLUMN_ORDER,
        header=0,
    )

    @classmethod
    def file(cls, file):
        data = pd.read_csv(file, **CsvParser.PD_OPTIONS)
        data[cls.DEPTH_COLUMN] = data[cls.DEPTH_COLUMN] / 100
        data[cls.DENSITY_COLUMN] = data[cls.DENSITY_COLUMN] * 10

        return data
