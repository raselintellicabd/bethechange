import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_flavor.dart';
import 'core/config/env_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> bootstrap(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load(flavor);

  runApp(
    ProviderScope(
      child: BeTheChangeApp(flavor: flavor),
    ),
  );
}

class BeTheChangeApp extends ConsumerStatefulWidget {
  const BeTheChangeApp({super.key, required this.flavor});

  final AppFlavor flavor;

  @override
  ConsumerState<BeTheChangeApp> createState() => _BeTheChangeAppState();
}

class _BeTheChangeAppState extends ConsumerState<BeTheChangeApp> {
  late final _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: EnvConfig.appName,
      debugShowCheckedModeBanner: widget.flavor.isDev,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
