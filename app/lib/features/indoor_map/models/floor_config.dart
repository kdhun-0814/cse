class FloorConfig {
  final int floor;
  final String floorName;
  final String glbPath;
  final String jsonPath;
  final String initialCameraOrbit;
  final String initialCameraTarget;
  final double defaultZoom;

  const FloorConfig({
    required this.floor,
    required this.floorName,
    required this.glbPath,
    required this.jsonPath,
    required this.initialCameraOrbit,
    required this.initialCameraTarget,
    this.defaultZoom = 250,
  });
}
