class PathEdge {
  final int from;
  final int to;

  PathEdge({required this.from, required this.to});

  factory PathEdge.fromJson(Map<String, dynamic> json) {
    return PathEdge(from: json['from'] as int, to: json['to'] as int);
  }

  Map<String, dynamic> toJson() {
    return {'from': from, 'to': to};
  }
}
