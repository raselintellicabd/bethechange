import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// Finish login/signup without wiping the stack when [returnTo] was pushed under us.
///
/// Prefer `pop` so pages like Membership keep their back button; only `go`/`push`
/// when the destination is not already the current route after dismissing auth.
void completeAuthNavigation(BuildContext context, String? returnTo) {
  final dest = (returnTo ?? '').trim();
  if (dest.isEmpty) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
    return;
  }

  final destPath = Uri.tryParse(dest)?.path ?? dest;

  if (!context.canPop()) {
    context.go(dest);
    return;
  }

  context.pop();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    final current = GoRouterState.of(context).uri.path;
    if (current != destPath) {
      context.push(dest);
    }
  });
}

/// Leave Membership (or similar root overlays): pop if possible, else Patients tab.
void leaveMembershipScreen(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.patients);
  }
}
