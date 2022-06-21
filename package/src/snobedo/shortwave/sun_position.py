from datetime import timedelta
from importlib.resources import files

import pytz
from skyfield import almanac
from skyfield.api import load_file, load, wgs84


class SunPosition:
    ONE_HOUR = timedelta(hours=1)
    ONE_DAY = timedelta(days=1)
    ONE_SECOND = timedelta(seconds=1)

    EPHEMERIS_DATA = 'de440_earth_sun.bsp'
    EPHEMERIS_FILE = files('snobedo.package_data').joinpath(EPHEMERIS_DATA)

    def __init__(self, lat, lon, elevation):
        self._location = wgs84.latlon(lat, lon, elevation)
        self._planets = load_file(self.EPHEMERIS_FILE)
        self._timescale = load.timescale()

    @property
    def sun(self):
        return self._planets['sun']

    @property
    def earth(self):
        return self._planets['earth']

    @property
    def observer(self):
        return self.earth + self._location

    @property
    def timescale(self):
        return self._timescale

    def rise_and_set(self, day):
        """
        Find sunrise and sunset for given day in UTC time

        :param day: <datetime> beginning of the period

        :return:
            Tuple: (Sunrise, Sunset)
        """
        times, up_or_down = almanac.find_discrete(
            self.timescale.from_datetime(day),
            self.timescale.from_datetime(day + self.ONE_DAY),
            almanac.sunrise_sunset(self._planets, self._location)
        )

        return times[up_or_down.argmax()].astimezone(pytz.utc), \
            times[up_or_down.argmin()].astimezone(pytz.utc)

    def at_time(self, time):
        """
        Sun Altitude and Azimuth at time

        :param time: <datetime> Time to calculate position for

        :return:
            Sun altitude in degrees
            Sun azimuth in degrees
        """
        astrometric = self.observer.at(time).observe(self.sun)
        altitude, azimuth, _distance = astrometric.apparent().altaz()

        # For days, where the sunrise/sunset is close to the full hour, the
        # altitude comes back negative with the body of the sun mostly
        # below the horizon. Filtering these days and consider the sun
        # not completely up or already down
        if altitude.degrees < 0:
            return None, None
        else:
            return altitude, azimuth

    def for_day(self, day):
        """
        Calculate the sun altitude and azimuth for every hour and initialized
        position (lat, lon, elevation), skipping times when the sun has set
        for the day.

        * Altitude angle above (zenith), below (nadir), or at the horizon:
          Zenith -> +90°
          Horizon-> 0°
          Nadir  -> −90°
        * Azimuth angle around the sky from the north pole:
          0° -> North,
          90° -> East,
          180° -> South,
          270° -> West.

        :param day: <datetime> date to calculate for

        :return:
            Hash with time steps as keys and Tuple values for altitude and
            azimuth. `None` values indicate that the sun is not visible
            during that time. Example:
            {
                time: (altitude, azimuth),
                time: (None, None)
            }
        """
        result = {}

        utc_start = day.astimezone(pytz.utc).replace(minute=0, second=0)
        utc_end = utc_start + self.ONE_DAY

        sun_rise, sun_set = self.rise_and_set(utc_start)
        sun_up = False

        if sun_set < sun_rise:
            raise ArithmeticError(
                'Sunrise and Sunset are for different days: \n'
                f'  Sunrise: {sun_rise} \n'
                f'  Sunset: {sun_set}.\n'
            )

        while utc_start < utc_end:
            # Hours after sunrise until sunset
            if sun_up and (sun_set - utc_start) > self.ONE_HOUR:
                result[utc_start] = self.at_time(
                    self.timescale.from_datetime(utc_start)
                )
            # Sunrise hour
            elif utc_start < sun_rise and \
                    (sun_rise - utc_start) < self.ONE_HOUR:
                minutes_to_sunrise = self.timedelta_to_minutes(
                    sun_rise - utc_start
                )
                # Use half of the amount of time after sunrise in this hour
                if minutes_to_sunrise < 59:
                    sun_up_in_hour = 60 - (60 - minutes_to_sunrise) // 2
                else:
                    sun_up_in_hour = 59
                utc_start = utc_start.replace(minute=int(sun_up_in_hour))
                result[utc_start] = self.at_time(
                    self.timescale.from_datetime(utc_start)
                )
                utc_start = utc_start.replace(minute=0)
                sun_up = True
            # Sunset hour
            elif sun_set > utc_start and (sun_set - utc_start) < self.ONE_HOUR:
                minutes_to_sunset = self.timedelta_to_minutes(
                    sun_set - utc_start
                )
                # Use half of the amount of time until sunset in this hour
                sun_up_in_hour = minutes_to_sunset // 2
                utc_start = utc_start.replace(minute=sun_up_in_hour)
                result[utc_start] = self.at_time(
                    self.timescale.from_datetime(utc_start)
                )
                utc_start = utc_start.replace(minute=0)
            else:
                result[utc_start] = (None, None)

            utc_start += self.ONE_HOUR

        return result

    @staticmethod
    def timedelta_to_minutes(delta):
        return int(delta.total_seconds() % 3600 // 60)
