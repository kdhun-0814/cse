import 'dart:collection';
import '../models/path_node.dart';
import '../models/floor_data.dart';

class NavigationService {
  /// BFS 알고리즘을 사용한 최단 경로 탐색
  List<PathNode> findPath(PathNode start, PathNode end, FloorData data) {
    if (start.id == end.id) return [start];

    // 인접 리스트 생성
    final Map<int, List<int>> adjacencyList = {};
    for (final edge in data.edges) {
      adjacencyList.putIfAbsent(edge.from, () => []).add(edge.to);
      adjacencyList.putIfAbsent(edge.to, () => []).add(edge.from);
    }

    // BFS 초기화
    final queue = Queue<int>()..add(start.id);
    final visited = {start.id};
    final parent = <int, int?>{start.id: null};

    bool found = false;
    while (queue.isNotEmpty) {
      final currentId = queue.removeFirst();

      if (currentId == end.id) {
        found = true;
        break;
      }

      final neighbors = adjacencyList[currentId] ?? [];
      for (final neighborId in neighbors) {
        if (!visited.contains(neighborId)) {
          visited.add(neighborId);
          parent[neighborId] = currentId;
          queue.add(neighborId);
        }
      }
    }

    if (!found) return [];

    // 경로 재구성
    final List<PathNode> path = [];
    int? currentId = end.id;
    while (currentId != null) {
      final node = data.getNodeById(currentId);
      if (node != null) {
        path.insert(0, node);
      }
      currentId = parent[currentId];
    }

    return path;
  }
}
