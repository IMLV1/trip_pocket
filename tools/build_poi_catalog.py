"""Derive a named Thai POI catalogue from a Geofabrik OSM extract (ODbL).

pip install osmium shapely
python tools/build_poi_catalog.py thailand.osm.pbf assets/thailand_pois.json
No public geocoding/Overpass API is queried. Raw input is not bundled.
"""
import argparse
import collections
import hashlib
import json
import math
from pathlib import Path

import osmium
from shapely.geometry import Point, shape
from shapely.strtree import STRtree


def category(tags):
    tourism = tags.get('tourism', '')
    amenity = tags.get('amenity', '')
    if tourism in {'hotel', 'motel', 'hostel', 'guest_house', 'chalet', 'apartment', 'resort', 'camp_site', 'caravan_site', 'alpine_hut'}:
        return 'lodging'
    if amenity in {'restaurant', 'cafe', 'fast_food', 'food_court', 'ice_cream', 'bar', 'pub'}:
        return 'food'
    if tourism in {'attraction', 'museum', 'viewpoint', 'zoo', 'theme_park', 'gallery', 'aquarium'} or tags.get('historic', '') in {'castle', 'ruins', 'archaeological_site', 'monument', 'memorial'} or amenity == 'place_of_worship':
        return 'attraction'
    if tags.get('leisure', '') in {'park', 'garden', 'nature_reserve', 'water_park'}:
        return 'other'
    return None


class Catalogue(osmium.SimpleHandler):
    def __init__(self):
        super().__init__()
        self.pois = {}
        self.provinces = []
        self.factory = osmium.geom.GeoJSONFactory()
        self.geometry_errors = 0

    def add(self, prefix, oid, tags, lon, lat):
        name = tags.get('name:th') or tags.get('name') or tags.get('name:en')
        kind = category(tags)
        if not name or not kind or not all(map(math.isfinite, [lat, lon])):
            return
        descriptors = {'cafe': 'cafe คาเฟ่ ร้านกาแฟ', 'restaurant': 'restaurant ร้านอาหาร', 'fast_food': 'fast food อาหารจานด่วน', 'hotel': 'hotel โรงแรม', 'hostel': 'hostel โฮสเทล', 'resort': 'resort รีสอร์ท', 'museum': 'museum พิพิธภัณฑ์', 'viewpoint': 'viewpoint จุดชมวิว', 'park': 'park สวนสาธารณะ'}
        descriptor = descriptors.get(tags.get('amenity', ''), descriptors.get(tags.get('tourism', ''), descriptors.get(tags.get('leisure', ''), '')))
        aliases = ' '.join(dict.fromkeys(v for v in [descriptor, tags.get('name', ''), tags.get('name:en', ''), tags.get('alt_name', ''), tags.get('addr:city', ''), tags.get('addr:district', ''), tags.get('addr:province', ''), tags.get('addr:state', '')] if v and v != name))
        self.pois[f'{prefix}{oid}'] = [f'{prefix}{oid}', name[:200], kind, round(lat, 6), round(lon, 6), '', aliases[:400]]

    def node(self, n):
        if n.location.valid() and category(n.tags):
            self.add('n', n.id, n.tags, n.lon, n.lat)

    def way(self, w):
        if not category(w.tags) or not (w.tags.get('name:th') or w.tags.get('name') or w.tags.get('name:en')):
            return
        positions = [(n.lon, n.lat) for n in w.nodes if n.location.valid()]
        if positions:
            # A representative area point replaces this fallback in area().
            self.add('w', w.id, w.tags, sum(p[0] for p in positions) / len(positions), sum(p[1] for p in positions) / len(positions))

    def area(self, a):
        province = a.tags.get('boundary') == 'administrative' and a.tags.get('admin_level') == '4' and a.tags.get('ISO3166-2', '').startswith('TH-')
        if not province and not category(a.tags):
            return
        try:
            geometry = shape(json.loads(self.factory.create_multipolygon(a)))
            if not geometry.is_valid:
                geometry = geometry.buffer(0)
            if geometry.is_empty:
                return
            if province:
                self.provinces.append((a.tags.get('name:th') or a.tags.get('name'), a.tags.get('name:en', ''), geometry))
            elif category(a.tags):
                point = geometry.representative_point()
                self.add('w' if a.from_way() else 'r', a.orig_id(), a.tags, point.x, point.y)
        except (RuntimeError, ValueError):
            self.geometry_errors += 1


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('input', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--boundary', type=Path, default=Path('assets/thailand.geojson'))
    args = parser.parse_args()
    with osmium.io.Reader(str(args.input)) as reader:
        timestamp = reader.header().get('osmosis_replication_timestamp')
    handler = Catalogue()
    handler.apply_file(str(args.input), locations=True, idx='flex_mem')
    country = shape(json.loads(args.boundary.read_text(encoding='utf-8'))['geometry'])
    tree = STRtree([p[2] for p in handler.provinces])
    rows, seen = [], set()
    for row in handler.pois.values():
        point = Point(row[4], row[3])
        if not country.covers(point):
            continue
        for index in tree.query(point, predicate='intersects'):
            province, english, _ = handler.provinces[int(index)]
            row[5] = province
            row[6] = (row[6] + ' ' + english).strip()
            break
        key = (row[1], row[2], row[3], row[4])
        if key not in seen:
            seen.add(key)
            rows.append(row)
    rows.sort(key=lambda r: r[0])
    metadata = {
        'format': 1, 'country': 'TH', 'dataTimestamp': timestamp,
        'source': 'https://download.geofabrik.de/asia/thailand.html',
        'license': 'ODbL-1.0', 'licenseUrl': 'https://opendatacommons.org/licenses/odbl/1-0/',
        'attribution': '© OpenStreetMap contributors',
        'inputSha256': hashlib.file_digest(args.input.open('rb'), 'sha256').hexdigest(),
        'columns': ['id', 'name', 'category', 'latitude', 'longitude', 'province', 'aliases'],
        'count': len(rows), 'categories': dict(collections.Counter(r[2] for r in rows)),
        'provinceCount': len(set(r[5] for r in rows if r[5])),
        'geometryErrors': handler.geometry_errors,
        'notes': 'Named community POIs only. Representative points may not be entrances. Approximate country boundary filter; small islands/borders may be incomplete. No prices or opening times verified.',
    }
    if len(rows) < 10000 or metadata['provinceCount'] < 70:
        raise RuntimeError(f'Unexpectedly incomplete catalogue: {metadata}')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps({'metadata': metadata, 'places': rows}, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')
    print(json.dumps(metadata, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
