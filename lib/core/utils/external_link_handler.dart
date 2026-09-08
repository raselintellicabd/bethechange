import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Central policy for opening external destinations from the app.
///
/// Phase H decisions: Patient Portal and Shop Supplements always open in an
/// **external browser** (`LaunchMode.externalApplication`). In-app WebView is
/// not used for these links.
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

  /// Opens [url] in an external browser when possible.
  ///
  /// Returns `true` if a launch was attempted successfully.
  Future<bool> openExternal(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
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
