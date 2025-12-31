class PathNode {
  final int id;
  final String type;
  final String? name;
  final double x;
  final double y;
  final double z;

  PathNode({
    required this.id,
    required this.type,
    this.name,
    required this.x,
    required this.y,
    required this.z,
  });

  factory PathNode.fromJson(Map<String, dynamic> json) {
    return PathNode(
      id: json['id'] as int,
      type: json['type'] as String,
      name: json['name'] as String?,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'type': type, 'name': name, 'x': x, 'y': y, 'z': z};
  }
}
