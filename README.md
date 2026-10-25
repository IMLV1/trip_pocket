# TripPocket

แอป Flutter ภาษาไทยสำหรับวางแผนเที่ยวส่วนตัว ใช้ Firebase Authentication และ Cloud Firestore โดยตรง เป้าหมาย Android

## ใช้งาน

ต้องมี Flutter 3.44.6 / Dart 3.12.2 และ Android SDK พร้อมอุปกรณ์หรือ emulator

~~~powershell
flutter pub get
flutter run -d emulator-5554
~~~

โหมดปกติเชื่อม Firebase จริง project `trippocket-382b7` บน Spark ฟรี เปิด Email/Password และใช้ Firestore Standard ที่ Bangkok (`asia-southeast3`) แล้ว Android package คือ `com.imlv1.trippocket`

สมัครบัญชีของตนเองในแอป → สร้างทริป → เพิ่มกิจกรรม เลือกและยืนยันหมุด → ตรวจงบ → เช็กของ → preview และเปิด share sheet

## โหมดทดสอบ

~~~powershell
npm ci
npm run emulators
# อีก terminal
flutter run --dart-define=APP_MODE=emulator
~~~

Android Emulator ใช้ host `10.0.2.2` ports Auth 9099 / Firestore 8080; มือถือจริงระบุ `--dart-define=EMULATOR_HOST=<IP เครื่องพัฒนา>` โหมด emulator ใช้ Firebase app แยกชื่อและ project `demo-trippocket` ไม่เขียน project จริง

ลอง UI โดยไม่เปิด Firebase: `flutter run --dart-define=APP_MODE=demo` มีป้ายโหมดจำลองชัดเจน ทริป demo อยู่ในหน่วยความจำและหายเมื่อปิดแอป เช็กลิสต์ยังเก็บในเครื่อง Release ยอมรับเฉพาะ live

## ตรวจสอบ

~~~powershell
flutter analyze
flutter test
npm run test:rules
flutter test integration_test/firebase_flow_test.dart -d emulator-5554 --dart-define=APP_MODE=emulator
flutter test integration_test/ui_flow_test.dart -d emulator-5554
flutter build apk --debug
~~~

Rules emulator ต้องมี Java 21 ใน PATH เช่น Android Studio jbr หากต้องการทดสอบ live ให้เปลี่ยน APP_MODE เป็น live ใน firebase_flow_test เท่านั้น ซึ่งสร้างบัญชี/ทริปทดสอบและล้างเมื่อจบ อย่าใช้ข้อมูลส่วนตัวกับชุดทดสอบ

APK อยู่ที่ `build/app/outputs/flutter-apk/app-debug.apk` การ build integration test จะใช้ path เดียวกัน จึงต้อง build main ใหม่ก่อนแจก APK

## V2.1 ฟรี

เพิ่มจุดหมายหลายจุดต่อวันจากแผนที่หรือค้นหาจากชุดเชียงใหม่ เรียงหมุด แยกหมวดและค่าเดินทาง อ่านตำแหน่งของฉันเมื่อกด และเปิด Google Maps นำทาง ไม่ใช้ Places/Routes API หรือเปิด Billing

ค้นหาเริ่มจาก 4 สถานที่ที่คัดเอง พิกัดแนะนำต้องยืนยันก่อนเพิ่ม ราคาไม่ทราบไม่ถือว่าฟรี ยอดกิจกรรมและค่าเดินทางเป็นยอดรวมทั้งกลุ่มที่ผู้ใช้กรอก ไม่คำนวณต่อรถหรือค่าโดยสารทั่วประเทศ

ดู [คู่มือตรวจ V2.1](docs/V21_TEST_GUIDE.md) และ [สัญญาส่วนขยาย](docs/FEATURE_THAILAND_TRIP_PLANNER.md)

## ความสามารถและข้อจำกัด

- 6 ประเภทหน้าจอ: login, register, รายการทริป, ฟอร์มทริป, รายละเอียด, ฟอร์มกิจกรรม
- ข้อมูล cloud แยก uid, ตรวจสิทธิ์ด้วย Firestore Rules และ validation ฝั่งแอป
- เงินเป็นสตางค์จำนวนเต็ม วันเป็น YYYY-MM-DD เวลาเป็นนาทีตั้งแต่เที่ยงคืน
- ลบทริปแบบ deleting → children → parent → local cleanup และลองต่อได้จากรายการ
- เช็กลิสต์เฉพาะเครื่อง แยกบัญชี/ทริป; JSON เสียจะแจ้งโดยไม่เขียนทับ
- แชร์ข้อความหลัง preview โดยไม่รวมหมายเหตุ พิกัด หรือเช็กลิสต์ ผล share sheet ไม่ยืนยันการส่งถึงผู้รับ
- แผนที่ OSM Standard มี attribution ที่มองเห็นและลิงก์ลิขสิทธิ์ ใช้ cache ของ flutter_map ตาม HTTP headers ไม่รองรับดาวน์โหลดแผนที่ออฟไลน์ ใช้เพื่อโครงงานขนาดเล็ก; เปลี่ยน URL ผ่าน TILE_URL และตรวจเงื่อนไข provider ใหม่ด้วย
- การย่อวันตรวจ children จาก server แต่ไม่รับประกันการแก้พร้อมกันหลายอุปกรณ์
- รุ่นนี้ตั้งค่า Firebase เฉพาะ Android; iOS/Web ต้องลงทะเบียน app และสร้าง config เพิ่มก่อนใช้ live
- ยังใช้ debug signing สำหรับ APK ทดสอบ ไม่ใช่ไฟล์พร้อมลง Play Store

ผลทดสอบจริงและงานค้างอยู่ใน [IMPLEMENTATION_STATUS](docs/IMPLEMENTATION_STATUS.md), คู่มือสาธิต [DEMO_GUIDE](docs/DEMO_GUIDE.md), คู่มือรันตรวจ P7 [P7_TEST_GUIDE](docs/P7_TEST_GUIDE.md) และ [เอกสารออกแบบ](docs/README.md)

Firebase client config ใน source เป็นข้อมูลเชื่อมต่อแอป ไม่ใช่ Admin credential; ห้ามใส่ service account, signing key หรือรหัสผ่านผู้ใช้ใน repo การ deploy ครั้งต่อไปทำเมื่อได้รับมอบหมายพร้อมตรวจ Rules tests ก่อน
