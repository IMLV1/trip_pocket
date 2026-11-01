import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/providers.dart';
import '../../core/design_system.dart';
import '../../core/validation.dart';
import '../../core/widgets.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final form = GlobalKey<FormState>();
  final current = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool busy = false, visible = false;
  @override
  void dispose() {
    current.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: current.text,
            newPassword: password.text,
          );
      current.clear();
      password.clear();
      confirm.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('เปลี่ยนรหัสผ่านแล้ว')));
        context.pop();
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user =
        ref.watch(sessionProvider).value ??
        ref.read(authRepositoryProvider).currentSession;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('เปลี่ยนรหัสผ่าน')),
        body: PageBody(
          children: [
            const FormIntro(
              'รักษาบัญชีให้ปลอดภัย',
              'ยืนยันรหัสผ่านปัจจุบัน ก่อนตั้งรหัสใหม่',
              icon: Icons.lock_outline,
            ),
            if (user == null)
              const Text('กรุณาเข้าสู่ระบบอีกครั้ง')
            else if (!user.hasPassword) ...[
              const Text(
                'บัญชีนี้เข้าสู่ระบบด้วย Google และไม่มีรหัสผ่าน TripPocket การเปลี่ยนรหัสผ่าน Google ต้องทำในบัญชี Google ของคุณ',
              ),
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse('https://myaccount.google.com/security'),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text('จัดการความปลอดภัยบัญชี Google'),
              ),
            ] else
              Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const Key('current-password'),
                      controller: current,
                      enabled: !busy,
                      obscureText: !visible,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'รหัสผ่านปัจจุบัน',
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'กรอกรหัสผ่านปัจจุบัน'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('new-password'),
                      controller: password,
                      enabled: !busy,
                      obscureText: !visible,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'รหัสผ่านใหม่',
                        helperText:
                            'อย่างน้อย 6 ตัวอักษร และต่างจากรหัสปัจจุบัน',
                      ),
                      validator: (v) =>
                          passwordError(v) ??
                          (v == current.text
                              ? 'รหัสผ่านใหม่ต้องต่างจากรหัสปัจจุบัน'
                              : null),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('confirm-new-password'),
                      controller: confirm,
                      enabled: !busy,
                      obscureText: !visible,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => save(),
                      decoration: const InputDecoration(
                        labelText: 'ยืนยันรหัสผ่านใหม่',
                      ),
                      validator: (v) =>
                          v == password.text ? null : 'รหัสผ่านไม่ตรงกัน',
                    ),
                    TextButton.icon(
                      onPressed: busy
                          ? null
                          : () => setState(() => visible = !visible),
                      icon: Icon(
                        visible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      label: Text(visible ? 'ซ่อนรหัสผ่าน' : 'แสดงรหัสผ่าน'),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const Key('save-password'),
                      onPressed: busy ? null : save,
                      child: Text(
                        busy
                            ? 'กำลังเปลี่ยนรหัสผ่าน…'
                            : 'ยืนยันเปลี่ยนรหัสผ่าน',
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
}
