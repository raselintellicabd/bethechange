enum PatientTileActionType { externalUrlKey, route, externalUrl }

class PatientTileAction {
  const PatientTileAction({
    required this.type,
    this.urlKey,
    this.route,
    this.url,
  });

  final PatientTileActionType type;
  final String? urlKey;
  final String? route;
  final String? url;

  factory PatientTileAction.fromJson(Map<String, dynamic> json) {
    final typeName = (json['type'] as String?)?.trim() ?? '';
    final type = switch (typeName) {
      'externalUrlKey' => PatientTileActionType.externalUrlKey,
      'route' => PatientTileActionType.route,
      'externalUrl' => PatientTileActionType.externalUrl,
      _ => throw FormatException('Unknown patient tile action type: $typeName'),
    };

    return PatientTileAction(
      type: type,
      urlKey: (json['urlKey'] as String?)?.trim(),
      route: (json['route'] as String?)?.trim(),
      url: (json['url'] as String?)?.trim(),
    );
  }
}

class PatientTileItem {
  const PatientTileItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.action,
  });

  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final PatientTileAction action;

  factory PatientTileItem.fromJson(Map<String, dynamic> json) {
    return PatientTileItem(
      id: (json['id'] as String?)?.trim() ?? '',
      title: (json['title'] as String?)?.trim() ?? '',
      subtitle: (json['subtitle'] as String?)?.trim() ?? '',
      icon: (json['icon'] as String?)?.trim() ?? 'help_outline',
      action: PatientTileAction.fromJson(
        json['action'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class PatientsContent {
  const PatientsContent({
    required this.sectionTitle,
    required this.sectionSubtitle,
    required this.tiles,
  });

  final String sectionTitle;
  final String sectionSubtitle;
  final List<PatientTileItem> tiles;

  factory PatientsContent.fromJson(Map<String, dynamic> json) {
    final tiles = (json['tiles'] as List<dynamic>? ?? const [])
        .map((item) => PatientTileItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return PatientsContent(
      sectionTitle: (json['sectionTitle'] as String?)?.trim() ?? 'Patients',
      sectionSubtitle: (json['sectionSubtitle'] as String?)?.trim() ?? '',
      tiles: tiles,
    );
  }
}
