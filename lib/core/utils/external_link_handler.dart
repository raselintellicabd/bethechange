import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Central policy for opening external destinations from the app.
///
/// Patient Portal and Shop Supplements open in an **external browser**.
/// Clinic phone uses the `tel:` scheme.
class ExternalLinkHandler {
  ExternalLinkHandler({
    Future<bool> Function(Uri uri)? canLaunch,
    Future<bool> Function(Uri uri, {required LaunchMode mode})? launch,
  })  : _canLaunch = canLaunch ?? canLaunchUrl,
        _launch = launch ??
            ((uri, {required LaunchMode mode}) =>
                launchUrl(uri, mode: mode));

  final Future<bool> Function(Uri uri) _canLaunch;
  final Future<bool> Function(Uri uri, {required LaunchMode mode}) _launch;

  static const _allowedSchemes = {'http', 'https', 'tel', 'mailto'};

  /// Opens [url] externally when the scheme is allowed.
  ///
  /// Returns `true` if a launch was attempted successfully.
  Future<bool> openExternal(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !_allowedSchemes.contains(uri.scheme.toLowerCase())) {
      return false;
    }

    if (!await _canLaunch(uri)) {
      return false;
    }

    return _launch(uri, mode: LaunchMode.externalApplication);
  }
}

final externalLinkHandlerProvider = Provider<ExternalLinkHandler>((ref) {
  return ExternalLinkHandler();
});
