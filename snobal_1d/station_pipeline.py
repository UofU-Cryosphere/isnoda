import MesoPy
import json
import pandas as pd
import numpy as np
import math
import plotly.express as px
from plotly.subplots import make_subplots
import plotly.graph_objects as go
import chart_studio.plotly as py

# only needed if intending to pull station data again.
from MesoPy import Meso
m = Meso(token='YOUR TOKEN HERE')

# constants
SB_CONST = 5.67e-8


def html_chart(df, height=1200):
    """
    make interactive chart.

    param df: inpute dataframe
    param height: optional plot height
    returns: plotly chart
    """
    fig = make_subplots(rows=(len(df.columns)),
                        cols=1,
                        subplot_titles=df.columns,
                        shared_xaxes=True,
                        vertical_spacing=0.007
                        )
    j = 1
    for i in df.columns:
        fig.add_trace(
            go.Scatter(
                {'x': df.index,
                 'y': df[i]}),
                 row=j, col=1)
        j += 1

    fig.update_layout(height=height, font_size=9)
    return fig

def vapor_pressure(df, dt):
    """
    Vapor pressure dervied from dewpoint temp. Formula from NWS:
    https://www.weather.gov/media/epz/wxcalc/vaporPressure.pdf

    :param df: dataframe with dewpoint temp
    :param dt: column with dewpoint temp (in Deg C).
    :return: vapor pressure col in dataframe (output is in Pa).
    """
    df['vp'] = 6.11 * (10 ** ((7.5 * df[dt]) / (237.3 + df[dt])))
    # hPa to Pa
    df['vp'] = df['vp'] * 100
    return df

def longwave_est_2(RH_col, sw_net, air_t_col_K):
    """
    Updated longwave estimation from Immerzeel et al. 2019. Currently implemented
    with list comprehension is Irwin_pipeline.ipynb, because I had issues getting
    multiple df args to work w/ a lambda function.

    :param RH_col: col with RH
    :param sw_net: col with net shortwave, in W/M^2
    :param air_t_col_K: col with
    :return: list populated with estimated longwave.
    """
    clear = {'c1': -75.28,
             'c2': 0.82,
             'c3': 0.79}

    cloudy = {'c1': -212.59,
              'c2': 1.89,
              'c3': 1.06}

    lw_in_est = []

    # night branch
    if sw_net < 10.0:
        if RH_col < 80:
            # clear branch
            x = clear['c1'] + clear['c2'] * RH_col + clear['c3'] * SB_CONST * air_t_col_K ** 4
            lw_in_est.append(x)
        elif RH_col >= 80:
            # cloudy branch
            x = cloudy['c1'] + cloudy['c2'] * RH_col + cloudy['c3'] * SB_CONST * air_t_col_K ** 4
            lw_in_est.append(x)
    # day branch
    elif sw_net >= 10:
        if RH_col < 60:
            # clear branch
            x = clear['c1'] + clear['c2'] * RH_col + clear['c3'] * SB_CONST * air_t_col_K ** 4
            lw_in_est.append(x)
        elif RH_col >= 60:
            # cloudy branch
            x = cloudy['c1'] + cloudy['c2'] * RH_col + cloudy['c3'] * SB_CONST * air_t_col_K ** 4
            lw_in_est.append(x)

    return lw_in_est


def estimate_lw(df, lw_col, temp_col, threshold):
    """
    Simplified (collapsed) longwave parameterization from Skiles et al. 2012.

    :param df: dataframe with input data
    :param lw_col: column with incoming longwave radiation
    :param threshold: theshold incoming longwave (in w/m^2) below which the correction is applied. We assume snow is occluding
                      the sensor when it is below this theshold.
    :param precip_col: column with binned precipitation data.
    :return: estimate of lw_in during precip, based on air t, in new col "incoming_radiation_lw_corr".
    """
    # create new col for corrected data
    df['incoming_radiation_lw_corr'] = np.nan
    # convert air temp from C to K
    df['air_temp_K'] = df[temp_col].apply(lambda x: x + 273.15)
    df.loc[(df[lw_col] < threshold) & (df['fraction'] != 0), 'incoming_radiation_lw_corr'] = 0.963*SB_CONST*df['air_temp_K']**4
    return df


def replace_sw_in(df, default_sw_in, alt_sw_in, precip_col):
    """replace sw_in at Atwater with sw_in from Reynolds peak when Atwater radiometer is occluded."""
    df.loc[(df[default_sw_in] < df[alt_sw_in]) & (df[precip_col] != 0), 'corr_sw_in'] = df[alt_sw_in]
    return df

def snow_density_fraction(df, air_t_col):
    """
    Estimate density and fraction of snow based on air temp. Translated from IDL code
    written by TH Painter, and provided by S Skiles.

    :param df: pandas df to pull temp col from
    :param air_t_col: air temp col (in deg C)
    :return: df with new cols "fraction" and "density"
    """
    df['fraction'] = df[air_t_col].copy()
    df['density'] = df[air_t_col].copy()

    def transform_fraction(x):
            if x > 0.5:
                x = 0.00
                return x

            elif x < -5.0:
                x = 1.00
                return x

            elif x > -5.0 and x < -3.0:
                x = 1.00
                return x

            elif x > -3.0 and x < -1.0:
                x = 1.00
                return x
            elif x > -1.0 and x < -0.5:
                x = 1.00
                return x

            elif x > -0.5 and x < 0.0:
                x = 0.75
                return x

            elif x > 0.0 and x < 0.5:
                x = 0.25
                return x

    def transform_density(x):
            if x > 0.5:
                x = 0.00
                return x

            elif x < -5.0:
                x = 75.00
                return x

            elif x > -5.0 and x < -3.0:
                x = 100.000
                return x

            elif x > -3.0 and x < -1.0:
                x = 150.000
                return x

            elif x > -1.0 and x < -0.5:
                x = 175.000
                return x

            elif x > -0.5 and x < 0.0:
                x = 200.000
                return x

            elif x > 0.0 and x < 0.5:
                x = 250.000
                return x

    # apply to df
    df['fraction'] = df['fraction'].apply(lambda x: transform_fraction(x))
    df['density'] = df['density'].apply(lambda x: transform_density(x))

    return df


def get_dew_point_c(t_air_c, rel_humidity):
    """
    calculate the dew point in degrees Celsius, based on temp and RH

    :param t_air_c: current ambient temperature in degrees Celsius
    :type t_air_c: float
    :param rel_humidity: relative humidity in %
    :type rel_humidity: float
    :return: the dew point in degrees Celsius
    :rtype: float
    """
    A = 17.27
    B = 237.7
    alpha = ((A * t_air_c) / (B + t_air_c)) + math.log(rel_humidity/100.0)
    return (B * alpha) / (A - alpha)


def pull_atwater():
    """
    Uses Synoptic labs API to query MesoWest database for atwater study plot data and generate pandas df.
    For now just wy2019.
    """
    data = m.timeseries(stid='ATH20', start='201910010000', end='202009292350', qc_checks='all')
    print(data.keys())
    df = pd.DataFrame.from_dict(data['STATION'][0]['OBSERVATIONS'])
    df.set_index(df.date_time, inplace=True)
    df.index = pd.to_datetime(df.index)
    del df['date_time']
    return df

def pull_alta_guard():
    """same as pull_atwater, for alta guard house station."""
    data = m.timeseries(stid='AGD', start='201910010000', end='202009292350', qc_checks='all')
    print(data.keys())
    df = pd.DataFrame.from_dict(data['STATION'][0]['OBSERVATIONS'])
    df.set_index(df['date_time'], inplace=True)
    df.index = pd.to_datetime(df.index)
    del df['date_time']
    return df

def pull_udot():
    """same as pull_atwater, for UDOT Elbuts station, downcanyon."""
    data = m.timeseries(stid='ELBUT', start='201910010000', end='202009292350', qc_checks='all')
    print(data.keys())
    df = pd.DataFrame.from_dict(data['STATION'][0]['OBSERVATIONS'])
    df.set_index(df['date_time'], inplace=True)
    df.index = pd.to_datetime(df.index)
    del df['date_time']
    return df
