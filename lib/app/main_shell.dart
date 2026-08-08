import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/chat/presentation/screens/chat_rooms_screen.dart';
import '../features/friend/presentation/screens/friends_screen.dart';
import '../features/garden/presentation/screens/garden_screen.dart';
import '../features/post/presentation/screens/home_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../shared/widgets/main_bottom_nav.dart';

/// 지금 보이는 탭 번호.
///
/// `IndexedStack`은 탭을 옮겨도 다섯 화면을 전부 살려 두기 때문에, 각 화면이
/// 스스로 "내가 지금 보이나"를 알 수 없다. 낡은 데이터를 다시 읽을 시점을 잡으려면
/// 그걸 알아야 해서 셸이 여기에 적어 둔다. (core/util/freshness.dart)
final selectedTabProvider = StateProvider<int>((ref) => 0);

/// 탭 번호 — 화면 쪽에서 `selectedTabProvider`와 비교할 때 쓴다.
class MainTab {
  const MainTab._();

  static const int post = 0;
  static const int garden = 1;
  static const int chat = 2;
  static const int friend = 3;
  static const int profile = 4;
}

/// 로그인·온보딩 이후의 메인 셸. 하단 5탭으로 화면을 전환한다.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _index = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    // 첫 프레임 이후에 알린다(build 중 프로바이더 수정 금지).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedTabProvider.notifier).state = _index;
    });
  }

  void _select(int i) {
    setState(() => _index = i);
    ref.read(selectedTabProvider.notifier).state = i;
  }

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
            ChatRoomsScreen(),
            FriendsScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: MainBottomNav(selected: _index, onTap: _select),
      ),
    );
  }
}
