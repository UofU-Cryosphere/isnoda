from dask.distributed import Client
from pathlib import Path


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

        cluster = LocalCluster(memory_limit='1.5GB')
        client = Client(cluster)

    # print(cluster.job_script())
    return client

