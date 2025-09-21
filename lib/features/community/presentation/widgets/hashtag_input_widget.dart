import 'package:flutter/material.dart';
import 'package:sumi/features/community/models/hashtag_model.dart';
import 'package:sumi/features/community/services/hashtag_service.dart';
import 'package:sumi/l10n/app_localizations.dart';

class HashtagInputWidget extends StatefulWidget {
  final TextEditingController textController;
  final FocusNode? focusNode;
  final Function(List<String>)? onHashtagsChanged;

  const HashtagInputWidget({
    super.key,
    required this.textController,
    this.focusNode,
    this.onHashtagsChanged,
  });

  @override
  State<HashtagInputWidget> createState() => _HashtagInputWidgetState();
}

class _HashtagInputWidgetState extends State<HashtagInputWidget> {
  final HashtagService _hashtagService = HashtagService();
  List<HashtagModel> _suggestions = [];
  bool _showSuggestions = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.textController.text;
    final hashtags = _hashtagService.extractHashtags(text);
    
    // إشعار التطبيق بالهاشتاغات الجديدة
    widget.onHashtagsChanged?.call(hashtags);
    
    // البحث عن اقتراحات الهاشتاغات
    _searchHashtags(text);
  }

  Future<void> _searchHashtags(String text) async {
    // العثور على الكلمة الحالية التي يكتبها المستخدم
    final cursorPosition = widget.textController.selection.baseOffset;
    if (cursorPosition < 0) return;

    final words = text.substring(0, cursorPosition).split(' ');
    final currentWord = words.isNotEmpty ? words.last : '';

    if (currentWord.startsWith('#') && currentWord.length > 1) {
      final query = currentWord.substring(1); // إزالة رمز #
      
      try {
        final suggestions = await _hashtagService.searchHashtags(query);
        setState(() {
          _suggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
        });
        
        if (_showSuggestions) {
          _showSuggestionsOverlay();
        } else {
          _removeOverlay();
        }
      } catch (e) {
        print('خطأ في البحث عن الهاشتاغات: $e');
      }
    } else {
      _hideSuggestions();
    }
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final hashtag = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.tag,
                      color: Color(0xFF1AB385),
                      size: 20,
                    ),
                    title: Text(
                      hashtag.tag,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1AB385),
                      ),
                    ),
                    subtitle: Text(
                      '${hashtag.count} منشور',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () => _selectHashtag(hashtag.tag),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _selectHashtag(String hashtag) {
    final text = widget.textController.text;
    final cursorPosition = widget.textController.selection.baseOffset;
    
    // العثور على بداية الكلمة الحالية
    int wordStart = cursorPosition;
    while (wordStart > 0 && text[wordStart - 1] != ' ') {
      wordStart--;
    }
    
    // استبدال الكلمة الحالية بالهاشتاغ المحدد
    final newText = text.substring(0, wordStart) + 
                   hashtag + 
                   ' ' + 
                   text.substring(cursorPosition);
    
    widget.textController.text = newText;
    widget.textController.selection = TextSelection.fromPosition(
      TextPosition(offset: wordStart + hashtag.length + 1),
    );
    
    _hideSuggestions();
  }

  void _hideSuggestions() {
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isArabic = localizations.localeName == 'ar';

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // إرشادات الهاشتاغات
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1AB385).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF1AB385),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isArabic 
                        ? 'استخدم # لإضافة هاشتاغات لمنشورك (مثل #تقنية #برمجة)'
                        : 'Use # to add hashtags to your post (like #tech #programming)',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 12,
                      color: Color(0xFF1AB385),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // عرض الهاشتاغات المستخرجة
          if (widget.textController.text.isNotEmpty)
            _buildExtractedHashtags(isArabic),
        ],
      ),
    );
  }

  Widget _buildExtractedHashtags(bool isArabic) {
    final hashtags = _hashtagService.extractHashtags(widget.textController.text);
    
    if (hashtags.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'الهاشتاغات في منشورك:' : 'Hashtags in your post:',
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: hashtags.map((hashtag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1AB385),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hashtag,
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}