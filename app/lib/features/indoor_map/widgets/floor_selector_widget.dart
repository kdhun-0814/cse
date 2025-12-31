import 'package:flutter/material.dart';

class FloorSelectorWidget extends StatelessWidget {
  final int currentFloor;
  final Function(int) onFloorChanged;

  const FloorSelectorWidget({
    super.key,
    required this.currentFloor,
    required this.onFloorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFloorButton(7),
          _buildFloorButton(6),
          _buildFloorButton(5),
          _buildFloorButton(4),
        ],
      ),
    );
  }

  Widget _buildFloorButton(int floor) {
    final isSelected = floor == currentFloor;

    return Container(
      margin: const EdgeInsets.all(4),
      child: Material(
        color: isSelected ? const Color(0xFF3182F6) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () => onFloorChanged(floor),
          child: Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            child: Text(
              '${floor}F',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
