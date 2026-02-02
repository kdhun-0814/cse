import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String id;
  final String name;
  final String type;
  final String description;
  final double x;
  final double y;
  final double z;
  final bool isCorridor;

  Room({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.x,
    required this.y,
    required this.z,
    this.isCorridor = false,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('position')) {
      // Local JSON format
      final pos = json['position'] as Map<String, dynamic>;
      return Room(
        id: json['id'],
        name: json['name'],
        type: json['type'],
        description: json['description'],
        x: (pos['x'] as num).toDouble(),
        y: (pos['y'] as num).toDouble(),
        z: (pos['z'] as num).toDouble(),
        isCorridor: false,
      );
    } else {
      // Firestore Node format
      // Note: In make_building.py, we mapped JSON Z -> Graph Y because it's a 2D graph.
      // But in 3D Viewer:
      // Viewer X = Node X
      // Viewer Y = Node Y (Height, usually 0)
      // Viewer Z = Node Y (Depth, stored as Y in graph because it's 2D)

      // Let's rely on field names stored in Firestore:
      // 'x' -> Viewer X
      // 'y' -> Viewer Z (Depth)
      // Height is 0.

      return Room(
        id: json['id'],
        name: json['name'] ?? '',
        type: json['type'] ?? 'etc',
        description: json['description'] ?? '',
        x: (json['x'] as num).toDouble(),
        y: 0.0,
        z: (json['y'] as num).toDouble(),
        isCorridor: json['is_corridor'] ?? false,
      );
    }
  }
}

class MapService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Firebase Storage에서 GLB 모델의 다운로드 URL 가져오기
  Future<String> getMapModelUrl() async {
    try {
      // Use local asset provided by user
      return 'assets/3d/4floor_2.glb';
    } on FirebaseException catch (e) {
      debugPrint("🔥 Firebase Storage Error: ${e.code} - ${e.message}");
      // Attempt fallback to local if needed, but ModelViewer needs URL or asset
      return '';
    } catch (e) {
      debugPrint("❌ General Error fetching map URL: $e");
      return '';
    }
  }

  // 2. Load Nodes from Firestore (Graph Data)
  Future<List<Room>> loadRooms() async {
    try {
      // Try Firestore First
      debugPrint("📡 Fetching Map Nodes from Firestore...");
      final snapshot = await _firestore
          .collection('maps')
          .doc('CSE_BUILDING')
          .collection('nodes')
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Room.fromJson(doc.data())).toList();
      } else {
        // Fallback to local JSON if Firestore is empty
        debugPrint("⚠️ Firestore empty, falling back to local JSON.");
        return _loadLocalRooms();
      }
    } catch (e) {
      debugPrint("❌ Error loading rooms data: $e");
      return _loadLocalRooms();
    }
  }

  Future<List<Room>> _loadLocalRooms() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/3d/rooms_data.json',
      );
      final List<dynamic> data = json.decode(response);
      return data.map((json) => Room.fromJson(json)).toList();
    } catch (e) {
      debugPrint("❌ Error loading local rooms: $e");
      return [];
    }
  }

  // 3. Fetch Edges for Graph Pathfinding
  Future<List<Map<String, dynamic>>> fetchEdges() async {
    try {
      final doc = await _firestore
          .collection('maps')
          .doc('CSE_BUILDING')
          .collection('edges')
          .doc('all_edges')
          .get();

      if (doc.exists && doc.data() != null) {
        List<dynamic> list = doc.data()!['list'];
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint("❌ Error fetching edges: $e");
      return [];
    }
  }
}
