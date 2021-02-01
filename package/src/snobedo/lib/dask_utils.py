from contextlib import contextmanager
from pathlib import Path

# Dask workaround for Python 3.9; https://github.com/dask/distributed/pull/4460
import multiprocessing.popen_spawn_posix  # noqa: F401
from dask.distributed import Client

CHPC = 'chpc' in str(Path.home())


def start_cluster(cores=6, memory=None):
    if CHPC:
        from dask_jobqueue import SLURMCluster

        cluster = SLURMCluster(
            cores=cores,
            processes=cores,
            project="notchpeak-shared-short",
            queue="notchpeak-shared-short",
            memory=f"{memory or cores}g",
            walltime="2:00:00",
        )

        cluster.scale(1)
        client = Client(cluster)
    else:
        # Assume local
        from dask.distributed import LocalCluster

        memory = memory / cores
        cluster = LocalCluster(n_workers=cores, memory_limit=f"{memory}G")
        client = Client(cluster)

    return client


@contextmanager
def run_with_client(cores, memory):
    client = start_cluster(cores, memory)
    print(client.dashboard_link)
    try:
        yield client
    finally:
        client.shutdown()
