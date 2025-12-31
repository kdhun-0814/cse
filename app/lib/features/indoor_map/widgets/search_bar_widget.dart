import 'package:flutter/material.dart';
import '../models/room_search_result.dart';

class SearchBarWidget extends StatefulWidget {
  final List<RoomSearchResult> allRooms; // Changed from List<PathNode>
  final Function(RoomSearchResult) onRoomSelected; // Changed callback type
  final VoidCallback onClear;

  const SearchBarWidget({
    super.key,
    required this.allRooms,
    required this.onRoomSelected,
    required this.onClear,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  List<RoomSearchResult> _filteredRooms = [];
  bool _showDropdown = false;

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredRooms = [];
        _showDropdown = false;
      });
      return;
    }

    final filtered = widget.allRooms.where((result) {
      final name = result.node.name?.toLowerCase() ?? '';
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredRooms = filtered;
      _showDropdown = true;
    });
  }

  void _selectRoom(RoomSearchResult result) {
    _controller.text = result.node.name ?? '';
    setState(() {
      _showDropdown = false;
    });
    FocusScope.of(context).unfocus();
    widget.onRoomSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
          child: TextField(
            controller: _controller,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: '호수 검색 (예: 501, 715)',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _controller.clear();
                        _onSearchChanged('');
                        widget.onClear();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
        if (_showDropdown && _filteredRooms.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _filteredRooms.length,
              itemBuilder: (context, index) {
                final result = _filteredRooms[index];
                return ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
                  title: Text(result.node.name ?? 'Unknown'),
                  subtitle: Text('${result.floorName}'),
                  onTap: () => _selectRoom(result),
                );
              },
            ),
          ),
      ],
    );
  }
}
