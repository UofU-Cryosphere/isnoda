import datetime


def day_filter(dataset):
    """
    There is an issue with AWSM (#55 on GitHub), where there is an extra
    hour in SMRF outputs. This filter removes the additional hour of the day.

    :param dataset: XArray dataset

    :return:
        Xarray dataset with `sel` filter applied
    """
    return dataset.sel(time=dataset.time[0].dt.strftime('%Y-%m-%d').values)


def hour_filter(dataset):
    """
    iSnobal sometimes has an additional hour in their snow.nc outputs, aside
    from the expected end of day value. This filter ensure the datasets are
    only reading the last hour of the day value and ignore others.

    :param dataset: XArray dataset

    :return:
        Xarray dataset with `sel` filter applied
    """
    return dataset.sel(time=datetime.time(23))
