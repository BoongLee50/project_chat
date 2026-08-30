import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../data/models/post_info.dart';

/// 상대 한 사람의 [포스트 정보].
///
/// `autoDispose`로 둔다 — 이 화면은 한 사람을 보고 닫는 화면이라
/// 남겨 둘 이유가 없고, 다음에 열 때는 접속 상태·신청 상태가 이미 달라져 있다.
final postInfoProvider = FutureProvider.autoDispose
    .family<PostInfo, String>((ref, targetUserId) {
      return ref.read(postInfoApiProvider).get(targetUserId);
    });
