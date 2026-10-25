# คู่มือตรวจ P7 บน Android Emulator

ขอบเขตที่ผู้ใช้ยืนยัน 25 ตุลาคม 2569: ใช้ Android Emulator เพราะมือถือของผู้ใช้เป็น iPhone ผลรอบนี้ไม่ใช่การทดสอบบนมือถือจริงหรือ iOS

## ก่อนเริ่ม

- เปิด Pixel_10_Pro_XL แล้วตรวจ `adb devices -l` ว่า emulator-5554 อยู่ในสถานะ device
- ใช้บัญชีทดสอบเท่านั้น ชุด cold restart จะปฏิเสธการแทนที่ session บัญชีอื่น
- Firebase live ใช้ project เดิม trippocket-382b7 ไม่ต้องสร้าง project หรือเปิด billing เพิ่ม
- อย่า build/test Android สองงานพร้อมกันใน checkout เดียว
- หากต้องเก็บข้อมูลไว้ข้ามการทดสอบ ต้องระบุ `--no-uninstall`: Flutter 3.44.6 ถอนแอป integration test เมื่อจบโดยค่าเริ่มต้น

## Automated checks

~~~powershell
flutter analyze --no-pub
flutter test --no-pub
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/ui_flow_test.dart -d emulator-5554 --no-pub
~~~

Widget tests ตรวจ loading/error/not-found navigation, save failure แล้วยังคง draft และ ID เดิม, ป้องกันกดซ้ำ, map error/retry แล้วยังคงชื่อ/ราคา/หมุด และ preview ที่แช่ snapshot เดิมแต่เปิดใหม่จะเห็นกิจกรรมที่แก้ไข/ลบล่าสุด

UI driver ตรวจ native keyboard ผ่าน viewInsets.bottom จริง และ assert ว่าปุ่มบันทึกเลื่อนพ้นคีย์บอร์ดก่อนกดได้ รวมถึง workflow เดิม โดยใช้ demo cloud repository แต่ native preferences และ map tiles จริง ไม่ใช่หลักฐาน Firebase live UI ทุกหน้าบนมือถือจริง

## Cold process restart กับ Firebase จริง

รันสองคำสั่งต่อกันบนอุปกรณ์เดิม ห้ามถอนแอป/clear data ระหว่างกลาง

~~~powershell
flutter test integration_test/persistence_restart_test.dart -d emulator-5554 --dart-define=PERSISTENCE_PHASE=setup --no-uninstall --no-pub
flutter test integration_test/persistence_restart_test.dart -d emulator-5554 --dart-define=PERSISTENCE_PHASE=verify --no-uninstall --no-pub
~~~

setup สร้างบัญชีและข้อมูลชั่วคราว เก็บ manifest ทดสอบที่ไม่มีรหัสผ่าน แล้วทิ้ง session ไว้ verify ตรวจว่า PID เปลี่ยนจริง, Firebase กู้ session เดิม, packing checked ยังอยู่แม้ปิด network, อีก uid ไม่เห็น packing และการ resume ลบค้างไม่ล้าง packing ของทริป active จากนั้นล้าง fixtures และลบบัญชีทดสอบ

หาก setup ค้างก่อนจบ ให้รัน setup ซ้ำเมื่อ session/manifest ยังอยู่เพื่อ cleanup เฉพาะ fixture เดิม อย่าถอนแอปเพื่อแก้ปัญหา หากถอนแอปจน manifest หาย มี cleanup mode สำหรับ run ID ของบัญชี p7-restart ที่สร้างโดยชุดนี้เท่านั้น ห้ามใช้กับบัญชีส่วนตัว

## Native share แบบมีผู้ตรวจ UI

~~~powershell
# ยกเลิก share sheet และ assert dismissed
flutter test integration_test/native_share_test.dart -d emulator-5554 --dart-define=RUN_MANUAL_SHARE=true --no-uninstall --no-pub
# เลือกแอปรับข้อความและ assert selected action (ต้องตรวจเนื้อหาในแอปนั้นด้วย)
flutter test integration_test/native_share_test.dart -d emulator-5554 --dart-define=RUN_MANUAL_SHARE=true --dart-define=CHECK_SHARE_RECEIVER=true --no-uninstall --no-pub
~~~

เปิดหน้าต่าง Emulator บนจอก่อนรัน ชุดนี้รอการเลือก/ยกเลิกไม่เกิน 60 วินาที ไม่ใช่ automated test ล้วน อย่ากดส่งให้บุคคลอื่น การได้ success จาก share_plus บอกเพียงว่าเลือก action แล้ว ไม่ยืนยันว่าแอปรับข้อความครบหรือผู้รับได้รับ ต้องตรวจ screenshot/เนื้อหาที่แอปปลายทางแสดงด้วย

## ตรวจ keyboard / back / small screen ด้วยมือ

1. เปิด APK ปกติใน Emulator แตะช่องอีเมลและฟอร์มยาว ตรวจคีย์บอร์ดไม่บังช่อง/บันทึก และเลื่อนหน้าจอได้
2. Back ขณะคีย์บอร์ดเปิดควรซ่อนคีย์บอร์ดก่อน Back อีกครั้งจึงกลับหน้า
3. โหลดข้อมูลผิดพลาดหรือรายการถูกลบ: ปุ่มกลับต้องยังอยู่ และมี “กลับรายการทริป” ในหน้าไม่พบข้อมูล
4. ขณะกำลังบันทึก ปุ่มบันทึกถูกปิด การบันทึกไม่ผ่านต้องคง draft ไว้ให้ลองใหม่
5. ลองจอเล็กและขยายตัวอักษร; ถ้า emulator ต่อ physical keyboard จนไม่แสดง software keyboard ให้ระบุ environment จริงก่อนสรุปผล

## APK หลังตรวจเสร็จ

~~~powershell
flutter build apk --debug --no-pub
flutter install --debug -d emulator-5554
~~~

ต้อง build APK จาก main.dart กลับคืนหลัง integration tests เพราะทุก target ใช้ output `build/app/outputs/flutter-apk/app-debug.apk` ร่วมกัน ดู hash และผลล่าสุดใน IMPLEMENTATION_STATUS.md
