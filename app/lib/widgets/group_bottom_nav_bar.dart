import 'package:flutter/material.dart';
import 'animated_bottom_nav_item.dart';

class GroupBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final bool isActive;
  final bool shouldAnimate;

  const GroupBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.isActive = false,
    this.shouldAnimate = true,
  });

  @override
  State<GroupBottomNavBar> createState() => _GroupBottomNavBarState();
}

class _GroupBottomNavBarState extends State<GroupBottomNavBar>
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
      duration: const Duration(milliseconds: 600), // 전체 아이콘 등장 시간
    );

    // ... (Loop for animations is same) ...

    // 5개 아이템에 대한 Staggered Animation 생성
    // 0.0~1.0 구간을 5개로 쪼개서 순차적으로 실행
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
      if (widget.shouldAnimate) {
        _startAnimation();
      } else {
        _staggerController.value = 1.0; // 애니메이션 없이 즉시 표시
      }
    }
  }

  @override
  void didUpdateWidget(GroupBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        if (widget.shouldAnimate) {
          _startAnimation();
        } else {
          _staggerController.value = 1.0;
        }
      } else {
        _staggerController.reset();
      }
    }
  }

  void _startAnimation() async {
    _staggerController.reset();
    // 메인 네비게이션 전환 시간(450ms)에 맞춰 조금 늦게 시작
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted && widget.isActive && widget.shouldAnimate) {
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
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 50), // 하단 마진 증가 (시스템 바 겹침 방지)
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30), // 둥근 캡슐 모양
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material( // 터치 효과를 둥근 모서리 안으로 클립하기 위해 Material 사용
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양 끝으로 정렬하여 뒤로가기 버튼을 왼쪽으로 밀착
          children: [
            // 뒤로가기 버튼 (홈으로 이동) - Item 0
            _buildAnimatedItem(
              0,
              InkWell(
                onTap: () => widget.onTap(0),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F6), // 연한 회색 배경
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF333D4B),
                    size: 24,
                  ),
                ),
              ),
            ),
            
            _buildAnimatedItem(
              1,
              AnimatedBottomNavItem(
                icon: Icons.add_circle_outline,
                label: '모집 만들기',
                isSelected: widget.selectedIndex == 1,
                onTap: () => widget.onTap(1),
              ),
            ),
            _buildAnimatedItem(
              2,
              AnimatedBottomNavItem(
                icon: Icons.list_alt_rounded,
                label: '모집 목록',
                isSelected: widget.selectedIndex == 2,
                onTap: () => widget.onTap(2),
              ),
            ),
            _buildAnimatedItem(
              3,
              AnimatedBottomNavItem(
                icon: Icons.manage_accounts_rounded,
                label: '내 모집 관리',
                isSelected: widget.selectedIndex == 3,
                onTap: () => widget.onTap(3),
              ),
            ),
            _buildAnimatedItem(
              4,
              AnimatedBottomNavItem(
                icon: Icons.favorite_outline_rounded,
                label: '찜 목록',
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
