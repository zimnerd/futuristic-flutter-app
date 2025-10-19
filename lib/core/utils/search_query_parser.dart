/// Parser for advanced search query syntax
///
/// Supports:
/// - "quoted phrases" for exact matches
/// - sender:username to filter by sender
/// - before:YYYY-MM-DD to filter messages before date
/// - after:YYYY-MM-DD to filter messages after date
///
/// Example:
/// ```dart
/// final parser = SearchQueryParser();
/// final parsed = parser.parse('"hello world" sender:john after:2024-01-01');
/// // parsed.phrases: ['hello world']
/// // parsed.sender: 'john'
/// // parsed.afterDate: DateTime(2024, 1, 1)
/// // parsed.remainingQuery: ''
/// ```
class SearchQueryParser {
  /// Parse a search query string into structured components
  ParsedSearchQuery parse(String query) {
    final phrases = <String>[];
    String? sender;
    DateTime? beforeDate;
    DateTime? afterDate;
    String remainingQuery = query;

    // Extract quoted phrases: "exact match"
    final phraseRegex = RegExp(r'"([^"]+)"');
    final phraseMatches = phraseRegex.allMatches(query);
    for (final match in phraseMatches) {
      phrases.add(match.group(1)!);
      remainingQuery = remainingQuery.replaceFirst(match.group(0)!, '');
    }

    // Extract sender: sender:username
    final senderRegex = RegExp(r'sender:(\S+)');
    final senderMatch = senderRegex.firstMatch(remainingQuery);
    if (senderMatch != null) {
      sender = senderMatch.group(1);
      remainingQuery = remainingQuery.replaceFirst(senderMatch.group(0)!, '');
    }

    // Extract before date: before:YYYY-MM-DD
    final beforeRegex = RegExp(r'before:(\d{4}-\d{2}-\d{2})');
    final beforeMatch = beforeRegex.firstMatch(remainingQuery);
    if (beforeMatch != null) {
      try {
        beforeDate = DateTime.parse(beforeMatch.group(1)!);
        remainingQuery = remainingQuery.replaceFirst(beforeMatch.group(0)!, '');
      } catch (_) {
        // Invalid date format - ignore
      }
    }

    // Extract after date: after:YYYY-MM-DD
    final afterRegex = RegExp(r'after:(\d{4}-\d{2}-\d{2})');
    final afterMatch = afterRegex.firstMatch(remainingQuery);
    if (afterMatch != null) {
      try {
        afterDate = DateTime.parse(afterMatch.group(1)!);
        remainingQuery = remainingQuery.replaceFirst(afterMatch.group(0)!, '');
      } catch (_) {
        // Invalid date format - ignore
      }
    }

    // Clean up remaining query (remove extra whitespace)
    remainingQuery = remainingQuery.trim().replaceAll(RegExp(r'\s+'), ' ');

    return ParsedSearchQuery(
      phrases: phrases,
      sender: sender,
      beforeDate: beforeDate,
      afterDate: afterDate,
      remainingQuery: remainingQuery,
      originalQuery: query,
    );
  }
}

/// Structured representation of a parsed search query
class ParsedSearchQuery {
  /// Exact phrases to match (from "quoted text")
  final List<String> phrases;

  /// Filter by sender username/display name
  final String? sender;

  /// Filter messages before this date
  final DateTime? beforeDate;

  /// Filter messages after this date
  final DateTime? afterDate;

  /// Remaining query text after extracting special syntax
  final String remainingQuery;

  /// Original unparsed query
  final String originalQuery;

  const ParsedSearchQuery({
    required this.phrases,
    required this.sender,
    required this.beforeDate,
    required this.afterDate,
    required this.remainingQuery,
    required this.originalQuery,
  });

  /// Check if query has any special syntax
  bool get hasSpecialSyntax =>
      phrases.isNotEmpty ||
      sender != null ||
      beforeDate != null ||
      afterDate != null;

  /// Get the simplified query for backend search (without special syntax)
  String get simplifiedQuery {
    if (!hasSpecialSyntax) return originalQuery;
    
    // Combine phrases and remaining query
    final parts = <String>[];
    if (remainingQuery.isNotEmpty) parts.add(remainingQuery);
    parts.addAll(phrases);
    
    return parts.join(' ').trim();
  }

  @override
  String toString() {
    return 'ParsedSearchQuery('
        'phrases: $phrases, '
        'sender: $sender, '
        'beforeDate: $beforeDate, '
        'afterDate: $afterDate, '
        'remainingQuery: "$remainingQuery"'
        ')';
  }
}
