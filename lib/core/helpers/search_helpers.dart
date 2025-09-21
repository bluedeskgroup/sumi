List<String> generateKeywords(String text) {
  if (text.isEmpty) return [];
  final words = text.toLowerCase().split(RegExp(r'[\s,]+')); // Split by space or comma
  final keywords = <String>{};
  for (var word in words) {
    if (word.isNotEmpty) {
      // Add substrings for prefix matching
      for (int i = 1; i <= word.length; i++) {
        keywords.add(word.substring(0, i));
      }
      // Add the full word
      keywords.add(word);
    }
  }
  return keywords.toList();
} 