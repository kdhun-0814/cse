import 'dart:math';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'map_service.dart';

class PathPoint {
  final double x;
  final double y;
  final double z;

  PathPoint(this.x, this.y, this.z);
}

class PathService {
  // Graph Structure: Adjacency List
  Map<String, List<String>> adjList = {};
  Map<String, Room> nodeMap = {};

  // Build Graph from loaded data
  void buildGraph(List<Room> nodes, List<Map<String, dynamic>> edges) {
    adjList.clear();
    nodeMap.clear();

    for (var node in nodes) {
      nodeMap[node.id] = node;
      adjList[node.id] = [];
    }

    for (var edge in edges) {
      String from = edge['from'];
      String to = edge['to'];

      // Undirected Graph
      if (adjList.containsKey(from) && adjList.containsKey(to)) {
        adjList[from]!.add(to);
        adjList[to]!.add(from);
      }
    }
    debugPrint(
      "🕸️ Graph Built: ${nodes.length} nodes, ${edges.length} edges (x2 for undir)",
    );
  }

  /// Calculate Path using BFS (Unweighted Shortest Path)
  /// Since we generated a 'Manhattan' like graph (Corridors), BFS is sufficient to find path.
  /// If distances vary significantly, Dijkstra is better,
  /// but our edge weights are simple distances and we just want connectivity.
  List<PathPoint> calculatePath(Room start, Room end) {
    // If graph is empty (e.g. using fallback mode with no edges), fallback to simple interpolation
    if (adjList.isEmpty) {
      return _calculateSimplePath(start, end);
    }

    // BFS
    Queue<String> queue = Queue();
    Map<String, String?> cameFrom = {};
    Set<String> visited = {};

    queue.add(start.id);
    visited.add(start.id);
    cameFrom[start.id] = null;

    bool found = false;

    while (queue.isNotEmpty) {
      String currentId = queue.removeFirst();

      if (currentId == end.id) {
        found = true;
        break;
      }

      for (String neighbor in adjList[currentId] ?? []) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          cameFrom[neighbor] = currentId;
          queue.add(neighbor);
        }
      }
    }

    if (!found) {
      debugPrint("❌ Path not found between ${start.name} and ${end.name}");
      // Fallback
      return _calculateSimplePath(start, end);
    }

    // Reconstruct Path
    List<PathPoint> path = [];
    String? current = end.id;

    while (current != null) {
      Room r = nodeMap[current]!;
      path.add(PathPoint(r.x, r.y, r.z)); // r.y is 0, r.z is depth
      current = cameFrom[current];
    }

    // Path is reversed (End -> Start), revers it
    return path.reversed.toList();
  }

  // Fallback: Simple Interpolation (Old Logic)
  List<PathPoint> _calculateSimplePath(
    Room start,
    Room end, {
    double step = 2.5,
  }) {
    debugPrint("⚠️ Using simple path fallback");
    List<PathPoint> path = [];
    double corridorZ = 0.0; // Heuristic Spine

    PathPoint p1 = PathPoint(start.x, start.y, start.z);
    PathPoint p2 = PathPoint(start.x, start.y, corridorZ); // Project to spine
    PathPoint p3 = PathPoint(end.x, end.y, corridorZ); // Project to spine
    PathPoint p4 = PathPoint(end.x, end.y, end.z);

    path.addAll(_generateSegment(p1, p2, step));
    path.addAll(_generateSegment(p2, p3, step));
    path.addAll(_generateSegment(p3, p4, step));
    return path;
  }

  List<PathPoint> _generateSegment(PathPoint p1, PathPoint p2, double step) {
    List<PathPoint> segment = [];
    double dx = p2.x - p1.x;
    double dy = p2.y - p1.y;
    double dz = p2.z - p1.z;
    double dist = sqrt(dx * dx + dy * dy + dz * dz);

    if (dist <= 0.1) return [];

    int count = (dist / step).floor();
    if (count < 1) count = 1;

    for (int i = 0; i <= count; i++) {
      double t = i / count;
      segment.add(PathPoint(p1.x + dx * t, p1.y + dy * t, p1.z + dz * t));
    }
    return segment;
  }
}

// Queue Helper since Dart collection doesn't export Queue by default in simple imports sometimes, 
// but actually 'dart:collection' does.

