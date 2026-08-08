import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "마지막으로 읽은 지 오래됐으면 다시 읽는다" — **앱 전반의 갱신 방식**이다.
///
/// 왜 이 방식인가:
/// - 탭에 들어올 때마다 무조건 읽으면 탭을 오갈 때마다 요청이 나간다.
/// - 그렇다고 한 번 읽고 놔두면(기존 동작) 앱을 오래 켜둔 사용자가 몇 시간 전 목록을 본다.
/// 그래서 **시간으로 끊는다.** 방금 봤으면 캐시를 쓰고, 오래됐으면 조용히 다시 읽는다.
///
/// 소켓으로 실시간 갱신되는 화면(대화방·친구)은 이게 필요 없다.
/// 서버가 알려줄 방법이 없는 목록(달빛가든 피드 등)에 쓴다.
class Freshness {
  Freshness({this.staleAfter = defaultStaleAfter});

  /// 이 시간이 지나면 낡은 것으로 본다. 화면마다 다르게 줄 수 있다.
  final Duration staleAfter;

  /// 앱 공통 기본값. 여기만 바꾸면 전 화면이 따라온다.
  static const Duration defaultStaleAfter = Duration(minutes: 1);

  DateTime? _loadedAt;

  /// 데이터를 읽은 직후에 부른다.
  void markLoaded() => _loadedAt = DateTime.now();

  /// 한 번도 안 읽었거나 [staleAfter]가 지났으면 true.
  bool get isStale {
    final at = _loadedAt;
    return at == null || DateTime.now().difference(at) >= staleAfter;
  }
}

/// 낡았을 때만 다시 읽는 프로바이더가 구현할 계약.
///
/// 화면은 "다시 읽어라"가 아니라 **"낡았으면 읽어라"**만 말한다 —
/// 언제가 낡은 것인지는 프로바이더가 안다.
abstract class RefreshableIfStale {
  Future<void> refreshIfStale();
}

/// 탭이 **다시 보이게 된 순간**에 낡은 데이터를 갱신한다.
///
/// `IndexedStack`은 탭을 옮겨도 화면을 살려 두기 때문에, 화면이 스스로
/// "내가 지금 보이나"를 알 수 없다. 그래서 셸이 알려주는 선택 탭 번호를 보고 판단한다.
///
/// 앱이 백그라운드에 다녀온 경우도 같은 이유로 갱신 대상이다(오래 묵었을 확률이 높다).
class RefreshOnVisible extends ConsumerStatefulWidget {
  const RefreshOnVisible({
    required this.isVisible,
    required this.onStale,
    required this.child,
    super.key,
  });

  /// 이 화면이 지금 보이는 탭인지.
  final bool isVisible;

  /// 보이게 된 순간(또는 앱 복귀 시) 부를 것. 낡지 않았으면 프로바이더가 알아서 넘긴다.
  final Future<void> Function() onStale;

  final Widget child;

  @override
  ConsumerState<RefreshOnVisible> createState() => _RefreshOnVisibleState();
}

class _RefreshOnVisibleState extends ConsumerState<RefreshOnVisible>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(RefreshOnVisible oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 안 보이다가 보이게 된 순간에만. 계속 보이는 동안은 건드리지 않는다.
    if (!oldWidget.isVisible && widget.isVisible) {
      widget.onStale();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isVisible) {
      widget.onStale();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
