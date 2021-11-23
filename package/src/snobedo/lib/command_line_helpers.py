

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


def check_paths_presence(arguments, required_paths):
    """
    Verify that required paths given as command line arguments exist.
    The required paths variable names have to match to options from the
    command line. Will exit the program once one path is not found or missing.

    :param arguments: Paths given via command line arguments
    :param required_paths: List of required paths
    """
    for path_arg in required_paths:
        location = getattr(arguments, path_arg)
        if not location.exists():
            print(
                f'Given {path_arg.replace("_", "-")} argument: {location} '
                'does not exist.'
            )
            exit(-1)
