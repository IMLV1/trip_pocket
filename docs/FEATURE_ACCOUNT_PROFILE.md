# Account profile and password recovery — 2 พฤศจิกายน 2569

ผู้ใช้เพิ่มขอบเขต: ลืมรหัสผ่านทางอีเมล, หน้าโปรไฟล์แก้ชื่อ, รูปจาก Google ที่ยินยอมเชื่อม และเปลี่ยนรหัสผ่าน โดยใช้ Firebase Authentication เดิม ไม่เพิ่ม server/Firestore users document/Storage/billing

- Session เพิ่ม displayName/photoUrl/provider flags จาก Firebase Auth userChanges เพื่อ refresh โปรไฟล์โดยไม่สลับ uid หรือทิ้ง navigation state
- /forgot-password เปิดได้ก่อนล็อกอิน ส่ง reset link ด้วย Firebase Auth ภาษาไทย แสดงผลตอบกลับทั่วไป ไม่เปิดเผยว่ามีอีเมลในระบบหรือไม่ ไม่ log/persist password/token
- /profile ดูอีเมล/ชื่อ/รูป แก้ displayName (1–100 ตัวอักษร) บันทึกผ่าน updateDisplayName และแสดง fallback เมื่อรูปโหลดไม่สำเร็จ
- /change-password สำหรับ provider password ต้องกรอกรหัสปัจจุบัน, รหัสใหม่และยืนยัน ทำ reauthenticateWithCredential ก่อน updatePassword เสมอ ไม่ใช่การเปลี่ยนรหัส Gmail
- บัญชี Google-only ไม่มีรหัสแอปให้เปลี่ยน แสดงคำอธิบายและลิงก์ไปจัดการบัญชี Google ของผู้ใช้เอง
- Google Sign-In ขอเฉพาะ basic identity ไม่อ่าน Gmail/contacts เลือกบัญชีเองและยกเลิกได้ เชื่อมกับบัญชีเดิมด้วย linkWithCredential โดยรักษา uid และตรวจอีเมลตรงกันก่อน link ห้ามเงียบ ๆ sign in ไปอีกบัญชีเมื่อ credential มีเจ้าของอยู่แล้ว
- เมื่อเชื่อม Google ให้นำ photo URL จาก provider มาใช้ รักษาชื่อที่ผู้ใช้ตั้งเอง หากยังไม่มีชื่อจึงเติมจาก Google รีเฟรชรูปได้โดยยืนยันกับ Google อีกครั้ง ไม่อ้างว่าดึงรูป Gmail จากอีเมลที่พิมพ์ได้
- ปุ่มเข้าด้วย Google รองรับผู้ใช้ Google กลับมาเข้าแอป ต้องตั้ง provider/Android SHA/OAuth client และ iOS URL scheme ให้ตรงกับโปรเจกต์จริง ไม่สร้าง Admin credential ในแอป
- Firebase live provider configuration และ Rules strict dates ต้องเตรียม/ทดสอบก่อนเผยแพร่และขอยืนยันเมื่อกฎเครื่องมือกำหนด ทดสอบ UI/Emulator/Google interactive/live แยกกัน ไม่อ้าง Google sign-in ผ่านหากไม่ได้เลือกบัญชีจริง

แหล่ง API ที่ตรวจ: https://firebase.google.com/docs/auth/flutter/manage-users, https://firebase.google.com/docs/auth/flutter/federated-auth และ google_sign_in 7.2.0 จาก flutter.dev บน pub.dev
## Native Firebase configuration

Google provider เปิดแล้วใน project trippocket-382b7 (Spark) ชื่อสาธารณะ TripPocket ใช้ support email เจ้าของโปรเจกต์ ไม่ขอ Gmail/contacts scope Android config มี OAuth client type 1 สำหรับ debug SHA-1 และ type 3 สำหรับ server client; iOS config มี CLIENT_ID/REVERSED_CLIENT_ID และ Info.plist ตั้ง GIDClientID/GIDServerClientID/CFBundleURLSchemes แล้ว

SHA-1 ที่ลงทะเบียนเป็น debug certificate ของเครื่องพัฒนาเท่านั้น เมื่อทำ signed release หรือใช้ Play App Signing ต้องเพิ่ม SHA-1 ของ certificate นั้นและดาวน์โหลด config ใหม่ก่อนทดสอบ Google บน build นั้น ห้ามนำ private keystore ขึ้น Git

Windows ตรวจโครงสร้าง plist/IDs ได้ แต่ไม่แทนการ build ด้วย Xcode หรือทดสอบ Google callback บน iOS การล็อกอินด้วยบัญชี Google จริงให้เจ้าของบัญชียืนยันเอง ไม่เก็บ Google password ในแอป
