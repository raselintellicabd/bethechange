import '../../../../core/router/app_routes.dart';
import '../../../appointment/domain/models/source_context.dart';
import '../../domain/models/chat_message.dart';

/// Where an assistant link opens inside the app.
class ChatbotLinkTarget {
  const ChatbotLinkTarget(this.path, {this.useGo = false});

  final String path;

  /// Tab destinations (inside the bottom-nav shell) are opened with `go`;
  /// everything else is pushed so Back returns to the chat.
  final bool useGo;

  @override
  bool operator ==(Object other) =>
      other is ChatbotLinkTarget && other.path == path && other.useGo == useGo;

  @override
  int get hashCode => Object.hash(path, useGo);

  @override
  String toString() => 'ChatbotLinkTarget($path, useGo: $useGo)';
}

/// Maps a website link from the assistant (`kind` + site-relative `url`) to an
/// app screen. Returns null when there is no matching screen; open it in the
/// browser instead.
ChatbotLinkTarget? chatbotLinkTarget(ChatbotLink link) {
  final uri = Uri.tryParse(link.url);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  final parts = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  final slug = parts.length == 1 ? parts.first : null;

  switch (link.kind.toLowerCase()) {
    case 'service':
      return slug == null
          ? null
          : ChatbotLinkTarget(AppRoutes.serviceDetailPath(slug));
    case 'condition':
      return slug == null
          ? null
          : ChatbotLinkTarget(AppRoutes.conditionDetailPath(slug));
    case 'blog':
      return slug == null
          ? null
          : ChatbotLinkTarget(AppRoutes.blogDetailPath(slug));
    case 'doctor':
    case 'about':
      if (parts.length == 2 && parts.first == 'about') {
        return ChatbotLinkTarget(
          AppRoutes.aboutSectionPath(parts[1]),
          useGo: true,
        );
      }
      if (slug == 'about') {
        return const ChatbotLinkTarget(AppRoutes.about, useGo: true);
      }
      // e.g. `/our-process/`, an About page outside `/about/` on the site.
      if (slug != null && link.kind.toLowerCase() == 'about') {
        return ChatbotLinkTarget(AppRoutes.aboutSectionPath(slug), useGo: true);
      }
      return null;
    case 'booking':
      if (slug == 'book-online') {
        final category = (uri.queryParameters['category'] ?? '').trim();
        if (category.isEmpty) {
          return const ChatbotLinkTarget(
            AppRoutes.exploreServices,
            useGo: true,
          );
        }
        return ChatbotLinkTarget(
          AppRoutes.bookOnlinePath(
            SourceContext(
              type: SourceContextType.service,
              id: category,
              name: _bookingName(link.title),
            ),
          ),
        );
      }
      if (slug == 'appointments') {
        return ChatbotLinkTarget(
          AppRoutes.appointmentPath(AppRoutes.clinicSourceContext),
        );
      }
      return null;
    case 'faq':
      return const ChatbotLinkTarget(AppRoutes.faq);
    case 'memberships':
      return const ChatbotLinkTarget(AppRoutes.membership);
    case 'package':
      return const ChatbotLinkTarget(AppRoutes.packages);
    case 'contact':
      return const ChatbotLinkTarget(AppRoutes.contact);
    case 'patients':
      return const ChatbotLinkTarget(AppRoutes.patients, useGo: true);
  }
  return null;
}

/// "Book Hyperbaric Oxygen Therapy online" -> "Hyperbaric Oxygen Therapy".
String _bookingName(String title) {
  final name = title
      .replaceFirst(RegExp(r'^book\s+', caseSensitive: false), '')
      .replaceFirst(RegExp(r'\s+online$', caseSensitive: false), '')
      .trim();
  return name.isEmpty ? title : name;
}
