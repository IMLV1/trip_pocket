// widget กลาง: แสดงสถานะโหลด/ผิดพลาด, ยืนยันการลบ, แจ้ง error
// โครงหน้าแบบเลื่อน และหน้าที่ใช้เมื่อหาข้อมูลไม่พบ

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'errors.dart';

class AsyncContent<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T) data;
  final VoidCallback retry;
  final String? screenTitle;
  const AsyncContent({
    super.key,
    required this.value,
    required this.data,
    required this.retry,
    this.screenTitle,
  });
  @override
  Widget build(BuildContext context) => value.when(
    skipLoadingOnRefresh: false,
    data: data,
    loading: () => frame(
      const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
    ),
    error: (e, s) => frame(
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorText(e)),
            TextButton(onPressed: retry, child: const Text('ลองใหม่')),
          ],
        ),
      ),
    ),
  );

  Widget frame(Widget child) => screenTitle == null
      ? child
      : Scaffold(
          appBar: AppBar(title: Text(screenTitle!)),
          body: Center(child: child),
        );
}

Future<bool> confirmDelete(BuildContext context, String title) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: const Text('เมื่อลบแล้วจะกู้คืนไม่ได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    ) ??
    false;
void showError(BuildContext context, Object error) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(errorText(error))));

class PageBody extends StatelessWidget {
  final List<Widget> children;
  const PageBody({super.key, required this.children});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: children,
      ),
    ),
  );
}

class UnavailablePage extends StatelessWidget {
  final String title, message;
  final VoidCallback onExit;
  const UnavailablePage({
    super.key,
    required this.title,
    required this.message,
    required this.onExit,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          TextButton(onPressed: onExit, child: const Text('กลับรายการทริป')),
        ],
      ),
    ),
  );
}
