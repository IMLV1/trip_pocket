// Password reset request screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/design_system.dart';
import '../../core/errors.dart';
import '../../core/validation.dart';
import '../../core/widgets.dart';

/// Requests a reset link. The result text never reveals whether an account exists.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  bool busy = false, sent = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  /// Sends the request and switches to the confirmation view.
  Future<void> send() async {
    if (busy || sent || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email.text);
      if (mounted) setState(() => sent = true);
    } catch (e) {
      if (mounted) setState(() => error = errorText(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('ลืมรหัสผ่าน')),
      body: PageBody(
        children: [
          const FormIntro(
            'ตั้งรหัสผ่านใหม่',
            'กรอกอีเมลที่ใช้กับ TripPocket เพื่อรับลิงก์จาก Firebase',
            icon: Icons.lock_reset_outlined,
          ),
          if (sent) ...[
            const Icon(
              Icons.mark_email_read_outlined,
              size: 64,
              color: TripColors.primary,
            ),
            const SizedBox(height: 20),
            const Text(
              'หากอีเมลนี้มีบัญชีที่รองรับ ระบบจะส่งลิงก์ตั้งรหัสผ่านใหม่ให้ กรุณาตรวจกล่องจดหมายและสแปม',
            ),
            const SizedBox(height: 16),
            const Text(
              'ลิงก์มีอายุจำกัด หากหมดอายุให้กลับมาขอลิงก์ใหม่ รหัสผ่าน Gmail ไม่ถูกเปลี่ยนโดย TripPocket',
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('กลับเข้าสู่ระบบ'),
            ),
          ] else
            Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('reset-email'),
                    controller: email,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    onFieldSubmitted: (_) => send(),
                    decoration: const InputDecoration(
                      labelText: 'อีเมล',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: emailError,
                  ),
                  const SizedBox(height: 20),
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  FilledButton(
                    key: const Key('send-reset-email'),
                    onPressed: busy ? null : send,
                    child: Text(
                      busy ? 'กำลังส่งคำขอ…' : 'ส่งลิงก์ตั้งรหัสผ่านใหม่',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
