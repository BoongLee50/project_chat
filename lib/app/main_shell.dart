import 'package:flutter/material.dart';

import '../features/garden/presentation/screens/garden_screen.dart';
import '../features/post/presentation/screens/home_screen.dart';
import '../shared/widgets/main_bottom_nav.dart';
import '../shared/widgets/placeholder_screen.dart';

/// 로그인·온보딩 이후의 메인 셸. 하단 5탭으로 화면을 전환한다.
/// (대화방·친구·프로필은 아직 임시 화면)
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: const [
            HomeScreen(),
            GardenScreen(),
            PlaceholderScreen(title: '대화방', icon: Icons.chat_bubble_outline),
            PlaceholderScreen(title: '친구', icon: Icons.people_outline),
            PlaceholderScreen(title: '프로필', icon: Icons.person_outline),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: MainBottomNav(
          selected: _index,
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
