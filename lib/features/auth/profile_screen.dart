// Profile screen and avatar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/design_system.dart';
import '../../core/validation.dart';
import '../../core/widgets.dart';
import 'auth_repository.dart';

/// Shows an https photo, or the first letter of the name.
class ProfileAvatar extends StatelessWidget {
  final Session user;
  const ProfileAvatar({super.key, required this.user});
  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        (user.displayName?.trim().isNotEmpty == true
                ? user.displayName!
                : user.email)
            .characters
            .take(1)
            .toString()
            .toUpperCase(),
        style: const TextStyle(fontSize: 34, color: TripColors.primary),
      ),
    );
    final url = Uri.tryParse(user.photoUrl ?? '');
    return Semantics(
      label: 'รูปโปรไฟล์',
      image: true,
      child: Container(
        width: 88,
        height: 88,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: TripColors.mint,
        ),
        clipBehavior: Clip.antiAlias,
        child: url?.scheme == 'https'
            ? Image.network(
                url.toString(),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              )
            : fallback,
      ),
    );
  }
}

/// Edits the display name, Google link and password.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(
    text: ref.read(authRepositoryProvider).currentSession?.displayName,
  );
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  /// Saves the display name.
  Future<void> saveName() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await ref.read(authRepositoryProvider).updateDisplayName(name.text);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('บันทึกชื่อแล้ว')));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Links Google, or refreshes the photo if already linked.
  Future<void> connect() async {
    if (busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => busy = true);
    try {
      final linked = await ref
          .read(authRepositoryProvider)
          .connectGoogleProfile();
      if (linked && mounted) {
        if (name.text.trim().isEmpty) {
          name.text =
              ref.read(authRepositoryProvider).currentSession?.displayName ??
              '';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตรูปจาก Google แล้ว')),
        );
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
        appBar: AppBar(title: const Text('โปรไฟล์ของฉัน')),
        body: user == null
            ? const Center(child: Text('กรุณาเข้าสู่ระบบอีกครั้ง'))
            : PageBody(
                children: [
                  const FormIntro(
                    'บัญชีของคุณ',
                    'จัดการชื่อ รูปโปรไฟล์ และความปลอดภัย',
                    icon: Icons.manage_accounts_outlined,
                  ),
                  Center(child: ProfileAvatar(user: user)),
                  const SizedBox(height: 12),
                  Text(user.email, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          key: const Key('profile-name'),
                          controller: name,
                          enabled: !busy,
                          maxLength: 100,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => saveName(),
                          decoration: const InputDecoration(
                            labelText: 'ชื่อที่แสดง',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: textError,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          key: const Key('save-profile'),
                          onPressed: busy ? null : saveName,
                          child: Text(busy ? 'กำลังดำเนินการ…' : 'บันทึกชื่อ'),
                        ),
                      ],
                    ),
                  ),
                  const SectionTitle('รูปโปรไฟล์จาก Google'),
                  const Text(
                    'เชื่อมบัญชี Google ที่ใช้อีเมลเดียวกันเพื่อใช้รูปโปรไฟล์ แอปไม่อ่านอีเมล Gmail หรือรายชื่อติดต่อ',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('connect-google-profile'),
                    onPressed: busy ? null : connect,
                    icon: const Icon(Icons.account_circle_outlined),
                    label: Text(
                      user.googleLinked
                          ? 'อัปเดตรูปจาก Google'
                          : 'เชื่อมบัญชี Google เพื่อใช้รูป',
                    ),
                  ),
                  const SectionTitle('ความปลอดภัย'),
                  OutlinedButton.icon(
                    key: const Key('open-change-password'),
                    onPressed: busy
                        ? null
                        : () => context.push('/change-password'),
                    icon: const Icon(Icons.lock_reset_outlined),
                    label: const Text('เปลี่ยนรหัสผ่าน'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ข้อมูลทริปยังเป็นของบัญชีเดิม การแก้โปรไฟล์ไม่เปลี่ยนเจ้าของทริป',
                  ),
                ],
              ),
      ),
    );
  }
}
