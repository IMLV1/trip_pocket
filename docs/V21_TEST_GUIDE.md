# ตรวจ V2.1 แบบฟรี

หมายเหตุล่าสุด: UI/ฐานสถานที่เปลี่ยนเป็นทั่วไทยแล้ว ดู FEATURE_NATIONWIDE_PLACES.md และ nationwide_ui_test.dart ส่วนรายการเชียงใหม่ 4 แห่งด้านล่างเป็นประวัติ V2.1/fixture regression เท่านั้น

ผลจริงอยู่ใน IMPLEMENTATION_STATUS.md โค้ดปกติใช้ Firebase Spark live; demo อยู่ในหน่วยความจำ ไม่ใช่ข้อมูล cloud จริง ห้ามใช้ข้อมูลส่วนตัวกับ fixtures

## ชุดตรวจ

~~~powershell
flutter analyze --no-pub
flutter test --no-pub
# Java 21 เช่น Android Studio jbr ต้องอยู่ใน PATH
npm run test:rules
npm run emulators
# แยก terminal ขณะ Auth/Firestore Emulator เปิดอยู่
flutter test integration_test/v21_firebase_test.dart -d emulator-5554 --no-uninstall --no-pub
flutter test integration_test/v21_firebase_test.dart -d emulator-5554 --dart-define=APP_MODE=live --no-uninstall --no-pub
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/v21_ui_test.dart -d emulator-5554 --no-pub
~~~

Rules ต้องผ่านก่อน publish schema ใหม่; live SDK test ใช้บัญชีชั่วคราวเฉพาะชุดและล้างเองใน finally ไม่เขียนทับทริปของผู้ใช้

UI test ใช้ fake cloud แต่ OSM tiles และ SharedPreferences จริง: หมุดเลข หมวด การเรียง ค่าเดินทางที่หมดอายุหลังเรียง ค้นหา เลือก/ยืนยันหมุด เพิ่มจุดที่ 3/4 ลบ และแชร์ราคาไม่ทราบ ภาพ tiles อาจโหลดไม่ครบตามเครือข่าย ไม่ใช่แผนที่ offline

## Native GPS และ Maps

~~~powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/v21_native_navigation_test.dart -d emulator-5554 --dart-define=RUN_NATIVE_NAVIGATION=true --no-pub
# จำลอง external launch ล้มเหลว แล้วเรียก browser branch จริง
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/v21_native_navigation_test.dart -d emulator-5554 --dart-define=RUN_NATIVE_NAVIGATION=true --dart-define=BROWSER_ONLY=true --no-pub
~~~

ต้องมีผู้ตรวจ native permission และ receiver UI ห้ามถือว่า launch สำเร็จแปลว่าเส้นทางถูกต้อง ให้ใช้ตำแหน่งจำลอง Emulator และตรวจชื่อ/พิกัดปลายทางด้วย

อนุญาตสิทธิ์เฉพาะครั้งนี้ได้ ไม่ต้องเปิด Google Location Accuracy เพิ่ม TripPocket ใช้ Android LocationManager อ่านครั้งเดียวเมื่อกดปุ่ม ต้องแยกผลจากฮาร์ดแวร์จริง ยังไม่ได้ตรวจการเดินทางบนถนนจริง/เสียงนำทาง

รอบ browser branch บนเครื่องนี้ถูกส่งต่อเข้า Maps ที่ติดตั้งอยู่ จึงไม่อ้างว่าได้ถอน Maps แล้วทดสอบบนอุปกรณ์ไม่มี Maps จริง Unit test ตรวจการ fallback/error อีกชั้น

ตำแหน่งปัจจุบันไม่เขียนลง Firestore/SharedPreferences แต่การเลื่อนแผนที่ร้องขอ tile พื้นที่นั้นจาก OSM และการกดนำทางส่งข้อมูลจุดหมาย/ต้นทางที่เลือกให้ Google Maps ผู้ใช้เลือกใช้เอง ไม่มี background tracking

## ข้อมูลสถานที่และขอบเขต

แค็ตตาล็อกคัดเองใน lib/features/places/curated_places.dart มี 4 รายการในเชียงใหม่ (ท่องเที่ยว 2 อาหาร 1 ที่พัก 1) ค้นชื่อ/หมวด/จังหวัดในเครื่องและกรองหมวดได้ ไม่มี API ค้นทั่วประเทศไทย

ตรวจชื่อและหมวดจากแหล่งข้อมูลเมื่อ 2026-10-26:

- วัดพระสิงห์: https://thai.tourismthailand.org/Attraction/วัดพระสิงห์วรมหาวิหาร
- วัดพระธาตุดอยสุเทพ: https://www.tourismthailand.org/Attraction/wat-phra-that-doi-suthep
- Jasmine และ Dusit Princess Chiang Mai: https://www.dusit.com/dusitprincess-chiangmai/

บันทึกเพียงชื่อ หมวด URL และวันที่ตรวจ ไม่คัดข้อความประชาสัมพันธ์/ภาพ/รีวิว พิกัดเป็นจุดโดยประมาณที่ผู้ใช้ต้องตรวจและยืนยันอีกครั้ง ราคาและเวลาเปิดปิดไม่ยืนยันจึงแสดงไม่ทราบ ไม่เดาความเหมาะสมกับงบจากข้อมูลที่ไม่มี

ขอบเขตหมุดใหม่ใช้ point-in-polygon ของ assets/thailand.geojson จาก Natural Earth 1:10m admin0 (public domain) ไม่ใช่ bounding box; ข้อมูลเป็นแบบ generalised เกาะเล็กและชายแดนอาจคลาดเคลื่อน ไม่ใช้เป็นข้อยืนยันเขตแดนทางกฎหมาย ข้อมูลเก่าไม่ถูกย้ายหรือลบทิ้งเพราะตัวกรองใหม่

- Dataset: https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_10m_admin_0_countries.geojson
- License: https://www.naturalearthdata.com/about/terms-of-use/
- OSM tiles: https://operations.osmfoundation.org/policies/tiles/
- Maps URLs: https://developers.google.com/maps/documentation/urls/get-started

## APK ส่งมอบ

~~~powershell
flutter build apk --debug --no-pub
flutter install --debug -d emulator-5554
~~~

ต้อง build main.dart หลัง integration tests ก่อนแจก เพราะใช้ชื่อ APK เดียวกัน ดู SHA256 ล่าสุดในสถานะ ไม่ commit APK/generated build ลง Git
