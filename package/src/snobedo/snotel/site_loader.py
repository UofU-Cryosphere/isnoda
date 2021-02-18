import json

from .snotel_site import SnotelSite


class SiteLoader:
    @classmethod
    def parse_from_json(cls, file):
        data = json.load(open(file, 'r'))
        return [
            SnotelSite(name=key, lon=value['lon'], lat=value['lat'])
            for key, value in data.items()
        ]
