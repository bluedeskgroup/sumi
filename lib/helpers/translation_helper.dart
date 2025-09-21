import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/translation_service.dart';

/// مساعد للوصول السريع للترجمات في التطبيق
class TranslationHelper {
  /// الحصول على نص مترجم من السياق
  static String getText(BuildContext context, String key, {String? fallback}) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final translationService = Provider.of<TranslationService>(context, listen: false);
    return translationService.getText(key, isArabic: isArabic, fallback: fallback);
  }

  /// الحصول على نص مترجم مع تحديد اللغة
  static String getTextWithLanguage(BuildContext context, String key, bool isArabic, {String? fallback}) {
    final translationService = Provider.of<TranslationService>(context, listen: false);
    return translationService.getText(key, isArabic: isArabic, fallback: fallback);
  }

  /// ويدجت لعرض النص المترجم مع تحديث تلقائي
  static Widget buildText(
    String key, {
    String? fallback,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Builder(
      builder: (context) {
        return Consumer<TranslationService>(
          builder: (context, translationService, child) {
            final isArabic = Directionality.of(context) == TextDirection.rtl;
            final text = translationService.getText(key, isArabic: isArabic, fallback: fallback);
            
            return Text(
              text,
              style: style,
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: overflow,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            );
          },
        );
      },
    );
  }

  /// ويدجت للعنوان في AppBar مع تحديث تلقائي
  static Widget buildAppBarTitle(String key, {String? fallback, TextStyle? style}) {
    return Builder(
      builder: (context) {
        return Consumer<TranslationService>(
          builder: (context, translationService, child) {
            final isArabic = Directionality.of(context) == TextDirection.rtl;
            final text = translationService.getText(key, isArabic: isArabic, fallback: fallback);
            
            return Text(
              text,
              style: style ?? const TextStyle(
                fontFamily: 'Almarai',
                fontWeight: FontWeight.bold,
              ),
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            );
          },
        );
      },
    );
  }

  /// ويدجت للأزرار مع نص مترجم
  static Widget buildElevatedButton({
    required String textKey,
    required VoidCallback onPressed,
    String? fallback,
    ButtonStyle? style,
    IconData? icon,
  }) {
    return Builder(
      builder: (context) {
        return Consumer<TranslationService>(
          builder: (context, translationService, child) {
            final isArabic = Directionality.of(context) == TextDirection.rtl;
            final text = translationService.getText(textKey, isArabic: isArabic, fallback: fallback);
            
            if (icon != null) {
              return ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(
                  text,
                  style: const TextStyle(fontFamily: 'Almarai'),
                ),
                style: style,
              );
            } else {
              return ElevatedButton(
                onPressed: onPressed,
                style: style,
                child: Text(
                  text,
                  style: const TextStyle(fontFamily: 'Almarai'),
                ),
              );
            }
          },
        );
      },
    );
  }

  /// ويدجت لحقول الإدخال مع تسميات مترجمة
  static Widget buildTextField({
    required String labelKey,
    required String hintKey,
    TextEditingController? controller,
    String? labelFallback,
    String? hintFallback,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLines = 1,
    InputDecoration? decoration,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return Builder(
      builder: (context) {
        return Consumer<TranslationService>(
          builder: (context, translationService, child) {
            final isArabic = Directionality.of(context) == TextDirection.rtl;
            final labelText = translationService.getText(labelKey, isArabic: isArabic, fallback: labelFallback);
            final hintText = translationService.getText(hintKey, isArabic: isArabic, fallback: hintFallback);
            
            return TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              maxLines: maxLines,
              onChanged: onChanged,
              validator: validator,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              decoration: decoration?.copyWith(
                labelText: labelText,
                hintText: hintText,
              ) ?? InputDecoration(
                labelText: labelText,
                hintText: hintText,
                labelStyle: const TextStyle(fontFamily: 'Almarai'),
                hintStyle: const TextStyle(fontFamily: 'Almarai'),
                border: const OutlineInputBorder(),
              ),
              style: const TextStyle(fontFamily: 'Almarai'),
            );
          },
        );
      },
    );
  }

  /// عرض رسالة SnackBar مترجمة
  static void showTranslatedSnackBar(
    BuildContext context,
    String messageKey, {
    String? fallback,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final translationService = Provider.of<TranslationService>(context, listen: false);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final message = translationService.getText(messageKey, isArabic: isArabic, fallback: fallback);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Almarai'),
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        ),
        duration: duration,
        action: action,
      ),
    );
  }

  /// عرض حوار تأكيد مترجم
  static Future<bool?> showTranslatedConfirmDialog(
    BuildContext context,
    String titleKey,
    String contentKey, {
    String? titleFallback,
    String? contentFallback,
    String confirmKey = 'confirm',
    String cancelKey = 'cancel',
  }) async {
    final translationService = Provider.of<TranslationService>(context, listen: false);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    
    final title = translationService.getText(titleKey, isArabic: isArabic, fallback: titleFallback);
    final content = translationService.getText(contentKey, isArabic: isArabic, fallback: contentFallback);
    final confirm = translationService.getText(confirmKey, isArabic: isArabic, fallback: 'تأكيد');
    final cancel = translationService.getText(cancelKey, isArabic: isArabic, fallback: 'إلغاء');
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Almarai'),
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        ),
        content: Text(
          content,
          style: const TextStyle(fontFamily: 'Almarai'),
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              cancel,
              style: const TextStyle(fontFamily: 'Almarai'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirm,
              style: const TextStyle(fontFamily: 'Almarai'),
            ),
          ),
        ],
      ),
    );
  }
}

/// اختصارات للوصول السريع للترجمات الشائعة
class T {
  /// مفاتيح الترجمة الأساسية
  static const String appName = 'app_name';
  static const String welcome = 'welcome';
  static const String save = 'save';
  static const String cancel = 'cancel';
  static const String edit = 'edit';
  static const String delete = 'delete';
  static const String search = 'search';
  static const String confirm = 'confirm';
  static const String loading = 'loading';
  static const String error = 'error';
  static const String success = 'success';
  static const String jobVacancies = 'job_vacancies';
  static const String noJobsAvailable = 'no_jobs_available';
  static const String apply = 'apply';
  static const String viewDetails = 'view_details';
  static const String back = 'back';
  static const String next = 'next';
  static const String finish = 'finish';
  static const String retry = 'retry';
  
  /// الحصول على نص مترجم
  static String get(BuildContext context, String key, {String? fallback}) {
    return TranslationHelper.getText(context, key, fallback: fallback);
  }
  
  /// ويدجت نص مترجم
  static Widget text(String key, {String? fallback, TextStyle? style}) {
    return TranslationHelper.buildText(key, fallback: fallback, style: style);
  }
}
