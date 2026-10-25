# UI/UX refresh — 26 ตุลาคม 2569

## สิ่งที่เปลี่ยน

- Design system ร่วมกัน: เขียวเข้ม พื้นสว่าง การ์ดขอบมน ปุ่มและช่องกรอกขนาดสม่ำเสมอ ใช้ Noto Sans Thai ในแอป ไม่ต้องโหลดฟอนต์จากเครือข่าย
- หน้าเข้าสู่ระบบมีปุ่มแสดง/ซ่อนรหัสผ่าน ย่อหัวต้อนรับบนจอเตี้ย/เปิดคีย์บอร์ด
- รายการทริปแสดงวันภาษาไทยและการ์ดที่อ่านง่ายขึ้น
- รายละเอียดทริปแยกแถบล่าง **แผนเที่ยว / แผนที่ / เตรียมของ** สร้างแต่ละหน้าเมื่อเปิดครั้งแรกและคงหน้าที่เคยเปิดเพื่อรักษา draft/ตำแหน่งเลื่อน
- การ์ดงบเน้นยอดคงเหลือ แยกราคาที่ทราบกับรายการไม่ทราบราคา ไม่มีการแก้สูตรคำนวณ
- การ์ดจุดหมายมีปุ่มดินสอแก้ไข ปุ่มเรียงขึ้น/ลงและลบยังอยู่บนการ์ด แก้/ลบทริปจากเมนูมุมบน
- ค้นสถานที่แสดงรายการทันที สลับแผนที่ด้วยปุ่มมุมมอง เปิดตัวกรองเพื่อเลือกจังหวัด/ประเภท และซ่อนส่วนรองเมื่อเปิดคีย์บอร์ด
- เช็กลิสต์แสดงความคืบหน้า เก็บในเครื่องแยก uid/tripId เหมือนเดิม

## การบันทึกจริง

APK ปกติสร้างจาก lib/main.dart โดย APP_MODE ค่าเริ่มต้นเป็น live: Firebase Authentication และ Cloud Firestore จริง ส่วน integration UI ใช้ demo repository และมีแถบสีเหลืองเตือนชัดเจนว่าไม่บันทึก Firebase

ไม่มีการเปลี่ยน schema/Rules/backend ไม่มีการเปิด billing หรือเพิ่มบริการเสียเงิน การเลือกสถานที่ยังต้องยืนยันก่อนบันทึก ราคาไม่ทราบไม่ถือเป็นศูนย์ และการลบยังใช้ขั้นตอนเดิมที่ทำต่อได้

## ตรวจซ้ำ

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/nationwide_ui_test.dart -d emulator-5554 --no-pub
# คืน APK ปกติหลัง integration test เสมอ
flutter build apk --debug --no-pub
```

ผลและข้อจำกัดล่าสุดอยู่ใน IMPLEMENTATION_STATUS.md แยกข้อมูลจำลอง, แค็ตตาล็อกจริง, Android Emulator และ Firebase live อย่างชัดเจน

## ฟอนต์

Noto Sans Thai: https://github.com/google/fonts/tree/main/ofl/notosansthai — SIL Open Font License 1.1 แจกใบอนุญาตที่ assets/fonts/OFL.txt พร้อมฟอนต์
