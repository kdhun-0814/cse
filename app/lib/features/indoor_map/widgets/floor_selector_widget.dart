import 'package:flutter/material.dart';
import '../../../widgets/common/bounceable.dart';

class FloorSelectorWidget extends StatelessWidget {
  final int currentFloor;
  final ValueChanged<int> onFloorChanged;

  const FloorSelectorWidget({
    super.key,
    required this.currentFloor,
    required this.onFloorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFloorButton(context, 4),
          _buildFloorButton(context, 5),
          _buildFloorButton(context, 6),
          _buildFloorButton(context, 7),
        ],
      ),
    );
  }

  Widget _buildFloorButton(BuildContext context, int floor) {
    final bool isSelected = currentFloor == floor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Bounceable(
        onTap: () => onFloorChanged(floor),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3182F6) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${floor}F',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isSelected ? Colors.white : const Color(0xFF4E5968),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
