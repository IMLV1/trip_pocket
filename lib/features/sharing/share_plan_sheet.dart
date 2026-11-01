// หน้าตัวอย่างข้อความแชร์ และการเปิด share sheet ของระบบ

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/widgets.dart';

class PlatformShareService {
  Future<void> share(String text, Rect origin) async {
    await SharePlus.instance.share(
      ShareParams(text: text, sharePositionOrigin: origin),
    );
  }
}

class SharePlanSheet extends StatefulWidget {
  final String text;
  final bool cached;
  final PlatformShareService? service;
  const SharePlanSheet({
    super.key,
    required this.text,
    required this.cached,
    this.service,
  });
  @override
  State<SharePlanSheet> createState() => _SharePlanSheetState();
}

class _SharePlanSheetState extends State<SharePlanSheet> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: Text('ตัวอย่างแผนที่จะแชร์')),
              IconButton(
                onPressed: busy ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          if (widget.cached)
            const Text('ใช้ข้อมูลที่โหลดไว้ล่าสุด อาจยังไม่เป็นปัจจุบัน'),
          Flexible(
            child: SingleChildScrollView(child: SelectableText(widget.text)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    try {
                      final box = context.findRenderObject()! as RenderBox;
                      await (widget.service ?? PlatformShareService()).share(
                        widget.text,
                        box.localToGlobal(Offset.zero) & box.size,
                      );
                    } catch (e) {
                      if (context.mounted) showError(context, e);
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
            child: Text(busy ? 'กำลังเปิด…' : 'เลือกแอปที่จะแชร์'),
          ),
        ],
      ),
    ),
  );
}
