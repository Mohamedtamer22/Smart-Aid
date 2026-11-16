import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/settings/settings_controller.dart';

/// One-tap bilingual language switcher accessible across all user roles.
class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({super.key, this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final isArabic = currentLocale == 'ar';

    if (isCompact) {
      return IconButton(
        onPressed: () => ref.read(appLocaleProvider.notifier).toggle(),
        icon: const Icon(Icons.language_rounded),
        tooltip: isArabic ? 'Switch to English' : 'التحويل إلى العربية',
      );
    }

    return Tooltip(
      message: isArabic ? 'Switch to English' : 'التحويل إلى العربية',
      child: InkWell(
        onTap: () => ref.read(appLocaleProvider.notifier).toggle(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.translate_rounded, size: 16),
              const SizedBox(width: 6),
              Text(
                isArabic ? 'English' : 'العربية',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
