import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:sumi/features/community/presentation/pages/hashtag_posts_page.dart';
import 'package:sumi/l10n/app_localizations.dart';

class HashtagWidget extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const HashtagWidget({
    super.key,
    required this.text,
    this.textStyle,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: _buildTextSpan(context),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }

  TextSpan _buildTextSpan(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isArabic = localizations.localeName == 'ar';
    
    final regex = RegExp(r'#[\u0600-\u06FFa-zA-Z0-9_]+');
    final matches = regex.allMatches(text);
    
    if (matches.isEmpty) {
      return TextSpan(
        text: text,
        style: textStyle,
      );
    }

    List<TextSpan> spans = [];
    int lastIndex = 0;

    for (final match in matches) {
      // إضافة النص العادي قبل الهاشتاغ
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: textStyle,
        ));
      }

      // إضافة الهاشتاغ كرابط قابل للنقر
      final hashtag = match.group(0)!;
      spans.add(TextSpan(
        text: hashtag,
        style: textStyle?.copyWith(
          color: const Color(0xFF1AB385),
          fontWeight: FontWeight.w600,
        ) ?? const TextStyle(
          color: Color(0xFF1AB385),
          fontWeight: FontWeight.w600,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _navigateToHashtag(context, hashtag),
      ));

      lastIndex = match.end;
    }

    // إضافة النص المتبقي
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: textStyle,
      ));
    }

    return TextSpan(children: spans);
  }

  void _navigateToHashtag(BuildContext context, String hashtag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HashtagPostsPage(hashtag: hashtag),
      ),
    );
  }
}