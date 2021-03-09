import json

from .snotel_site import SnotelSite


class SnotelLocations:
    """
    Class to handle SNOTEL json data.

    Two options are present for usage:
    1. Only parse via `parse_json`
    2. Instantiate an instance first and use `load_from_json` to have all sites
       accessible via attribute.
    """

    def add_site(self, site):
        return setattr(self, site.name, site)

    def load_from_json(self, file):
        [self.add_site(site) for site in self.parse_json(file)]

    @staticmethod
    def parse_json(file):
        data = json.load(open(file, 'r'))
        return [
            SnotelSite(name=key, lon=value['lon'], lat=value['lat'])
            for key, value in data.items()
        ]
