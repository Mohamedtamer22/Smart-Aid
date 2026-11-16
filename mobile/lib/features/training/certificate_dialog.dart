import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// Displays an official, accredited certificate of completion dialog.
void showOfficialCertificate(
  BuildContext context, {
  required String recipientName,
  required String courseTitle,
  required double score,
  DateTime? date,
  String? certificateId,
  bool isArabic = true,
}) {
  final issueDate = date ?? DateTime.now();
  final certId = certificateId ??
      'SA-CERT-${issueDate.year}-${(courseTitle.hashCode.abs() % 9000 + 1000)}';

  showDialog<void>(
    context: context,
    builder: (dialogCtx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: _CertificateCard(
        recipientName: recipientName.trim().isEmpty ? 'Mohamed Tamer' : recipientName.trim(),
        courseTitle: courseTitle,
        score: score,
        issueDate: issueDate,
        certId: certId,
        isArabic: isArabic,
      ),
    ),
  );
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({
    required this.recipientName,
    required this.courseTitle,
    required this.score,
    required this.issueDate,
    required this.certId,
    required this.isArabic,
  });

  final String recipientName;
  final String courseTitle;
  final double score;
  final DateTime issueDate;
  final String certId;
  final bool isArabic;

  String _formatDate(DateTime dt) {
    const monthsAr = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    const monthsEn = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (isArabic) {
      return '${dt.day} ${monthsAr[dt.month - 1]} ${dt.year} م';
    }
    return '${monthsEn[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFC5A059);
    const darkGold = Color(0xFF9A7B38);
    const navyColor = Color(0xFF0F1E36);
    const creamBg = Color(0xFFFDFBF7);

    return Container(
      constraints: const BoxConstraints(maxWidth: 580),
      decoration: BoxDecoration(
        color: creamBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Outer Certificate Border Frame
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  border: Border.all(color: goldColor, width: 2.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: goldColor.withValues(alpha: 0.45), width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Header Crest / Logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.workspace_premium, color: goldColor, size: 28),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              Text(
                                isArabic
                                    ? 'منصة المساعد الذكي للإسعاف والطوارئ'
                                    : 'SMART AID EMERGENCY MEDICAL PLATFORM',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: navyColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                isArabic
                                    ? 'هيئة التدريب والتأهيل الطبي الميداني المعتمد'
                                    : 'Accredited Field Medical & Emergency Response Board',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.verified, color: goldColor, size: 28),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Certificate Ribbon Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [darkGold, goldColor, darkGold],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: goldColor.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          isArabic
                              ? '★ شهادة إتمام واجتياز معتمدة ★'
                              : '★ OFFICIAL CERTIFICATE OF COMPLETION ★',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Presented to
                      Text(
                        isArabic
                            ? 'تشهد إدارة منصة Smart Aid بأن المتدرب:'
                            : 'This is to officially certify that:',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF555555),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Recipient Name
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: goldColor, width: 2),
                          ),
                        ),
                        child: Text(
                          recipientName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: navyColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Statement
                      Text(
                        isArabic
                            ? 'قد أتم بنجاح واقتدار كافة متطلبات الدورة التدريبية واجتاز الاختبار التخصصي في:'
                            : 'Has successfully fulfilled all curriculum requirements and passed the certified assessment in:',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF444444),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Course Title Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EEDF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: goldColor.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              courseTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: navyColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star, color: goldColor, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  isArabic
                                      ? 'النتيجة: ${score.toStringAsFixed(0)}% (ممتاز مع مرتبة الشرف)'
                                      : 'Grade: ${score.toStringAsFixed(0)}% (Passed with Distinction)',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E6F3D),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Date and Serial ID
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                '${isArabic ? 'تاريخ الاعتماد: ' : 'Date: '}${_formatDate(issueDate)}',
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF666666)),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.qr_code_2, size: 13, color: goldColor),
                              const SizedBox(width: 4),
                              Text(
                                certId,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  color: navyColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Divider with Central Gold Seal
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const Divider(color: goldColor, thickness: 1),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: creamBg,
                              border: Border.all(color: goldColor, width: 1.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_user, color: darkGold, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  isArabic ? 'الاعتماد والمصادقة الرسمية' : 'OFFICIAL ENDORSEMENT',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: darkGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Dual Official Signatures (Eng. Mohamed Tamer & Eng. Mohamed Mahmoud)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Signer 1: ENG / Mohamed Tamer
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Mohamed Tamer',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: darkGold,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                Container(
                                  width: 120,
                                  height: 1,
                                  color: goldColor.withValues(alpha: 0.7),
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                ),
                                const Text(
                                  'ENG / Mohamed Tamer',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: navyColor,
                                  ),
                                ),
                                Text(
                                  isArabic
                                      ? 'مؤسس المنصة ورئيس النظم'
                                      : 'Lead Systems Architect & Co-Founder',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Central Seal Stamp
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: goldColor, width: 2),
                              color: const Color(0xFFF6F0DC),
                              boxShadow: [
                                BoxShadow(
                                  color: goldColor.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.shield_outlined, color: darkGold, size: 24),
                            ),
                          ),
                          // Signer 2: ENG / Mohamed Mahmoud
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Mohamed Mahmoud',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: darkGold,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                Container(
                                  width: 120,
                                  height: 1,
                                  color: goldColor.withValues(alpha: 0.7),
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                ),
                                const Text(
                                  'ENG / Mohamed Mahmoud',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: navyColor,
                                  ),
                                ),
                                Text(
                                  isArabic
                                      ? 'مؤسس المنصة والعمليات الطبية'
                                      : 'Medical Operations & Co-Founder',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: navyColor,
                          side: const BorderSide(color: goldColor),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: Text(
                          isArabic ? 'نسخ بيانات الاعتماد' : 'Copy Verification',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          final text = 'Smart Aid Certified Training\nRecipient: $recipientName\nCourse: $courseTitle\nScore: ${score.toStringAsFixed(0)}%\nSerial: $certId\nCertified By: ENG/Mohamed Tamer & ENG/Mohamed Mahmoud';
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isArabic
                                    ? 'تم نسخ بيانات ورقم الشهادة المعتمدة بنجاح!'
                                    : 'Certificate details copied to clipboard!',
                              ),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: navyColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(isArabic ? 'إغلاق' : 'Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
