import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/server_config_dialog.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale =
        ref
            .watch(appLocaleProvider)
            .when(
              data: (locale) => locale,
              loading: () => null,
              error: (_, _) => null,
            ) ??
        Localizations.localeOf(context);
    final isAr = l.isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(l.text('settings'))),
      body: QaPageFrame(
        child: ListView(
          children: [
            SectionHeader(title: l.text('language')),
            const SizedBox(height: 10),
            QaCard(
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'en', label: Text(l.text('english'))),
                    ButtonSegment(value: 'ar', label: Text(l.text('arabic'))),
                  ],
                  selected: {locale.languageCode},
                  onSelectionChanged: (values) => ref
                      .read(appLocaleProvider.notifier)
                      .select(Locale(values.first)),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SectionHeader(
              title: isAr ? 'الاتصال بالسيرفر والشبكة' : 'Server & Network',
            ),
            const SizedBox(height: 10),
            _ServerConfigCard(isArabic: isAr),
            const SizedBox(height: 22),
            SectionHeader(title: l.text('accessibility')),
            const SizedBox(height: 10),
            QaCard(
              child: _infoTile(
                Icons.text_fields_rounded,
                AppTheme.blue,
                l.text('textSize'),
                l.text('textSizeMessage'),
              ),
            ),
            const SizedBox(height: 22),
            SectionHeader(title: l.text('privacy')),
            const SizedBox(height: 10),
            QaCard(
              child: _infoTile(
                Icons.privacy_tip_outlined,
                AppTheme.mintTeal,
                l.text('privacy'),
                l.text('privacyMessage'),
              ),
            ),
            const SizedBox(height: 22),
            SectionHeader(title: l.text('about')),
            const SizedBox(height: 10),
            QaCard(
              child: _infoTile(
                Icons.health_and_safety_outlined,
                AppTheme.navyBlue,
                l.text('about'),
                l.text('aboutMessage'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  l.text('version'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navyBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(
    IconData icon,
    Color accent,
    String title,
    String subtitle,
  ) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: accent, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ServerConfigCard extends StatefulWidget {
  const _ServerConfigCard({required this.isArabic});
  final bool isArabic;

  @override
  State<_ServerConfigCard> createState() => _ServerConfigCardState();
}

class _ServerConfigCardState extends State<_ServerConfigCard> {
  bool _testing = false;
  String? _statusMessage;
  bool? _isConnected;

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _statusMessage = null;
    });

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(milliseconds: 3500),
          receiveTimeout: const Duration(milliseconds: 3500),
        ),
      );
      final response = await dio.get<dynamic>('/actuator/health');
      if (mounted) {
        setState(() {
          _testing = false;
          _isConnected = response.statusCode == 200;
          _statusMessage = widget.isArabic
              ? 'متصل بالسيرفر بنجاح أونلاين (HTTP 200)'
              : 'Connected to server successfully (HTTP 200)';
        });
      }
    } catch (e) {
      if (mounted) {
        if (e is DioException && e.response != null) {
          setState(() {
            _testing = false;
            _isConnected = true;
            _statusMessage = widget.isArabic
                ? 'متصل بالسيرفر بنجاح (HTTP ${e.response?.statusCode})'
                : 'Connected to server successfully (HTTP ${e.response?.statusCode})';
          });
          return;
        }
        setState(() {
          _testing = false;
          _isConnected = false;
          _statusMessage = widget.isArabic
              ? 'تعذر الوصول للسيرفر. تأكد أن السيرفر يعمل وعدّل الرابط إذا تغيّر.'
              : 'Cannot reach server. Ensure server is running and update URL.';
        });
      }
    }
  }

  void _showEditUrlDialog() {
    showServerConfigDialog(
      context,
      isArabic: widget.isArabic,
      onSaved: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.dns_rounded,
                  color: AppTheme.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isArabic
                          ? 'عنوان خادم البيانات (Backend API)'
                          : 'Backend API Server',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppConfig.apiBaseUrl,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: widget.isArabic ? 'تعديل' : 'Edit',
                onPressed: _showEditUrlDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Online connectivity note for mobile
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.sky,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.public_rounded, size: 16, color: AppTheme.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isArabic
                        ? 'ملاحظة: السيرفر متصل أونلاين ويعمل من أي شبكة (بيانات الهاتف 4G/5G أو أي Wi-Fi).'
                        : 'Note: Server connects online and works from any network (4G/5G data or any Wi-Fi).',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  _isConnected == true
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  size: 16,
                  color: _isConnected == true
                      ? AppTheme.success
                      : AppTheme.emergencyRed,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _statusMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isConnected == true
                          ? AppTheme.success
                          : AppTheme.emergencyRed,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _testing ? null : _testConnection,
              icon: _testing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.network_check_rounded, size: 18),
              label: Text(
                _testing
                    ? (widget.isArabic ? 'جاري الفحص...' : 'Testing...')
                    : (widget.isArabic
                          ? 'فحص الاتصال بالسيرفر (Test Ping)'
                          : 'Test Server Connection'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
