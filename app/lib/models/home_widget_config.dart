class HomeWidgetConfig {
  final String id;
  bool isVisible;

  HomeWidgetConfig({required this.id, required this.isVisible});

  Map<String, dynamic> toMap() {
    return {'id': id, 'isVisible': isVisible};
  }

  factory HomeWidgetConfig.fromMap(Map<String, dynamic> map) {
    return HomeWidgetConfig(
      id: map['id'] ?? '',
      isVisible: map['isVisible'] ?? true,
    );
  }
}
