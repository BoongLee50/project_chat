import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../widgets/profile_preview_view.dart';

/// 내 프로필 [미리 보기] — [작성하기]의 `미리 보기` 버튼이 연다.
///
/// 남이 내 프로필을 눌렀을 때 보는 창과 **같은 위젯**([ProfilePreviewView])이다.
/// 세션의 내 프로필을 그대로 그리므로 서버를 따로 묻지 않는다.
class ProfilePreviewScreen extends ConsumerWidget {
  const ProfilePreviewScreen({super.key});

  static Route<void> route() => MaterialPageRoute(
    builder: (_) => const ProfilePreviewScreen(),
    fullscreenDialog: true,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider).profile;

    return Scaffold(
      backgroundColor: Colors.white,
      body: me == null
          ? const SizedBox.shrink()
          : ProfilePreviewView(
              data: ProfilePreviewData(
                nickname: me.nickname ?? '',
                // 서버는 출생년도만 주므로 연 단위로 계산한다(포스트 정보와 같은 셈).
                age: me.birthYear == null
                    ? null
                    : DateTime.now().year - me.birthYear!,
                country: me.country,
                facePhotoUrl: me.photoUrl,
                mainPhotoUrl: me.mainPhotoUrl,
                intro: me.intro,
                interests: me.interests,
                regions: me.regions,
              ),
            ),
    );
  }
}
