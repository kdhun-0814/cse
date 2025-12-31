import 'path_node.dart';
import 'path_edge.dart';

class FloorData {
  final List<PathNode> nodes;
  final List<PathEdge> edges;

  FloorData({required this.nodes, required this.edges});

  factory FloorData.fromJson(Map<String, dynamic> json) {
    return FloorData(
      nodes: (json['nodes'] as List)
          .map((n) => PathNode.fromJson(n as Map<String, dynamic>))
          .toList(),
      edges: (json['edges'] as List)
          .map((e) => PathEdge.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  PathNode? getNodeById(int id) {
    try {
      return nodes.firstWhere((node) => node.id == id);
    } catch (_) {
      return null;
    }
  }

  List<PathNode> getRoomNodes() {
    return nodes.where((node) => node.type == 'room').toList();
  }

  PathNode? getStartNode() {
    try {
      return nodes.firstWhere((node) => node.type == 'start');
    } catch (_) {
      return null;
    }
  }
}
