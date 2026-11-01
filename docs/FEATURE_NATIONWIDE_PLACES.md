# ค้นหาทั่วไทยและหมุดสถานที่แนะนำ

สถานะ 26 ตุลาคม 2569: ใช้ฐานสถานที่จริง OpenStreetMap ของประเทศไทย แทนชุดเชียงใหม่ 4 รายการใน V2.1 เดิม ไม่มี paid API/Billing/Go/backend เพิ่ม

## สิ่งที่ใช้ได้

- ค้นชื่อไทย/อังกฤษ คำประเภทจากแท็ก เช่น คาเฟ่/โรงแรม และจังหวัด ในเครื่อง
- กรองได้ 77 จังหวัด อำเภอ/เขต ตำบล/แขวง (แบบไล่ระดับ) และหมวดท่องเที่ยว อาหาร ที่พัก อื่น ๆ
- หน้ารายวันแสดงหมุดแนะนำสีน้ำเงิน แยกจากเลขหมุดของทริป พร้อมสวิตช์และตัวกรองหมวด
- เมื่อซูมออก รวมสถานที่ใกล้กันเป็นกลุ่มจำนวน แตะเพื่อซูมเข้า; เมื่อ zoom >=12 แสดงสูงสุด 100 ไอคอนในพื้นที่ พร้อมแจ้งเมื่อมีผลมากกว่าที่แสดง
- แตะไอคอน → รายละเอียด/แหล่งข้อมูล → เพิ่มจุดหมายนี้ → ตรวจหมุดในฟอร์ม → บันทึก ไม่เขียนเข้าแผนอัตโนมัติ
- ช่องค้นหา/แนะนำมีแผนที่กรองตามคำค้นและจังหวัด และรายการ 100 อันดับแรกพร้อมจำนวนทั้งหมด
- แผนที่ทริปว่างเริ่มจากกรอบประเทศไทยเหนือถึงใต้ ไม่ล็อกเชียงใหม่

## ชุดข้อมูล

ต้นทาง: https://download.geofabrik.de/asia/thailand.html
OSM data timestamp: 2026-10-31T21:23:06Z
Input SHA256: 970a2b35e47b3738edf8b42cc7d7b622ae885a608647753f55fb02c4e38173ee

assets/thailand_pois.json มี 67,074 แห่ง: อาหาร 33,651 ท่องเที่ยว 16,652 ที่พัก 14,985 อื่น ๆ 1,786 พบข้อมูลกระจายครบ 77 จังหวัด ไม่หมายความว่ามีทุกสถานที่หรือทุกร้านยังเปิดอยู่

เลือกเฉพาะสถานที่มีชื่อจาก OSM nodes/ways/areas ใช้ name:th ก่อน name/name:en จุดพื้นที่ใช้ representative point ซึ่งอาจไม่ใช่ทางเข้า จังหวัดมาจาก administrative boundaries ที่มี ISO3166-2=TH-* และ point-in-polygon ไม่เดาจากจังหวัดที่ใกล้ที่สุด กรองประเทศด้วย Natural Earth boundary ตามสัญญาเดิม ซึ่งเกาะเล็ก/แนวชายแดนอาจไม่ครบ

ไม่คัดรีวิว รูปภาพ อันดับ หรือราคาจาก Google และไม่แต่งราคา/เวลาเปิดปิด ใช้คำว่า “ข้อมูล ณ” จาก timestamp ของ extract ไม่อ้างว่าตรวจทุกสถานที่ด้วยมือ

ฐานอ่านผ่าน PlaceCatalog repository ด้วย isolate แล้วสร้างดัชนีพื้นที่ 0.25 องศา การแพน/ซูมคำนวณผลในเครื่องแบบหน่วงสั้น ๆ ไม่มี public Nominatim/Overpass request และไม่ดาวน์โหลด POIs ทั้งประเทศซ้ำจาก API ขณะใช้งาน

การค้นหาในฐานทำได้ออฟไลน์ แต่พื้นแผนที่ OSM ยังต้องใช้อินเทอร์เน็ตและตาม Tile Usage Policy: https://operations.osmfoundation.org/policies/tiles/

## สิทธิ์ข้อมูลและวิธีสร้างซ้ำ

แค็ตตาล็อกที่แปลงแล้วใช้ ODbL-1.0 แยกจาก source แอป มีเครดิต © OpenStreetMap contributors และลิงก์ลิขสิทธิ์ใน UI ดู assets/THAILAND_POIS_LICENSE.txt ซึ่ง bundle อยู่ใน APK เช่นเดียวกับ JSON ผู้รับ APK สามารถแตกไฟล์ ZIP เพื่อรับฐานข้อมูลที่แจกภายใต้ ODbL ได้ ไม่ใช้เงื่อนไข Private ของ source แอปจำกัดสิทธิ์ข้อมูลนี้

- https://www.openstreetmap.org/copyright
- https://opendatacommons.org/licenses/odbl/1-0/

อำเภอและตำบลมาจาก ADM3 ของ OCHA COD-AB Thailand (กรมแผนที่ทหาร, CC BY-IGO) https://data.humdata.org/dataset/cod-ab-tha ไม่ใช้ขอบเขต OSM เพราะระดับตำบลครอบคลุมเพียง 42% ของสถานที่ สถานที่แต่ละแห่งได้ค่าจากการจับพิกัดกับขอบเขต และรับเฉพาะเมื่อจังหวัดตรงกับ OSM ระบุได้ 99.8% ส่วนที่เหลือเว้นว่างและยังค้นด้วยจังหวัดได้ ฐานเป็น format 2 มีคอลัมน์ district และ subdistrict เพิ่ม

~~~powershell
python -m pip install -r tools/requirements-poi.txt
# ดาวน์โหลด country extract หนึ่งครั้ง ไม่ commit PBF ลง Git
# ดาวน์โหลด tha_admin3.geojson จาก HDX หนึ่งครั้ง ไม่ commit ลง Git
python tools/build_poi_catalog.py path/to/thailand.osm.pbf path/to/tha_admin3.geojson assets/thailand_pois.json
~~~

ต้องตรวจ metadata, count, provinces และชุดทดสอบก่อนอัปเดตฐานรุ่นใหม่ ไม่เปิด automatic country-wide API scraping

## ผลตรวจ

- Flutter analyze ไม่มี issues
- Flutter tests 33/33 ผ่าน รวมฐานจริงทุกจังหวัด ค้นหลายภูมิภาค/หมวด กลุ่มหมุด การแตะไอคอน และภาพรวมประเทศ
- Android Emulator: integration_test/nationwide_ui_test.dart ใช้ production loader และแค็ตตาล็อกจริง ผ่านการแตะหมุดแนะนำกรุงเทพ → ยืนยัน/บันทึก และค้น “ป่าตอง” → เลือกสถานที่ภูเก็ต → เพิ่มเป็นจุดที่สอง
- Cloud repository ใน UI test เป็น demo/fake; tiles/SharedPreferences เป็น native ของ Android แยกจากผล Firebase live รุ่นก่อน ไม่มี schema/Rules เปลี่ยนในรอบนี้ จึงไม่อ้าง live test ใหม่
- ภาพหลักฐาน: evidence/nationwide-bangkok-pois.png และ evidence/nationwide-phuket-search.png พื้นแผนที่บางส่วนยังโหลดอยู่ในภาพ แต่ POI มาจากข้อมูลในเครื่อง
- ยังไม่ได้ทดสอบมือถือจริง/iOS และยังไม่รองรับการคำนวณต่อรถหรือราคาสถานที่ทั่วไทยอัตโนมัติ

~~~powershell
flutter analyze --no-pub
flutter test --no-pub
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/nationwide_ui_test.dart -d emulator-5554 --no-pub
# Build main.dart กลับหลัง integration test ก่อนแจก APK
flutter build apk --debug --no-pub
~~~
