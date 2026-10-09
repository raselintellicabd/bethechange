enum LiveChatStatus {
  none,
  waiting,
  active,
  ended;

  bool get isOpen => this == waiting || this == active;

  static LiveChatStatus parse(Object? raw) {
    return switch ('${raw ?? ''}'.trim()) {
      'waiting' => waiting,
      'active' => active,
      'ended' => ended,
      _ => none,
    };
  }
}

enum LiveChatSender {
  visitor,
  staff,
  system;

  static LiveChatSender parse(Object? raw) {
    return switch ('${raw ?? ''}'.trim()) {
      'visitor' => visitor,
      'staff' => staff,
      _ => system,
    };
  }
}

class LiveChatMessage {
  const LiveChatMessage({
    required this.id,
    required this.sender,
    required this.body,
    this.author = '',
    this.time = '',
  });

  final int id;
  final LiveChatSender sender;
  final String author;
  final String body;

  /// Clinic-local time label from the server, e.g. "3:17 PM".
  final String time;

  factory LiveChatMessage.fromJson(Map<String, dynamic> json) {
    return LiveChatMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      sender: LiveChatSender.parse(json['sender']),
      author: '${json['author'] ?? ''}'.trim(),
      body: '${json['body'] ?? ''}',
      time: '${json['time'] ?? ''}'.trim(),
    );
  }
}

/// One response from the live chat API (`start`, `state`, `send`, `end`).
/// [messages] holds only messages newer than the `since` id that was sent.
class LiveChatSnapshot {
  const LiveChatSnapshot({
    required this.status,
    this.token,
    this.staffName = '',
    this.fallback = false,
    this.messages = const [],
  });

  final LiveChatStatus status;

  /// Only returned by `start`.
  final String? token;
  final String staffName;

  /// Still waiting after the server's fallback window: the team will reply by email.
  final bool fallback;
  final List<LiveChatMessage> messages;

  factory LiveChatSnapshot.fromJson(Map<String, dynamic> json) {
    final token = '${json['token'] ?? ''}'.trim();
    return LiveChatSnapshot(
      status: LiveChatStatus.parse(json['status']),
      token: token.isEmpty ? null : token,
      staffName: '${json['staff_name'] ?? ''}'.trim(),
      fallback: json['fallback'] == true,
      messages: (json['messages'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => LiveChatMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
