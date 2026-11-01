# สถานะ TripPocket — 26 ตุลาคม 2569

ดำเนินการตามข้อ 1 ใน IMPLEMENTATION_PROMPTS.md โดยต่อยอด Flutter starter ใน `C:\Users\GOODK\IdeaProjects\trip_pocket` ผู้ใช้เปลี่ยนจาก Emulator เป็น Firebase จริงบน Spark และอนุญาต commit/push ไป `https://github.com/IMLV1/trip_pocket.git` (Private) แล้ว

สถานะล่าสุด: ค้นหาทั่วไทย 66,975 แห่ง/77 จังหวัด และเลือกหมุดแนะนำบนแผนที่ได้แล้ว ดู FEATURE_NATIONWIDE_PLACES.md และผล V2.2 ท้ายไฟล์

## ผลงาน

| Milestone | สถานะตามหลักฐาน |
|---|---|
| P0 Setup | Flutter 3.44.6 / Dart 3.12.2; dependency lockfiles; applicationId com.imlv1.trippocket; Android build และติดตั้งชุดทดสอบผ่าน |
| P1 App Shell | ธีม Material 3 ภาษาไทย, Riverpod แบบไม่ generate, go_router, 6 ประเภทหน้าจอ; workflow fake ผ่าน widget/Android UI tests |
| P2 Auth | Firebase Email/Password register/login/logout จริงผ่าน; router สร้างใหม่ต่อ uid ปิดหน้าข้อมูลเมื่อ logout; cold process restart ผ่านบน Emulator แล้ว; มือถือจริงยังไม่ได้ตรวจ |
| P3 Trip CRUD | Firestore client SDK, models, validation, query/index และ Rules; owner/user B/anonymous ผ่าน Emulator Rules; CRUD ผ่าน Android SDK ทั้ง Emulator และ live |
| P4 Activities/Budget | CRUD/เรียงวันเวลา/ยอดสตางค์/ย่อวัน/ลบ children ก่อน parent/cleanup retry ผ่าน; derived totals ไม่เก็บซ้ำ |
| P5 Map | OSM Standard, app identifier, built-in HTTP caching, attribution ที่มองเห็นและลิงก์ลิขสิทธิ์; แตะ ยืนยัน ยกเลิก และเปิดหมุดเดิมผ่าน Android UI test; ตรวจว่ามี tile จริง render แล้ว |
| P6 Packing | SharedPreferences แยก uid/tripId, malformed JSON ไม่เขียนทับ, cleanup queue; unit, Android offline persistence และกลับหน้ารายละเอียดผ่าน; cold restart ผ่านบน Emulator แล้ว; มือถือจริงยังไม่ได้ตรวจ |
| P6A Sharing | formatter/privacy/empty/over budget, preview/error/busy tests ผ่าน; Android native share sheet เปิด/แสดงข้อความ/ยกเลิก ผ่านบน Emulator โดย CUA กด Back และ assertion ได้ dismissed; Chrome รับข้อความครบและ callback success ผ่านบน Emulator; ไม่อ้างว่าส่งถึงบุคคล |
| P7 Integration | analyze + Flutter tests + Rules tests + Android Firebase SDK Emulator/live + Android UI ผ่าน; ปิด P7 ใน scope Emulator ที่ผู้ใช้เลือก; Chrome/Back ผ่านแล้ว; hardware จริง/iOS ไม่ได้ตรวจ |
| P8 Demo | มี DEMO_GUIDE และตัวอย่าง workflow; สไลด์และซ้อมกับบัญชีของผู้พัฒนายังเป็นงานเตรียมนำเสนอ |

## Firebase จริง

- Project `trippocket-382b7`, Spark (No-cost $0/month), ไม่เปิด billing/Blaze
- Android app `com.imlv1.trippocket`; client config ใน android/app/google-services.json
- Authentication: Email/Password เปิดแล้ว ไม่ใช้ SMS หรือ passwordless link
- Firestore Standard `(default)`, `asia-southeast3` Bangkok
- เผยแพร่ firestore.rules ที่ผ่าน Emulator tests แล้ว; composite index trips(status ASC, startDate ASC) สร้างแล้ว
- เริ่มจาก Production mode แล้วใส่ Rules เฉพาะเจ้าของ ไม่มี allow-all
- Analytics และบริการ AI ไม่ใช้ใน MVP
- Live integration สร้างบัญชี A/B และข้อมูลทดสอบชั่วคราว แล้วลบเมื่อชุดทดสอบจบผ่าน ไม่ใช้ข้อมูลส่วนตัว
- Native config ตั้งไว้เฉพาะ Android; iOS/Web ยังไม่ได้ลงทะเบียน app/config

## ผลตรวจจริง

อุปกรณ์ที่ใช้: Android Emulator `Pixel_10_Pro_XL`, serial `emulator-5554` ไม่ใช่มือถือจริง

| คำสั่ง/ระดับ | ผล |
|---|---|
| flutter doctor -v | Flutter/Android SDK พบ; cmdline-tools ขาดและ doctor แจ้ง license status unknown; build ใช้ SDK ที่ติดตั้งได้จริง Windows desktop ขาด Visual Studio ซึ่งไม่ใช่ target |
| flutter analyze --no-pub | ผ่าน ไม่มี issues หลังแก้ lint และ exclude node_modules |
| flutter test --no-pub | รอบแรก 7 tests; รอบ P7 ล่าสุด 13/13 ผ่าน รวม editor/map/share/small-screen regressions |
| npm run test:rules | ผ่าน 6 กลุ่มทดสอบ ไม่มี failure; PERMISSION_DENIED ใน log เป็นกรณีที่คาดว่าต้องถูกปฏิเสธ |
| firebase_flow_test APP_MODE=emulator | ผ่านบน Android ด้วย Auth/Firestore Emulator project demo-trippocket |
| firebase_flow_test APP_MODE=live | ผ่านบน Android เชื่อม Firebase จริง: register/login, create/update/delete, active cleanup intent, offline write rejection, anonymous/user B denial, interrupted deleting แล้ว resume |
| flutter drive ui_flow_test | ผ่าน: login demo → สร้าง → กิจกรรม → tile จริง/เลือกและยกเลิกหมุด → งบ → packing → preview → กลับหน้าแล้วของยังอยู่; ใช้ fake cloud repository แต่ map/native preferences จริง |
| native_share_test | ผ่าน 1/1 แบบมี CUA ช่วยกด Back: เปิด Android share sheet เห็นข้อความจริงและผล ShareResultStatus.dismissed; รอบต่อมา Chrome รับข้อความครบและ callback success ผ่าน 1/1; ไม่ได้ส่งหาผู้รับ |

ภาพ: [แผนที่](evidence/map-picker.png), [งบและกิจกรรม](evidence/trip-budget.png), [Android share sheet](evidence/android-share-sheet.png)

ระหว่างพัฒนาแก้ปัญหา build cache ชนจากการรัน Gradle สองงานพร้อมกัน โดยหยุดงาน build ล้าง generated cache และรันทดสอบทีละงานแล้วผ่าน แก้ emulator duplicate Firebase app ด้วย app แยกชื่อ `emulator`; ไม่ fallback ไป fake เมื่อ live ล้มเหลว

## วิธีรัน

~~~powershell
flutter pub get
flutter run -d emulator-5554
# ค่าเริ่มต้น APP_MODE=live
~~~

ทดสอบ Emulator: ตั้ง Java 21 ใน PATH → npm ci → npm run emulators แล้ว `flutter run --dart-define=APP_MODE=emulator` (Android emulator host 10.0.2.2) ส่วน `APP_MODE=demo` แสดงป้ายชัดและไม่เก็บ cloud data ข้ามการปิดแอป Release ใช้ได้เฉพาะ live

~~~powershell
flutter analyze
flutter test
npm run test:rules
flutter test integration_test/firebase_flow_test.dart -d emulator-5554 --dart-define=APP_MODE=emulator
flutter test integration_test/firebase_flow_test.dart -d emulator-5554 --dart-define=APP_MODE=live
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/ui_flow_test.dart -d emulator-5554
flutter build apk --debug
~~~

ชุดทดสอบ native share เป็น manual opt-in (`RUN_MANUAL_SHARE=true`) ต้องกดยกเลิกบน Android เอง ไม่รวมในคำกล่าวว่า automated suite ผ่าน

## งานที่ยังต้องตรวจ / ข้อจำกัด

- มือถือ Android จริง: keyboard/back/หน้าจอเล็ก, ปิดเปิด process แล้ว session/checklist ยังอยู่, map gestures และเน็ตขาดระหว่างใช้งานจริง
- เลือกแอปปลายทางที่รับข้อความและตรวจข้อความในแอปปลายทาง โดยไม่สรุปว่าส่งถึงผู้รับจากสถานะ plugin
- Maps error/retry มีโค้ดรักษาฟอร์ม; ยังไม่ได้จำลอง tile provider ล่มบนมือถือจริง
- ไม่มี guarantee การย่อวันพร้อมกันหลายอุปกรณ์ตาม BACKEND_ARCHITECTURE.md; client preflight ใช้ข้อมูล server แต่ Rules ไม่วน children ทั้ง collection
- OSM tiles เป็นบริการ best effort สำหรับการใช้ขนาดเล็ก ไม่ใช้ bulk download/offline maps; cache ใช้ BuiltInMapCachingProvider ของ flutter_map 8.3.2 ตาม HTTP headers
- Debug APK ใช้ debug signing; iOS/Web, release signing, Play Store และสไลด์ยังไม่ได้ทำ
- Flutter เตือน firebase_auth/firebase_core ยังใช้ Kotlin Gradle Plugin กับ template AGP 9 compatibility flags; build ปัจจุบันผ่าน แต่ควรตรวจแพ็กเกจก่อนอัปเกรด Flutter ในอนาคต
- ผลผ่าน Emulator/live ไม่ใช่ผลผ่านมือถือจริง; checklist บางรายการจึงยังไม่ติ๊กครบ Definition of Done

## Git และ APK

Repo ปลายทาง `IMLV1/trip_pocket` ตรวจ Private ผ่าน GitHub UI แล้ว Git author ใช้ค่าที่ผู้พัฒนาตั้งไว้ ไม่มีการเพิ่มผู้ร่วมงานหรือเปลี่ยน visibility

APK ปกติต้อง build จาก main.dart หลัง integration tests (tests ใช้ output path เดียวกัน) ดูบันทึกส่งมอบท้ายไฟล์สำหรับผล build/commit ล่าสุด

### บันทึกส่งมอบ 25 ตุลาคม 2569
- Final flutter analyze: ไม่มี issues; flutter test: 7/7 ผ่าน
- Final flutter build apk --debug --no-pub จาก main.dart: ผ่าน
- APK: build/app/outputs/flutter-apk/app-debug.apk (216094954 bytes)
- APK SHA256: D7A59F57657CA59658C5B1F57C1DA4391AA4BBF9FC422789E3744F11F575446B
- ตรวจ Private ของ repo แล้ว ส่ง initial code commit 5b169ee ไป main สำเร็จ และตรวจ remote revision ตรงกับ local โดยไม่ force push

### ตรวจ APK และ native share หลังรีสตาร์ต Emulator
- พบ Android system ANR ระหว่างตรวจ APK ปกติ ทำให้หน้าจอดำ/ควบคุม share sheet ไม่ตอบสนอง แม้ widget tree สร้างครบแล้ว
- รีสตาร์ตเฉพาะ Emulator แล้ว APK ปกติเปิดหน้า login ภาษาไทยสำเร็จ ดู evidence/live-login.png
- รัน native_share_test พร้อม RUN_MANUAL_SHARE=true ซ้ำ และใช้ CUA กด Control+Backspace ยกเลิก: ผ่าน 1/1 ได้ dismissed ภายใน 19 วินาที
- ปัญหา timeout สองรอบก่อนหน้าเป็นผลระหว่าง Android system ค้าง ไม่ใช้เป็นหลักฐานว่าแอปยกเลิกแชร์ไม่ได้
- ชุด native นี้มีผู้ช่วยกด UI จึงแยกจาก automated Flutter 7 tests; ยังไม่ทดสอบแอปผู้รับหรือมือถือจริง
- สร้างและติดตั้ง APK ปกติรอบสุดท้ายหลัง native test ผ่านแล้ว
- ผลส่งมอบ: โค้ดอยู่ใน https://github.com/IMLV1/trip_pocket บน branch main; build artifacts และ node_modules ไม่อยู่ใน Git

## รอบ P7 ต่อเนื่อง — 25 ตุลาคม 2569

ผู้ใช้แจ้งว่ามี iPhone และยืนยันให้ใช้ Android Emulator เป็นอุปกรณ์ตรวจรับรอบนี้ การทดสอบ iOS และมือถือ Android จริงอยู่นอกผลตรวจรอบนี้ ไม่มีการสร้าง Firebase app สำหรับ iOS หรืออ้างว่า APK ใช้บน iPhone ได้

- ตรวจ Git เริ่มจาก 656de5b, main สะอาด, remote IMLV1/trip_pocket
- อุปกรณ์ที่พบ: emulator-5554 (sdk_gphone16k_x86_64) เท่านั้น
- แก้หน้าฟอร์ม loading/error และรายการที่ไม่มี ให้มี AppBar/ปุ่มกลับรายการ
- เพิ่ม regression tests: ปุ่มกลับ, กิจกรรมถูกลบ, draft หลังบันทึกไม่สำเร็จ, stable retry ID และป้องกันกดซ้ำ (3 tests ผ่านแล้ว)
- เพิ่มชุด cold restart ที่ตรวจ PID ต่างกันจริง และอ่าน Firebase session/SharedPreferences หลังเริ่ม process ใหม่
- พบว่า flutter test ถอน app เมื่อจบโดย default จึงปรับคำสั่ง cold restart เป็น --no-uninstall ทั้ง setup/verify; การถอน app ไม่ใช้เป็นหลักฐานว่า persistence ของแอปผิด
- กำลังตรวจ cold restart และ native receiver ต่อ ก่อนสรุปผล/สร้าง APK/push

### บันทึกระหว่างรอบ (สถานะก่อนตรวจ Chrome สำเร็จ)

- flutter analyze --no-pub: ผ่าน ไม่มี issues
- flutter test --no-pub: ผ่าน 12/12 รวม 5 กรณีเพิ่มจากรอบก่อน (editor recovery 3, map failure/retry 1, share preview refresh 1)
- Cold restart setup/verify แบบ --no-uninstall: ผ่านทั้งสองรอบบน emulator-5554 ต่อ Firebase live; assert PID ต่างกัน, session restore, packing checked/offline/account isolation และ pending deletion cleanup ผ่าน
- Fixture ของรอบแรกที่ test runner ถอน app ถูกล้างด้วย client SDK เฉพาะบัญชี p7-restart ของชุดทดสอบแล้ว; รอบที่ผ่านล้างข้อมูล/บัญชีตัวเองหลัง verify ไม่มีรหัสผ่านบันทึกลงไฟล์
- Native receiver attempt: ยังไม่ผ่านการตรวจ เนื่องจาก CUA เปิดหน้าต่าง Emulator ไม่ได้ (failed to activate captured window) หลัง refresh/retry แล้ว จึงเลือกแอปรับข้อความไม่สำเร็จและ test timeout ไม่ใช้ผลนี้อ้างว่าแอปปลายทางรับข้อความแล้ว
- หยุด workflow run ที่ถูก chooser ของ fixture ค้างบัง และรีสตาร์ต Emulator เพื่อรัน workflow ใหม่ มีการขอให้ผู้ใช้เปิดหน้าต่าง Emulator ไว้สำหรับตรวจ receiver/keyboard ด้วยมือ
- Rules ไม่เปลี่ยน จึงไม่มีการ deploy ใหม่หรืออ้าง Rules tests รอบใหม่; ผล Rules 6 กลุ่มในตารางก่อนหน้าเป็นหลักฐานเดิม
- P7 รอบ Emulator ยังไม่ปิดครบ: การตรวจเนื้อหาในแอปปลายทางและ keyboard/back แบบ native ด้วยมือยังค้าง; ไม่มีมือถือจริงหรือ iOS ถูกทดสอบ

### ผลตรวจพื้นฐาน P7 และข้อค้างในเวลานั้น (ดูผลปิดรอบด้านล่าง)

| รายการ | ผลและระดับการตรวจ |
|---|---|
| Analysis | ผ่าน ไม่มี issues |
| Flutter tests | ผ่าน 13/13; เพิ่ม 6 regression tests จากรอบแรก |
| ฟอร์มเมื่อ loading/error/not-found | ผ่าน widget tests ด้วย go_router จริง มีปุ่มกลับ/ทางออก |
| Save failure / duplicate tap / retry ID | ผ่าน widget tests; draft ไม่หาย และ retry ใช้ ID เดิม |
| Map error/retry | ผ่าน widget error injection; แก้ callback ตอน idle ให้ schedule frame; ชื่อ ราคา และพิกัดเดิมไม่หาย |
| Preview หลังแก้/ลบกิจกรรม | ผ่าน widget test ด้วย fake repository; snapshot ที่เปิดอยู่คงเดิม เปิดใหม่ได้ข้อมูลล่าสุด |
| Cold process restart | setup/verify ต่อ Firebase จริงผ่านทั้งคู่บน Emulator โดย --no-uninstall และ PID ต้องต่างกัน; fixture cleanup ผ่าน |
| Android UI workflow ล่าสุด | ผ่าน flutter drive: demo auth/cloud CRUD, native map tiles และ SharedPreferences จริง |
| Keyboard / save button | ผ่าน Android UI assertion: viewInsets.bottom > 0 และ save button อยู่เหนือพื้นที่คีย์บอร์ด ก่อนกดบันทึกสำเร็จ |
| จอเล็ก | ผ่าน widget test 320x568 พร้อม keyboard inset จำลอง 230 px; ไม่ใช่ผลจากเครื่องขนาดนั้นจริง |
| Native receiver รอบนี้ | ยังไม่ผ่าน: CUA ไม่สามารถเปิดหน้าต่าง Emulator ขึ้นมาเลือกแอปได้ จึง timeout; ห้ามอ้างว่าแอปปลายทางได้รับข้อความ |
| มือถือจริง / iOS | ไม่ได้ตรวจ ตาม scope Emulator ที่ผู้ใช้เลือก |

ข้อค้างในเวลานั้น ซึ่งตรวจต่อสำเร็จแล้วด้านล่าง: เลือกแอปรับข้อความและตรวจเนื้อหาในแอปนั้น, ตรวจปุ่ม Back ของระบบขณะ IME เปิดด้วยมือ ไม่อ้างว่าผล selected action หรือการเปิด chooser ยืนยันการรับข้อความ

ผล cold restart จากรอบแรกที่ลืม --no-uninstall ถูกแยกเป็นปัญหา test harness และข้อมูลทดสอบรอบนั้นถูก cleanup แล้ว ไม่ตีความเป็นบั๊ก persistence ของแอป มีคู่มือรันซ้ำใน P7_TEST_GUIDE.md

### APK รอบ P7 ล่าสุด
- flutter build apk --debug --no-pub และ flutter install --debug -d emulator-5554: ผ่าน
- Path: build/app/outputs/flutter-apk/app-debug.apk
- Size: 216097697 bytes
- SHA256: 59211B9F6EE18EA6FC329FD5D83CA7082F70008DB5AF43F3EC736350B756D078
- ติดตั้ง APK จาก main.dart กลับคืนแล้ว ไม่ใช่ APK ของ integration test
- โค้ด/คู่มือ/ผลตรวจรอบนี้อยู่ใน commit ส่งมอบ P7 บน main ของ private repo เดิม

## ช่วงงานต่อ: Chrome receiver — 25 ตุลาคม 2569

- เปิด Emulator กลับขึ้นจอได้แล้วตามที่ผู้ใช้มอบหมาย
- Chrome เปิดครั้งแรก ผู้ใช้ยืนยันให้ยอมรับ Terms และใช้ Stay signed out; ข้ามการเปิด notifications
- ตรวจข้อความจริงใน Chrome แล้ว: TripPocket: เชียงใหม่, งบทั้งหมด 3,000.00 บาท, คงเหลือ 2,800.00 บาท ครบ ภาษาไทยไม่เสีย Chrome แสดง line breaks เป็นช่องว่างในช่องค้นหา
- ใช้ข้อมูลตัวอย่างเท่านั้น ไม่ส่งข้อความถึงบุคคลใด และไม่อ้างว่าแอปแชต/LINE ได้รับข้อความ
- หลักฐาน: evidence/chrome-receiver.png แสดงข้อความทั้งหมดในช่องค้นหาของแอปปลายทาง
- รอบ assisted receiver test 60 วินาที timeout ระหว่าง first-run/การสลับกลับ จึงเพิ่มเวลาสำหรับ manual receiver เป็น 180 วินาทีโดยยัง assert success เหมือนเดิม ไม่เปลี่ยน timeout เป็นผลผ่าน
- สถานะเมื่อจบช่วงแรก: manual content receipt ใน Chrome ผ่าน; callback-assisted assertion และ native Back/IME ตรวจผ่านในช่วงถัดไปด้านล่าง
- ตามคำขอผู้ใช้ จะแบ่ง commit ตามช่วงงานที่ตรวจจบ แยกหลักฐานรับแชร์ / native Back / สรุป P7

## ช่วงงานต่อ: native Back และ Chrome round trip — 25 ตุลาคม 2569

- native_share_test แบบ RUN_MANUAL_SHARE=true และ CHECK_SHARE_RECEIVER=true ผ่าน 1/1 ภายในประมาณ 34 วินาที เมื่อเลือก Chrome แล้วกลับเข้า test host
- ผล receiver component: com.android.chrome/com.google.android.apps.chrome.IntentDispatcher; assert ShareResultStatus.success ผ่าน แยกจากหลักฐานเนื้อหาที่ตรวจด้วยมือใน Chrome
- APK ปกติจาก main.dart: เปิดฟอร์มสมัครสมาชิก เปิด on-screen keyboard จาก IME แล้วกด Android Back (Control+BackSpace) แผงคีย์บอร์ดถูกซ่อนและยังอยู่บนฟอร์มเดิม ไม่มี crash; toolbar handwriting ของ IME ยังอยู่ จึงไม่อ้างว่า IME ทุกส่วนปิด
- หลักฐานก่อน/หลัง: evidence/keyboard-before-back.png และ evidence/keyboard-after-back.png เป็น Android Emulator จริง ไม่ใช่ภาพ widget จำลอง
- จอเล็กและปุ่มกลับฟอร์ม error/not-found ใช้ผล widget tests เดิม; ไม่อ้างว่าได้ตรวจบนมือถือจริง

## ผลปิด P7 ตาม scope Emulator — 25 ตุลาคม 2569

- ปิดงาน P7 ในขอบเขต Android Emulator ที่ผู้ใช้ยืนยัน: Firebase live workflow, cold restart, account isolation, offline/retry deletion, maps, budget, checklist, preview/cancel, Chrome receiver และ Back/keyboard มีหลักฐานตามระดับการตรวจข้างต้น
- Analysis ไม่มี issues; Flutter tests 13/13 ผ่าน; Rules เดิม 6 กลุ่มผ่านและไม่มี Rules เปลี่ยนในรอบนี้; native receiver รอบล่าสุด 1/1 ผ่าน ไม่รวมรอบ timeout เป็นผลผ่าน
- Back manual ตรวจแผงคีย์บอร์ดแบบ floating ของ IME บน APK ปกติ; save กับ keyboard inset ตรวจโดย Android UI test; จอเล็กและ navigation error states ตรวจด้วย widget tests จึงไม่เหมารวมเป็นการตรวจทุกหน้าด้วยมือ
- ข้อจำกัด: ยังไม่ได้ทดสอบ hardware Android จริงหรือ iOS, แอปแชต/LINE และการส่งถึงผู้รับ; Definition of Done เดิมที่ต้องใช้มือถือจริงยังไม่ได้ครบทั้งหมด
- APK ปกติล่าสุด build/install/run สำเร็จหลัง native test และอยู่ที่ build/app/outputs/flutter-apk/app-debug.apk; SHA256 59211B9F6EE18EA6FC329FD5D83CA7082F70008DB5AF43F3EC736350B756D078 ตรง APK รอบ P7 ข้างต้น
- Commit เป็นช่วง: 47a8c26 หลักฐาน Chrome, 0abdcf6 native Back/round trip; ตามด้วย commit เอกสารปิดรอบนี้บน main ของ repo Private เดิม
- งานถัดไป P8: เตรียมข้อมูลสาธิต บัญชีสาธิต สไลด์ และซ้อมนำเสนอ ยังไม่ได้ทำในรอบตรวจ P7 นี้

## V2.1 ฟรี — เริ่ม 26 ตุลาคม 2569

- [x] ตรวจโค้ด/skill และออกแบบ backward compatibility ก่อนแก้ schema
- [x] Model/repository/Rules และ tests
- [x] แผนที่รายวัน/เรียงหมุด/หมวด/เดินทาง/งบ/Maps/คำแนะนำ และค้นหาออฟไลน์
- [x] Android Emulator integration, APK ปกติและสรุปผล
- ไม่เปิด Billing/Blaze/API เสียเงิน; OSM และ Maps URL ตรวจเอกสารผู้ให้บริการแล้ว
- ใช้ incoming segment ใน Activity แทนเพิ่ม collection เพื่อรักษา resumable delete เดิม; ราคาไม่ทราบไม่ถือว่าฟรี

## V2.1 ช่วง model/UI — 26 ตุลาคม 2569

- เพิ่ม schema 2 โดยอ่าน legacy เป็นค่าเดิม; incoming travel ที่ล้าสมัยไม่รวมงบ และราคาว่างไม่แปลว่าฟรี
- หลายจุดหมายต่อวัน หมุดเลขตามลำดับ หมวด เรียงขึ้น/ลง transaction แก้/ลบ เพิ่มจากแผนที่และจากช่องค้นหาออฟไลน์เชียงใหม่
- ข้อมูลแนะนำคัด 4 รายการจาก TAT/Dusit: ชื่อ หมวด URL และวันที่ตรวจ 2026-10-26 พิกัดโดยประมาณต้องยืนยันก่อนเพิ่ม ไม่มีราคา/เวลาเปิดปิดแต่งขึ้น
- แผนที่ใช้ OSM policy เดิม ไม่มี API key/billing; ขอบเขตประเทศไทยจาก Natural Earth 1:10m public domain (assets/thailand.geojson) เป็นขอบเขตประมาณ เกาะเล็ก/ริมแดนอาจคลาดเคลื่อน ไม่ใช่ข้อมูลสำรวจ
- Flutter analyze ไม่มี issues; Flutter tests 23/23 ผ่าน (เดิม 13 + domain 7 + UI 3); Rules tests 9/9 ผ่าน (เดิม 6 + V2 3) ใน Emulator เท่านั้น
- ยังไม่อ้าง Android device/live schema ผ่านในช่วงนี้ กำลังเพิ่มทดสอบ integration และตำแหน่งปัจจุบันตามคำขอเพิ่มเติม

## V2.1 ช่วง GPS และ Android verification — 26 ตุลาคม 2569

- Analysis ไม่มี issues; Flutter unit/widget tests 25/25 ผ่าน (เพิ่ม GPS permission/timeout 2 tests) และ Rules Emulator 9/9 ผ่านตามช่วงก่อนหน้า
- Android Firebase SDK V2.1 ผ่าน 1/1 ทั้ง APP_MODE=emulator และ APP_MODE=live: legacy → schema2, ยอดเก่า, transaction reorder, ปฏิเสธ stale snapshot, anonymous/user B server reads และ resumable deletion/packing cleanup; บัญชี/ทริป fixture ล้างเมื่อจบ
- Rules เผยแพร่บน trippocket-382b7 ผ่าน Firebase Console สำเร็จ (CLI ไม่มี login) ขอบเขต owner-only เดิมและ Spark No-cost ($0/month) ตรวจแล้ว ไม่มี billing/Blaze/API คิดเงินหรือ service ใหม่
- Android UI workflow ผ่าน: 2→3→4 จุดจากค้นหาและแตะแผนที่ ยืนยันหมุด เรียงบนแผนที่/รายการ ค่าเดินทาง 50 บาทแยกยอดและถูกตัดออกเมื่อ reorder ทำให้ช่วงเดิมไม่ตรง ลบจุด และ preview ราคาไม่ทราบ โดย cloud repository เป็น demo/fake แต่ native tiles/SharedPreferences จริง
- Native GPS test ผ่านบน Emulator: ขอสิทธิ์เฉพาะครั้งนี้ อ่านจาก Android LocationManager โดยตรงและแสดงจุดพร้อม accuracy/timestamp; ไม่ใช้ Google Location Accuracy เพิ่ม ไม่มี stream/background หรือเก็บ current fix ลงบัญชี
- Native URL launch ผ่านและ CUA เห็น Maps รับ Your location → 18.7885000,98.9814000; Maps ขอ Location Accuracy สำหรับต้นทางปัจจุบัน จึงไม่อ้างว่าทดสอบนำทางจริงขณะเคลื่อนที่/เสียงนำทางครบ
- รอบ fallback จำลอง external handler ล้มเหลวแล้วเรียก inAppBrowserView จริงผ่าน; URL ถูกส่งต่อไป Maps ที่ติดตั้งอยู่ และ CUA เห็นเส้นทางถนนระหว่างพิกัดทดสอบเชียงใหม่ 4 นาที/1.2 กม. ณ เวลาทดสอบ เป็นผลของ Maps ไม่ใช่ค่าที่ TripPocket คำนวณหรือบันทึก
- กรณีไม่มี Maps ติดตั้งจริงยังไม่จำลองด้วยการถอน/ปิดแอป; unit test ยืนยัน browser fallback/error branch ไม่เหมารวมเป็นผล device กรณีไม่มีแอป
- ภาพ: evidence/v21-daily-map.png, v21-place-search.png, v21-current-location.png, v21-maps-receiver.png และ v21-route-receiver.png ภาพ tiles บางส่วนยังโหลดอยู่ ไม่อ้าง offline maps
- รอบแรก native test ถูกหยุดเมื่อ Fused Location ขอเปิดบริการ Accuracy เพิ่ม แล้วเปลี่ยนเป็น Android LocationManager และรอบใหม่ผ่าน; ไม่ใช้รอบที่หยุดเป็นผลผ่าน
- ยังไม่ได้ตรวจ handset Android จริง/iOS, on-road tracking หรือระบบรถสาธารณะอัตโนมัติ

## ส่งมอบ V2.1 ฟรี — 26 ตุลาคม 2569

V2.1 ตามขอบเขตที่ผู้ใช้เลือกเสร็จแล้ว พร้อมส่วนที่ขอเพิ่มระหว่างทำ: ค้นหาสถานที่แทนกรอกเอง, เพิ่มจุดหมายต่อเนื่องจากแผนที่, และตำแหน่งของฉัน/เปิด Maps จากฉัน

- Flutter analyze ไม่มี issues; unit/widget tests สุดท้าย 26/26 ผ่าน เพิ่ม regression ว่าเลือกสถานที่ใหม่แล้วล้างราคาของสถานที่เดิมและให้ยืนยันหมุดใหม่
- Rules 9/9 ผ่าน; Android SDK integration ผ่านทั้ง Firebase Emulator และ live; Android UI workflow และ native GPS/URL launcher ผ่านตามหลักฐานที่แยกไว้ด้านบน
- Build/install/run APK ปกติจาก main.dart สำเร็จ เปิดหน้า login ภาษาไทย ไม่มีป้าย demo/test และไม่ขอ GPS ตอนเริ่มแอป ไม่ใช่ integration test APK
- APK: build/app/outputs/flutter-apk/app-debug.apk (debug signing)
- Size: 217334388 bytes
- SHA256: 9D22362F41C20266590F0B17EEA2411BFA9FD1CD79AE268F8A8C69F393248180
- Commit เป็นช่วงและ push main: b64fbed สัญญาข้อมูล, 1e0dc90 หลายหมุด/ค้นหา, a445b02 GPS/Android verification และ commit เอกสาร/ผลส่งมอบรอบนี้
- Repo ยังคง Private ไม่มีการเปลี่ยน visibility; ไม่ commit APK/build artifacts
- ฟรีในขอบเขต Spark quota และนโยบาย OSM ไม่มี billing/Blaze/Places/Routes API หรือ Go server
- ข้อจำกัดส่งมอบ: แค็ตตาล็อกออฟไลน์เชียงใหม่ 4 รายการ, ราคาและการเดินทางกรอกเอง, ไม่คำนวณค่าโดยสาร/ต่อรถทั่วไทย, แผนที่ต้องใช้อินเทอร์เน็ตและอาจโหลดบางส่วน, ไม่มี turn-by-turn/เสียงภายใน TripPocket, ไม่รับผลจาก Maps กลับ
- มือถือจริง/iOS/on-road navigation ยังไม่ได้ตรวจ ไม่อ้างผล Emulator เป็น hardware จริง งาน P8 สไลด์และซ้อมนำเสนอยังอยู่นอกงานรอบนี้
- คู่มือรันทดสอบและ provenance: V21_TEST_GUIDE.md

## V2.2 ทั่วไทย — 26 ตุลาคม 2569

เริ่มแก้ตามผู้ใช้: ค้นทั่วประเทศและหมุดแนะนำบนแผนที่ ใช้ข้อมูล OSM extract ฟรี ไม่เรียก API สาธารณะเป็น backend; ยังไม่อ้างผ่านจนตรวจข้อมูลและ UI จริง


### V2.2 ฐานข้อมูลและ UI

- สร้าง assets/thailand_pois.json จาก Geofabrik Thailand OSM ณ 2026-10-24T20:20:51Z ผ่าน tools/build_poi_catalog.py; 66,975 สถานที่มีชื่อ ครบ 77 จังหวัด: อาหาร 33,612 ท่องเที่ยว 16,601 ที่พัก 14,979 อื่น ๆ 1,783 (ไม่ใช่การรับประกันว่ามีทุกสถานที่)
- อ่าน/สร้าง index นอก UI isolate; ข้อมูลสถานที่ค้นในเครื่อง ไม่ใช้ public Nominatim/Overpass หรือ API เสียเงิน
- ช่องค้นชื่อ/คำหมวด/จังหวัด ตัวกรองจังหวัด/ประเภท แผนที่แนะนำพร้อมไอคอน และกลุ่มจำนวนเมื่อซูมออก; zoom >=12 แสดงสูงสุด 100 ไอคอนใน viewport, รายการค้นหาแสดง 100 อันดับแรกพร้อมจำนวนผลทั้งหมด
- ข้อมูล OSM/ODbL มี attribution, source URL, timestamp, input SHA และ license แยกจาก source แอป; ไม่แต่งราคา/เวลาเปิดปิดหรืออ้างตรวจทุกสถานที่ด้วยมือ
- flutter analyze ไม่มี issues; unit/widget tests 32/32 ผ่าน รวมข้อมูลจริง 77 จังหวัดและการแตะหมุด/cluster
- กำลังตรวจ Android integration ไม่อ้าง device ผ่านในช่วงนี้ ไม่มี schema/Rules cloud เปลี่ยน

### ส่งมอบ V2.2 ทั่วไทย — 26 ตุลาคม 2569

- แก้ข้อจำกัดชุดเชียงใหม่แล้ว: production catalogue 66,975 แห่ง/77 จังหวัด พร้อมหมุดแนะนำที่แตะเลือกได้ ตัวกรองและกลุ่มจำนวน ไม่มี public geocoding API หรือ billing
- flutter analyze ไม่มี issues; Flutter tests 33/33 ผ่าน รวมกรอบประเทศเหนือถึงใต้ และชุด map tests 3/3 ผ่านหลังปรับปุ่มกลับภาพรวมประเทศ
- Android Emulator nationwide_ui_test ผ่าน: production catalogue/loader จริง แตะหมุดแนะนำกรุงเทพ แล้วยืนยัน/บันทึก จากนั้นค้นป่าตองและเพิ่มสถานที่ภูเก็ตเป็นจุดที่สอง; cloud repository ใน UI test เป็น fake/demo ไม่ใช่ Firebase live ใหม่
- ภาพหลักฐาน: evidence/nationwide-bangkok-pois.png และ evidence/nationwide-phuket-search.png
- ไม่มี schema/Rules cloud เปลี่ยน จึงไม่ deploy หรืออ้างผล Rules/live รอบใหม่; ผลด้านนั้นใน V2.1 เป็นหลักฐานเดิม
- สร้างและติดตั้ง APK ปกติจาก main.dart แล้ว: build/app/outputs/flutter-apk/app-debug.apk
- ตรวจ ZIP ภายใน APK พบ assets/flutter_assets/assets/thailand_pois.json (11,854,856 bytes, compressed 3,103,103 bytes), thailand.geojson และ THAILAND_POIS_LICENSE.txt จริง
- APK size: 217349761 bytes
- APK SHA256: 4B350BDE2451842456C7AB180452143542A2F737744416EE84D76CB8D41755E2
- Commit เป็นช่วง: 749c3c4 สัญญาขอบเขต, 6acc4ce ข้อมูล/ค้นหา/หมุดแนะนำ และ commit ส่งมอบผลตรวจ/คู่มือรอบนี้ push ไป main ของ Private repo เดิม
- ข้อมูลเป็น OSM community extract ณ 24 ต.ค. 2569 ไม่ใช่ทุกธุรกิจและไม่ยืนยันว่าร้านยังเปิดอยู่ ไม่มีการแต่งราคา/เวลาเปิดปิด ไม่อ้าง offline tiles หรือทดสอบมือถือจริง/iOS
- คู่มือและ data license/provenance: FEATURE_NATIONWIDE_PLACES.md

## UI/UX refresh — เริ่ม 26 ตุลาคม 2569

กำลังปรับ design system และแยกแผนเที่ยว/แผนที่/เตรียมของตามคำขอ อ่านสัญญา frontend ก่อนแก้ ไม่มี schema/Rules/API/billing เปลี่ยน ยังไม่อ้างผลทดสอบของ UI ใหม่


### UI/UX milestone 1 — design system และ navigation

- ใช้ Noto Sans Thai แบบ bundled พร้อม OFL, โทนเขียว/พื้นสว่าง, ปุ่ม/ช่องกรอก/การ์ด/ฟอนต์ร่วมกันทั้งแอป
- หน้าเข้าสู่ระบบแสดง/ซ่อนรหัสผ่านได้ และลดหัวต้อนรับเมื่อจอเตี้ยหรือเปิดคีย์บอร์ด
- หน้าทริปแยกแท็บ แผนเที่ยว/แผนที่/เตรียมของ สร้างแท็บเมื่อเปิดครั้งแรกและเก็บ state ของแท็บที่เคยเปิด
- งบแสดงยอดคงเหลือและรายการไม่ทราบราคา, แก้ไข/ลบทริปในเมนู, ปุ่มดินสอแก้จุดหมายชัดเจน
- ค้นหาสถานที่เปิดเป็นรายการทันที สลับแผนที่และเปิดตัวกรองได้ ลดข้อมูลที่ต้องเลื่อนผ่านก่อนเจอผลค้น
- flutter analyze ไม่มี issues; Flutter tests 33/33 ผ่าน รวม regression login/CRUD/account isolation และเพิ่มตรวจ packing draft เมื่อสลับแท็บ
- ปรับ integration scripts ให้ใช้แท็บใหม่แล้ว แต่ยังไม่อ้าง Android UI ผ่านจนรันจริง

### UI/UX milestone 2 — verification

- flutter analyze ไม่มี issues; Flutter tests 35/35 ผ่าน (เพิ่มจอ 320×568 ตัวอักษร 1.5 เท่า, ปุ่มแสดงรหัสผ่าน และค้นหาขณะ keyboard inset 230)
- Android Emulator API 37: nationwide_ui_test ผ่านด้วย production loader/catalogue 66,975 แห่ง/77 จังหวัด เลือกหมุดกรุงเทพ ค้นป่าตอง เพิ่มเป็นจุดที่สอง แก้จุดที่บันทึกแล้วโดยไม่สร้างซ้ำ และเช็กลิสต์หลังสลับแท็บ
- Android Emulator: v21_ui_test ผ่าน: native map tiles แสดงจริง, ค่าเดินทาง 50 บาทรวมไม่ซ้ำ, สลับลำดับแล้วราคา segment เดิมไม่ถูกนับ, เพิ่มจากค้นหา/แตะแผนที่ และ preview แชร์
- UI tests ใช้ demo/fake cloud (แถบเหลือง) แค็ตตาล็อก production จริง/fixture เชียงใหม่ใน regression ตามชื่อ test; ไม่ใช่ผล Firebase live ใหม่
- ภาพตรวจหน้าตาจริง: ux-login.png, ux-trip-list.png, ux-plan.png, ux-nationwide-map.png, ux-nationwide-search.png, ux-packing.png ใน docs/evidence; ภาพ map ทั่วไทยยังเป็นช่วง tiles โหลดไม่ครบ ส่วน v21-daily-map.png มี tiles แสดงจริง
- ไม่มี schema/Rules เปลี่ยน จึงไม่รัน Rules/live SDK ใหม่ งานค้างด้านอุปกรณ์: มือถือจริง/iOS ยังไม่ได้ตรวจ
- คู่มือ UI_UX_REFRESH.md และ frontend contract อัปเดตตรงกับโค้ด กำลังสร้าง APK ปกติจาก main.dart (default APP_MODE=live) กลับหลัง integration tests

### ส่งมอบ UI/UX refresh

- สร้าง APK ปกติจาก lib/main.dart สำเร็จ ติดตั้ง/เปิดบน emulator-5554 แล้ว เห็นหน้าเข้าสู่ระบบรุ่นใหม่ ไม่มีแถบโหมดจำลอง; main.dart ใช้ APP_MODE=live เป็นค่าเริ่มต้นและเชื่อม Firebase project เดิม ไม่มีการทดสอบเขียน live เพิ่มในงาน UI นี้
- APK: build/app/outputs/flutter-apk/app-debug.apk (debug signing สำหรับทดสอบ ไม่ใช่ Play release)
- Size: 217373915 bytes
- SHA256: 3BF5EEF0CE52CE505E64111FAC7A86A243A6C320D46486D38AB328C624946C87
- Commit เป็นช่วงและ push main: 0518850 design/UI/navigation, 1f9fb9e ผลตรวจ responsive/Android และเอกสาร/evidence ตามด้วยบันทึกส่งมอบนี้ ไม่เปลี่ยนสิทธิ์ Private ของ repository
- งานค้าง: มือถือจริง/iOS และ native share recipient ไม่ได้ตรวจซ้ำในรอบ UI; ผล native share รุ่นเดิมยังบันทึกใน P7 การทดสอบ UI ใหม่ใช้ fake cloud ตามที่ระบุ ไม่อ้างเป็นการยืนยัน Firebase live รอบใหม่

## เริ่มหมุดพื้นที่หลักของทริป — 26 ตุลาคม 2569

ปรับสัญญา frontend/backend/database ก่อนแก้ schema: optional paired coordinates สำหรับ trip destination, legacy ไม่เดาพิกัด, ค้น/เลือก/ยืนยัน/preview และแสดงในแผนที่แยกจากกิจกรรม กำลังพัฒนา ยังไม่อ้างผ่าน

### หมุดพื้นที่หลัก — milestone 1

- ฟอร์มค้น/เลือก/ยืนยันหมุด พร้อม preview และแสดงหมุดพื้นที่หลักในแท็บแผนที่ แก้ไข/ล้างได้ แยกจาก activities และไม่กระทบงบ
- เพิ่ม optional coordinate pair, อ่าน legacy โดยไม่เดาพิกัด, คู่ null ล้างได้, ownership/deletion flow เดิม
- flutter analyze ไม่มี issues; Flutter tests 38/38 ผ่าน; Rules Emulator tests 10/10 ผ่าน รวม legacy/null/pin/invalid/cross-account/deleting
- Android trip_destination_ui_test รอบแรกผ่านด้วย production catalogue และ fake cloud; กำลังตรวจเพิ่มปุ่มกลับดูหมุดทั้งหมดหลังแก้ camera fit และยังรอ live SDK ใหม่
- ผู้ใช้ยืนยันเผยแพร่ Rules ณ ขั้นตอน Publish แล้ว เผยแพร่ผ่าน Firebase Console สำเร็จ 26 ต.ค. 2569 16:00 น. (แสดงใน Console); CLI ไม่ได้ authenticate จึงใช้ Console เดิม ไม่สร้าง credential ใหม่
- firestore.rules SHA256: F9BA01CB6AE66A9BFD01DECC406894EF041AF2316001AF9160CAD1E45C6E7B12; หลักฐาน docs/evidence/firebase-trip-pin-rules.png
- คู่มือ FEATURE_TRIP_DESTINATION_PIN.md; ยังไม่อ้าง live SDK ผ่านหรือ APK ส่งมอบรุ่นนี้จนตรวจจริง

### หมุดพื้นที่หลัก — verification

- Android Emulator trip_destination_ui_test ผ่านรอบสุดท้าย: production catalogue ค้นวัดอรุณ → ยืนยันหมุด → preview → บันทึก → เปิดแก้ตำแหน่งเดิม → ยกเลิกไม่ทับเดิม → เปลี่ยน/บันทึก → ล้างหมุดได้; ไม่สร้าง activity และงบ 2,500 บาทคงเดิม ปุ่มดูจุดหมายทั้งหมดกลับมาที่หมุดพื้นที่หลักได้
- UI test ใช้ fake cloud; screenshot แสดงหมุดจริงบนพิกัดที่เลือก แต่พื้น tiles ยังโหลดไม่ครบในภาพ ไม่มีการอ้าง offline tiles
- Firebase live SDK บน Android Emulator ผ่าน: เก็บ/อ่าน destinationLatitude/Longitude จาก Source.server จริง ล้างเป็น null pair ได้และยอดเงินคงเดิม รวม legacy activity upgrade/reorder/stale rejection/resumable deletion/cross-account denial เดิม
- รอบ live แรกตรวจ pin/clear ผ่าน แต่ชุด regression หยุดที่ชนิดข้อผิดพลาด: Android method channel ห่อ StateError เป็น FirebaseException(unknown) จึงปรับ matcher รับ wrapper และเพิ่ม assertion อ่านจาก server ว่าข้อมูล/ลำดับเดิมไม่ถูกทับ ทั้ง stale reorder และ save บน deleting parent; รันซ้ำผ่านทั้งหมด ไม่ได้ลดการตรวจความปลอดภัย
- test สร้างบัญชี/ทริปเฉพาะรอบและล้างใน finally; ไม่แก้ข้อมูลทริปของผู้ใช้ ไม่มี billing/Go/paid API
- Flutter analysis ไม่มี issues, unit/widget 38/38, Rules Emulator 10/10 ผ่านตามรอบก่อนหน้า กำลังคืน APK ปกติ main.dart/live หลัง SDK target

### ส่งมอบหมุดพื้นที่หลัก

- สร้าง APK ปกติ main.dart/default live สำเร็จ ติดตั้งและสั่งเปิดบน emulator-5554 ผ่าน Flutter CLI แล้ว (engine/VM service เชื่อมได้) ไม่ส่ง integration-test APK ให้ผู้ใช้
- APK: build/app/outputs/flutter-apk/app-debug.apk — 217383006 bytes, debug signing
- SHA256: 518DB78F22CAA3882DCFFA4A5465D39203665E855D07E5798D9D9D629627B577
- Commit/push เป็นช่วง: fe1e595 ฟีเจอร์/schema/Rules/tests, 5a489d2 ผล live SDK และ assertion พฤติกรรม แล้วบันทึกส่งมอบนี้ ไป main ของ repository เดิม ไม่แก้สิทธิ์ Private
- ข้อจำกัด: มือถือจริง/iOS ยังไม่ได้ตรวจ พื้น tiles ต้องใช้อินเทอร์เน็ตและในภาพหลักฐานยังโหลดไม่ครบ หมุดทริปเก่าต้องเลือกเพิ่มเอง ไม่มีการเดาพิกัดจากชื่อ

## Firebase iOS setup — 2 พฤศจิกายน 2569

- ลงทะเบียน TripPocket iOS ใน Firebase project เดิม trippocket-382b7 แล้ว Bundle ID com.imlv1.trippocket; App ID 1:488059345725:ios:8f897289980e7264a28354
- ดาวน์โหลด GoogleService-Info.plist จริงจาก Console และใส่ ios/Runner/GoogleService-Info.plist พร้อมลิงก์เข้า Runner Resources ใน Xcode project ไม่ใช่เพียงวางไฟล์ไว้ในโฟลเดอร์
- ตรวจ XML plist และ PROJECT_ID/BUNDLE_ID/GOOGLE_APP_ID ตรงกับ project/Runner; ตรวจ file reference, build file และ resource membership แล้ว git diff --check ผ่าน
- ไม่แก้ Dart/SDK packages/schema/Rules/billing จึงไม่รัน Flutter regression หรือ Rules tests ซ้ำสำหรับงาน native configuration นี้
- ข้อจำกัด: เครื่อง Windows ไม่มี Xcode จึงยังไม่ได้ build iOS, code signing หรือทดสอบ Auth/Firestore บน iPhone; ผล Android/live รุ่นก่อนหน้าไม่ใช่ผล iOS

## เริ่มบัญชีผู้ใช้และ strict dates — 2 พฤศจิกายน 2569

- ปิดงาน audit ทุก refs/reflog/objects และภาพแล้ว รายงาน REPOSITORY_AUDIT.md commit 9f2814a ไม่มีการลบข้อมูลหรือ rewrite history
- วันทริปใหม่/active save ต้องเริ่มก่อนจบเท่านั้น Domain/form/Rules ปรับแล้ว; Flutter tests 39/39 ผ่าน กำลังตรวจ Rules และ legacy deletion
- เริ่ม reset password / Firebase profile / Google photo link / change password ตาม FEATURE_ACCOUNT_PROFILE.md ยังไม่อ้างผลทดสอบหรือ live provider พร้อมจนตรวจจริง

### บัญชีและการจัดการทริป — milestone 1

- เพิ่มลืมรหัสผ่าน, แก้ชื่อ Firebase Auth, เชื่อม Google เพื่อรูปโปรไฟล์, เปลี่ยนรหัสผ่านด้วย reauthentication; ไม่อ่าน Gmail และไม่บันทึกรหัสผ่านลง Firestore
- เพิ่มค้นหาชื่อทริป, ยืนยันจบทริป และแยกกำลังจะไป/จบทริปแล้ว; completed เป็น optional bool อ่านข้อมูลเก่าเป็น false และยังแก้รายละเอียด/ลบได้
- Flutter analyze ไม่มี issues; unit/widget 42/42 ผ่าน; Firestore Rules Emulator 12/12 ผ่าน รวม strict dates, legacy deletion, completed และแยกบัญชี
- Android Emulator API 37: account_management_firebase_test ผ่านด้วย Auth/Firestore Emulator จริง รวม reset OOB code, reauthentication, Google fixture cancel/ผิดอีเมล/link UID เดิม, ชื่อ/รูป และ completion/budget/checklist/cross-account
- Google fixture ไม่ใช่ Google OAuth จริง; live SDK และ UI รอบใหม่ยังไม่อ้างผ่าน
- ผู้ใช้อนุญาตตั้งค่า Firebase จริงแล้ว เปิด Google provider สำเร็จ ใช้ TripPocket/support email เจ้าของ เพิ่ม SHA-1 debug และดาวน์โหลด native OAuth configs; ยังไม่เปิด Billing
- อัปเดต Android google-services.json และ iOS plist/URL scheme จาก config จริง ตรวจ project/bundle/client type แล้ว; iOS ยังไม่ได้ build บน Windows

### บัญชีและการจัดการทริป — live verification

- เผยแพร่ Firestore Rules ผ่าน Console สำเร็จ 2 พ.ย. 2569 เวลา 02:29 ตามหน้าประวัติ Console หลังผู้ใช้อนุญาต; SHA256 C0E6260DD8BDCB198FBA73848181FDBF6309E8DB4DC306D18F693B95D8A1F0A9
- Android Emulator API 37: account_management_firebase_test พร้อม LIVE_ACCOUNT_TEST=true ผ่านกับ Firebase project trippocket-382b7 จริง: แก้ชื่อ/reload UID เดิม, reauthenticate ด้วยรหัสผิดถูก, เปลี่ยนรหัสและล็อกอินใหม่, complete ซ้ำได้/แก้รายละเอียดหลังจบ, budget/checklist คงเดิม และ cross-account denied
- ตรวจ Rules จริงด้วย direct SDK update: endDate เท่ากับ startDate และ completed true -> false ถูกปฏิเสธ permission-denied; อ่าน Source.server ตรวจสถานะจริงแล้ว
- สร้างและล้างเฉพาะบัญชี/ทริปทดสอบใน finally ไม่ใช้ข้อมูลบัญชีเจ้าของ และไม่เปิด billing
- Android UI 3 scenarios ผ่านด้วย fake repositories: reset validation/generic response, profile/password confirmation, search/cancel/confirm complete/list separation
- live test ไม่ส่งอีเมลไป example.com และไม่ใช้ Google fixture กับ live Auth; reset OOB code ผ่านเฉพาะ Auth Emulator, การรับอีเมลจริงและ Google interactive ยังไม่ได้ตรวจ

### บัญชีและการจัดการทริป — final regression

- Flutter analyze --no-pub: No issues found; Flutter unit/widget tests 43/43 ผ่าน
- Android Emulator account_management_ui_test รอบสุดท้าย 4/4 ผ่าน (ใช้ scenario ร่วมกับ widget tests): ลืมรหัสผ่าน, profile/password, search/completion/list isolation และ DatePicker วันจบเริ่มได้ตั้งแต่ start + 1 วัน
- รอบเพิ่ม test พบ nullable initialDate และ lint braces ใน integration cleanup แก้เฉพาะ test แล้วรัน analyze/tests ผ่าน ไม่ใช่บั๊กการบันทึกข้อมูล
- Firebase Auth/Firestore Emulators ที่ใช้ทดสอบหยุดแล้ว; live SDK รอบนี้ผ่านตามบันทึกข้างต้น
- ตรวจ GitHub หน้า IMLV1/trip_pocket แสดง Private หลัง push b6ce1c5 แล้ว ไม่มีการเปลี่ยน visibility
- กำลังสร้าง APK ปกติ lib/main.dart/default live แทน integration target; จะบันทึกผล build/install และ hash เมื่อเสร็จ

### ส่งมอบบัญชีและการจัดการทริป

- สร้าง APK ปกติจาก lib/main.dart/default APP_MODE=live สำเร็จ และติดตั้ง/สั่งเปิดบน emulator-5554 ผ่าน Flutter CLI แล้ว engine/VM service เชื่อมได้ จากนั้น detach โดยคงแอปไว้
- APK: build/app/outputs/flutter-apk/app-debug.apk (debug signing สำหรับทดสอบ)
- Size: 217510459 bytes
- SHA256: 356D712E4FB1D23DDF37CAEF7C80F7F3D6F78C6D35673383958605F6A071FA19
- Windows screenshot ของหน้าต่าง Emulator รอบนี้จับพื้น Flutter เป็นสีดำ จึงไม่ใช้ภาพนั้นยืนยันหน้าตา normal APK; หลักฐานพฤติกรรม UI คือ integration scenarios 4/4 และ SDK Emulator/live ที่ผ่านข้างต้น
- Commit/push เป็นช่วง: 3b2d596 implementation/native config, b6ce1c5 live SDK/security/UI tests ตามด้วยรายงานส่งมอบนี้; GitHub ยังคง Private
- ค้างการทดสอบที่ต้องเจ้าของบัญชียืนยัน: Google sign-in/link และรูปจริง, การรับ reset email จริงใน mailbox; Windows ยังไม่ build/test iOS และยังไม่ได้ตรวจมือถือจริง ไม่อ้างผลเหล่านี้ผ่าน
- Build มีคำเตือน upstream firebase_auth/firebase_core เรื่อง Kotlin Gradle Plugin สำหรับ Flutter รุ่นอนาคต แต่ build รุ่นปัจจุบันสำเร็จ ไม่ปรับ native toolchain เพิ่มนอกขอบเขตนี้
