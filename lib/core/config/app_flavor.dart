enum AppFlavor {
  dev,
  staging,
  prod;

  static AppFlavor fromString(String value) {
    return AppFlavor.values.firstWhere(
      (flavor) => flavor.name == value,
      orElse: () => AppFlavor.dev,
    );
  }

  String get envFileName => 'env/.env.$name';

  bool get isDev => this == AppFlavor.dev;
}
