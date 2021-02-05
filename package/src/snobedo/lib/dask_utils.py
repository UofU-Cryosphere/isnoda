from contextlib import contextmanager
from pathlib import Path

from dask.distributed import Client

CHPC = 'chpc' in str(Path.home())


def start_cluster(cores=6, memory=None):
    if CHPC:
        from dask_jobqueue import SLURMCluster

        cluster = SLURMCluster(
            cores=cores,
            processes=cores,
            n_workers=1,
            project="notchpeak-shared-short",
            queue="notchpeak-shared-short",
            memory=f"{memory or cores}G",
            walltime="2:00:00",
        )
    else:
        # Assume local
        from dask.distributed import LocalCluster

        memory = memory / cores
        cluster = LocalCluster(n_workers=cores, memory_limit=f"{memory}G")

    return Client(cluster)


@contextmanager
def run_with_client(cores, memory):
    client = start_cluster(cores, memory)
    print(client.dashboard_link)
    try:
        yield client
    finally:
        client.shutdown()
