# หมุดพื้นที่หลักของทริป

ช่อง “จังหวัด / พื้นที่ที่จะไป” มีปุ่มค้นหาสถานที่ทั่วไทย และปุ่มเลือก/เปลี่ยนหมุดบนแผนที่ ยืนยันตำแหน่งแล้วเห็นแผนที่ตัวอย่าง ก่อนบันทึกทริป หมุดจะแสดงอีกครั้งในรายละเอียดและแท็บแผนที่ แก้ไข/เอาหมุดออกได้จากฟอร์มแก้ทริป

ข้อความพื้นที่เป็นป้ายกำกับ ไม่ใช่การ geocode: พิมพ์ชื่อใหม่จะไม่ย้ายหมุด ต้องกดเลือก/เปลี่ยนตำแหน่ง หมุดพื้นที่หลักไม่ใช่กิจกรรม จึงไม่เพิ่มยอดงบ ไม่เป็นจุดแวะลำดับแรกโดยอัตโนมัติ และไม่ส่งพิกัดในข้อความแชร์

## ข้อมูลและความเข้ากันได้

- Firestore trip เพิ่ม destinationLatitude/destinationLongitude เป็นคู่ nullable number
- Legacy ไม่มีทั้งคู่ → ไม่มีหมุด ไม่เดาพิกัดและไม่เปลี่ยนยอดเงิน
- บันทึกทริปไม่มีหมุด → null ทั้งคู่; เลือกแล้ว → number ทั้งคู่
- ฟอร์มเปิดแก้ทริปเดิมใช้พิกัดเดิม ยกเลิก picker ไม่ทับตำแหน่ง/ข้อความเดิม
- Rules ยังคง uid ownership, timestamps, active/deleting และตรวจชนิด/คู่/bounds
- ประเทศไทยตรวจใน picker ด้วย approximate boundary เดิม มีข้อจำกัดจุดริมแดน/เกาะเล็ก ไม่มี paid API หรือ GPS เพิ่ม

## ตรวจซ้ำ

```powershell
flutter analyze --no-pub
flutter test --no-pub
# Java 21 ใน PATH
npm run test:rules
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/trip_destination_ui_test.dart -d emulator-5554 --no-pub
# เมื่อ Rules ถูกเผยแพร่ไป live แล้ว และได้รับอนุญาตให้ทดสอบจริง
flutter test integration_test/v21_firebase_test.dart -d emulator-5554 --dart-define=APP_MODE=live --no-uninstall --no-pub
# คืน APK ปกติหลัง integration target เสมอ
flutter build apk --debug --no-pub
```

ชุด Android UI ใช้ cloud จำลอง แต่ production catalogue/แผนที่และ SharedPreferences Android จริง ชุด live SDK สร้างบัญชีและทริปทดสอบเฉพาะรอบแล้วล้างใน finally ไม่ใช่การทดสอบ UI ผ่านบัญชีผู้ใช้ ผลจริงและ hash APK ล่าสุดดู IMPLEMENTATION_STATUS.md
