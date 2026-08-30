package com.moonlighttalk.server.postinfo.dto;

import java.util.List;

/**
 * [포스트 정보] 화면 1건 (기획 6-1 우측 · 7-1 우측).
 *
 * <p><b>왜 화면 하나에 응답 하나인가</b> — 이 화면은 대화방(받은 신청) · 친구 목록 · 달빛가든
 * 세 군데가 부르는데, 보여 주는 것은 똑같고 <b>하단 버튼만 다르다</b>. 화면마다 따로
 * 만들면 열람 제한과 친구 상태 판정이 세 벌로 갈라진다. 판정은 서버에서 한 번 하고,
 * 부르는 쪽은 자기가 어디서 왔는지만 안다.
 *
 * @param photoUrls        볼 수 있는 사진. <b>열람 제한이 걸리면 메인 1장만 담긴다</b>(가든과 같은 규칙)
 * @param photoLocked      나머지가 잠겨 있는가
 * @param totalPhotos      원래 몇 장인가 — 잠겨 있어도 "더 있다"를 보여줘야 안내가 말이 된다
 * @param regions          활동 지역 <b>코드</b>. 문구는 클라가 만든다(서버는 코드, 클라는 문구)
 * @param chatRequestId    상대가 나에게 보낸 <b>대화</b> 신청. 있으면 하단이 [거절]/[수락]이 된다
 * @param chatRequestMessage 그 신청에 적힌 한마디(따옴표로 보여 준다)
 * @param friendRelation   <b>친구</b> 관계 — NONE / REQUESTED(내가 보냄) / INCOMING(상대가 보냄) / FRIEND
 * @param friendshipId     수락·해제에 필요한 id. 관계가 NONE이면 null
 * @param friendRequestMessage 상대가 친구 신청과 함께 남긴 한마디(25자, V17).
 *                         대화 신청 메시지와 <b>같은 자리</b>에 보여 준다 — 시안이 그렇다
 * @param chatRoomId       지금 살아 있는 대화방. 있으면 하단이 [대화하기]가 된다
 * @param hasTodayPost     상대가 오늘 포스트를 올렸는가. 없으면 사진 대신 프로필 사진을 보여 준다
 * @param profilePhotoUrl  ⋮ 메뉴의 [프로필 보기]가 쓰는 사진. 포스트 사진과 <b>다른 것</b>이라
 *                         열람 제한과 무관하다 — 프로필은 원래 누구나 본다
 */
public record PostInfoDto(
        String userId,
        String nickname,
        Integer age,
        String country,
        String gender,
        boolean online,
        boolean premium,
        List<String> photoUrls,
        boolean photoLocked,
        int totalPhotos,
        boolean hasTodayPost,
        String profilePhotoUrl,
        String intro,
        List<String> interests,
        List<String> regions,
        String chatRequestId,
        String chatRequestMessage,
        String friendRelation,
        String friendshipId,
        String friendRequestMessage,
        String chatRoomId
) {
}
