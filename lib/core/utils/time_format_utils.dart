/// Utility functions for formatting time and date strings
library;

/// Format last active time as "Active Xm/h/d ago" or "Active last week/month"
String formatLastActive(DateTime? lastActive) {
  if (lastActive == null) return 'Active recently';

  final now = DateTime.now();
  final difference = now.difference(lastActive);

  if (difference.inSeconds < 60) {
    return 'Active just now';
  } else if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;
    return 'Active ${minutes}m ago';
  } else if (difference.inHours < 24) {
    final hours = difference.inHours;
    return 'Active ${hours}h ago';
  } else if (difference.inDays == 1) {
    return 'Active yesterday';
  } else if (difference.inDays < 7) {
    return 'Active ${difference.inDays}d ago';
  } else if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return weeks == 1 ? 'Active last week' : 'Active ${weeks}w ago';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return months == 1 ? 'Active last month' : 'Active ${months}mo ago';
  } else {
    return 'Active long ago';
  }
}

/// Format time ago as "5m ago", "3h ago", "2d ago"
String formatTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  } else if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return '${weeks}w ago';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return '${months}mo ago';
  } else {
    final years = (difference.inDays / 365).floor();
    return '${years}y ago';
  }
}

/// Format timestamp for messages/chats
String formatMessageTime(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inMinutes < 1) {
    return 'Just now';
  } else if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inDays < 1) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  } else if (difference.inDays < 7) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[timestamp.weekday - 1];
  } else {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}

/// Format duration in seconds to "MM:SS" or "HH:MM:SS"
String formatDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  } else {
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

/// Format full date based on how recent it is
String formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays == 0) {
    return 'Today';
  } else if (difference.inDays == 1) {
    return 'Yesterday';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else {
    return '${date.day}/${date.month}/${date.year}';
  }
}
