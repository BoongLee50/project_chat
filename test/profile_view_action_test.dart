import 'package:flutter_test/flutter_test.dart';
import 'package:project_chat/features/postinfo/data/models/post_info.dart';
import 'package:project_chat/features/postinfo/presentation/screens/profile_view_screen.dart';

/// 남의 [프로필 보기] 하단 버튼 규칙(2026-10-05 사용자 결정).
void main() {
  const me = 'me';

  PostInfo other({
    FriendRelation relation = FriendRelation.none,
    String? chatRequestId,
    String? chatRoomId,
    String userId = 'other',
  }) => PostInfo(
    userId: userId,
    nickname: 'x',
    friendRelation: relation,
    chatRequestId: chatRequestId,
    chatRoomId: chatRoomId,
  );

  ProfileViewAction of(PostInfo info) =>
      profileViewActionOf(info, myUserId: me);

  test('아무 관계가 아니면 [대화 신청]', () {
    expect(of(other()), ProfileViewAction.requestChat);
  });

  test('대화 중이고 친구가 아니면 [친구 신청]', () {
    expect(of(other(chatRoomId: 'r')), ProfileViewAction.requestFriend);
  });

  test('대화 중에 내가 친구 신청을 이미 보냈으면 신청 대기', () {
    expect(
      of(other(chatRoomId: 'r', relation: FriendRelation.requested)),
      ProfileViewAction.friendPending,
    );
  });

  test('친구면 버튼 없음 — 대화 중이어도', () {
    expect(of(other(relation: FriendRelation.friend)), ProfileViewAction.none);
    expect(
      of(other(relation: FriendRelation.friend, chatRoomId: 'r')),
      ProfileViewAction.none,
    );
  });

  test('나에게 대화 신청을 보낸 사람(받은 신청 목록)이면 버튼 없음', () {
    expect(of(other(chatRequestId: 'q')), ProfileViewAction.none);
  });

  test('나 자신이면 버튼 없음', () {
    expect(of(other(userId: me)), ProfileViewAction.none);
  });
}
