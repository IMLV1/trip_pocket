// Sign-in and registration screen. Both share one widget; after success the
// session change rebuilds the router, so no navigation happens here.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/validation.dart';
import '../../core/errors.dart';
import '../../core/widgets.dart';
import '../../core/design_system.dart';

/// Sign-in form, or registration when [register] is true.
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
  bool busy = false, obscure = true;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  /// Validates, then signs in or registers.
  ///
  /// No navigation here: the session change rebuilds the router.
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

  /// Signs in with Google.
  Future<void> googleLogin() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
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
        if (MediaQuery.sizeOf(context).height < 650 ||
            MediaQuery.viewInsetsOf(context).bottom > 0)
          const FormIntro(
            'ไปเที่ยวกันเถอะ',
            'แผนดี ๆ เริ่มต้นที่นี่',
            icon: Icons.explore_outlined,
          )
        else
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: TripColors.ink,
              borderRadius: BorderRadius.circular(28),
            ),
            child: CustomPaint(
              painter: const RouteMotif(),
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.explore_outlined,
                      color: TripColors.accent,
                      size: 36,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      widget.register
                          ? 'เริ่มวางแผนทริปแรก'
                          : 'ทุกทริป เริ่มจาก\nแผนดี ๆ',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ค้นพบจุดหมาย วางแผนเที่ยว\nและเก็บความทรงจำทั่วไทย',
                      style: TextStyle(color: Color(0xffcedfd6)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        SectionTitle(
          widget.register ? 'สร้างบัญชีของคุณ' : 'ยินดีต้อนรับกลับมา',
        ),
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
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'อีเมล',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: emailError,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('password'),
                controller: password,
                enabled: !busy,
                obscureText: obscure,
                textInputAction: widget.register
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (!widget.register) submit();
                },
                decoration: InputDecoration(
                  labelText: 'รหัสผ่าน',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: obscure ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                    onPressed: () => setState(() => obscure = !obscure),
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: passwordError,
              ),
              if (!widget.register)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('forgot-password'),
                    onPressed: busy
                        ? null
                        : () => context.push('/forgot-password'),
                    child: const Text('ลืมรหัสผ่าน?'),
                  ),
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
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('google-sign-in'),
                onPressed: busy ? null : googleLogin,
                icon: const Icon(Icons.account_circle_outlined),
                label: const Text('เข้าสู่ระบบด้วย Google'),
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
