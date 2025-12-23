import 'package:flutter/material.dart';
import 'animated_bottom_nav_item.dart';

class MainBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final bool isActive;

  const MainBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<MainBottomNavBar> createState() => _MainBottomNavBarState();
}

class _MainBottomNavBarState extends State<MainBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  final List<Animation<double>> _itemAnimations = [];
  final List<Animation<Offset>> _slideAnimations = [];
  final List<Animation<double>> _scaleAnimations = [];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Staggered Animation 설정
    // 5개 아이템에 대한 Staggered Animation 생성
    for (int i = 0; i < 5; i++) {
      final start = i * 0.1;
      final end = start + 0.4;
      
      _itemAnimations.add(Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut),
        ),
      ));

      _slideAnimations.add(Tween<Offset>(
        begin: const Offset(-0.2, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut),
        ),
      ));

      _scaleAnimations.add(Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.elasticOut),
        ),
      ));
    }

    if (widget.isActive) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(MainBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startAnimation();
      } else {
        _staggerController.reset();
      }
    }
  }

  void _startAnimation() async {
    _staggerController.reset();
    // 슬라이드 애니메이션이 거의 끝날 때쯤 페이드인 시작 (Delay)
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted && widget.isActive) {
      _staggerController.forward();
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12, top: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(color: Color(0xFFE5E8EB), width: 1),
          left: BorderSide(color: Color(0xFFE5E8EB), width: 1),
          right: BorderSide(color: Color(0xFFE5E8EB), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAnimatedItem(
              0,
              AnimatedBottomNavItem(
                icon: Icons.home_filled,
                label: '홈',
                isSelected: widget.selectedIndex == 0,
                onTap: () => widget.onTap(0),
              ),
            ),
            _buildAnimatedItem(
              1,
              AnimatedBottomNavItem(
                icon: Icons.bookmark_outline,
                label: '스크랩',
                isSelected: widget.selectedIndex == 1,
                onTap: () => widget.onTap(1),
              ),
            ),
            _buildAnimatedItem(
              2,
              AnimatedBottomNavItem(
                icon: Icons.people_outline,
                label: '모집',
                isSelected: widget.selectedIndex == 2,
                onTap: () => widget.onTap(2),
              ),
            ),
            _buildAnimatedItem(
              3,
              AnimatedBottomNavItem(
                icon: Icons.calendar_today_rounded,
                label: '일정',
                isSelected: widget.selectedIndex == 3,
                onTap: () => widget.onTap(3),
              ),
            ),
            _buildAnimatedItem(
              4,
              AnimatedBottomNavItem(
                icon: Icons.map_outlined,
                label: '3D맵',
                isSelected: widget.selectedIndex == 4,
                onTap: () => widget.onTap(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    if (index >= _itemAnimations.length) return child;
    return FadeTransition(
      opacity: _itemAnimations[index],
      child: SlideTransition(
        position: _slideAnimations[index],
        child: ScaleTransition(
          scale: _scaleAnimations[index],
          child: child,
        ),
      ),
    );
  }
}
