import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';

/// Shows an interactive dialog allowing users or testers to configure the Backend server URL.
Future<void> showServerConfigDialog(
  BuildContext context, {
  required bool isArabic,
  VoidCallback? onSaved,
}) async {
  final controller = TextEditingController(text: AppConfig.apiBaseUrl);

  await showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.dns_rounded, color: AppTheme.blue, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isArabic ? 'إعدادات عنوان السيرفر' : 'Server Connection Settings',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'أدخل رابط السيرفر العام (Cloudflare Tunnel / Ngrok) أو عنوان IP المحلي:'
                  : 'Enter Public Tunnel URL (Cloudflare/Ngrok) or Local IP:',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'https://xxxx.trycloudflare.com',
                prefixIcon: const Icon(Icons.link_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste_rounded, size: 18),
                  tooltip: isArabic ? 'لصق من الحافظة' : 'Paste from clipboard',
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null && data!.text!.trim().isNotEmpty) {
                      controller.text = data.text!.trim();
                    }
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 14),
            Text(
              isArabic ? 'خيارات واختصارات سريعة:' : 'Quick Presets:',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.content_paste_go_rounded, size: 14),
                  label: Text(
                    isArabic ? 'لصق الرابط' : 'Paste URL',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null && data!.text!.trim().isNotEmpty) {
                      controller.text = data.text!.trim();
                    }
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.wifi, size: 14),
                  label: const Text('Wi-Fi / LAN', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = AppConfig.defaultBaseUrl,
                ),
                ActionChip(
                  avatar: const Icon(Icons.phone_android, size: 14),
                  label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://10.0.2.2:8080',
                ),
                ActionChip(
                  avatar: const Icon(Icons.laptop, size: 14),
                  label: const Text('Localhost', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://127.0.0.1:8080',
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final newUrl = controller.text.trim();
            if (newUrl.isNotEmpty) {
              await AppConfig.setBaseUrl(newUrl);
              onSaved?.call();
            }
            if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
          },
          child: Text(isArabic ? 'حفظ' : 'Save'),
        ),
      ],
    ),
  );
}
