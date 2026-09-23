enum PatientTileActionType { externalUrlKey, route, externalUrl, none }

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
      'none' => PatientTileActionType.none,
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

class PatientSection {
  const PatientSection({
    required this.id,
    required this.title,
    required this.tiles,
  });

  final String id;
  final String title;
  final List<PatientTileItem> tiles;

  factory PatientSection.fromJson(Map<String, dynamic> json) {
    final tiles = (json['tiles'] as List<dynamic>? ?? const [])
        .map((item) => PatientTileItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return PatientSection(
      id: (json['id'] as String?)?.trim() ?? '',
      title: (json['title'] as String?)?.trim() ?? '',
      tiles: tiles,
    );
  }
}

class PatientsContent {
  const PatientsContent({
    required this.sectionTitle,
    required this.sectionSubtitle,
    required this.sections,
    this.headerSubtitle = 'Manage your care in one place',
    List<PatientTileItem>? tiles,
  }) : _legacyTiles = tiles;

  final String sectionTitle;
  final String sectionSubtitle;
  final String headerSubtitle;
  final List<PatientSection> sections;
  final List<PatientTileItem>? _legacyTiles;

  /// Flat tile list (sections first, then any legacy top-level tiles).
  List<PatientTileItem> get tiles {
    if (sections.isNotEmpty) {
      return [for (final section in sections) ...section.tiles];
    }
    return _legacyTiles ?? const [];
  }

  factory PatientsContent.fromJson(Map<String, dynamic> json) {
    final sections = (json['sections'] as List<dynamic>? ?? const [])
        .map((item) => PatientSection.fromJson(item as Map<String, dynamic>))
        .toList();

    final legacyTiles = (json['tiles'] as List<dynamic>? ?? const [])
        .map((item) => PatientTileItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return PatientsContent(
      sectionTitle: (json['sectionTitle'] as String?)?.trim() ?? 'Patients',
      sectionSubtitle: (json['sectionSubtitle'] as String?)?.trim() ?? '',
      headerSubtitle: (json['headerSubtitle'] as String?)?.trim() ??
          'Manage your care in one place',
      sections: sections,
      tiles: sections.isEmpty ? legacyTiles : null,
    );
  }
}
