"""
Collection of convenience functions and to DRY out command line scripts.
"""


def add_dask_options(parser):
    """
    Adds 'cores' and 'memory' option to a argparse parser. Defaults the value
    to 4 cores and 8 memory.

    :param parser: ArgumentParser object

    :return: parser with added options.
    """
    parser.add_argument(
        '--cores',
        type=int,
        default=4,
        help='Number of CPU cores to use for parallelization. Default: 4'
    )
    parser.add_argument(
        '--memory',
        type=int,
        default=8,
        help='Amount of memory to allocate for parallelization: Default: 8 GB'
    )

    return parser


def add_water_year_option(parser):
    """
    Add a '--water-year' option to a argparse parser.

    :param parser: ArgumentParser object

    :return: parser with added options.
    """
    parser.add_argument(
        '--water-year',
        required=True,
        type=int,
        help='Water year. Determines the date range to process'
    )

    return parser
