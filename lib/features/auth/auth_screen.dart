import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/validation.dart';
import '../../core/errors.dart';
import '../../core/widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final bool register;
  const AuthScreen({super.key, this.register = false});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      if (widget.register) {
        await repo.register(email.text, password.text);
      } else {
        await repo.signIn(email.text, password.text);
      }
    } catch (e) {
      if (mounted) setState(() => error = errorText(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('TripPocket')),
    body: PageBody(
      children: [
        const SizedBox(height: 32),
        Icon(
          Icons.travel_explore,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          widget.register ? 'เริ่มวางแผนทริปแรก' : 'ทุกทริป เริ่มจากแผนดี ๆ',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('email'),
                controller: email,
                enabled: !busy,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'อีเมล'),
                validator: emailError,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('password'),
                controller: password,
                enabled: !busy,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
                validator: passwordError,
              ),
              if (widget.register) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirm,
                  enabled: !busy,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'ยืนยันรหัสผ่าน',
                  ),
                  validator: (v) =>
                      v == password.text ? null : 'รหัสผ่านไม่ตรงกัน',
                ),
              ],
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('auth-submit'),
                onPressed: busy ? null : submit,
                child: Text(
                  busy
                      ? 'กำลังดำเนินการ…'
                      : widget.register
                      ? 'สมัครสมาชิก'
                      : 'เข้าสู่ระบบ',
                ),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () =>
                          context.go(widget.register ? '/login' : '/register'),
                child: Text(
                  widget.register
                      ? 'มีบัญชีแล้ว เข้าสู่ระบบ'
                      : 'ยังไม่มีบัญชี สมัครสมาชิก',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
