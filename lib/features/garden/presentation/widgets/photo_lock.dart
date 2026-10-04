import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/main_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/design_canvas.dart';
import 'garden_art.dart';

/// 잠긴 사진 자리(기획 4-1 [사진 등록 안내창]) — **카드 안에서** 2번째 장부터 이렇게 보인다.
///
/// 🚨 **흐리게 그린 건 그 장의 사진이 아니라 메인 사진이다.** 잠긴 사진은 서버가 **URL을 아예 주지 않는다**
/// (열람 제한은 서버가 건다 — 화면이 가리는 게 아니라 애초에 못 받는다). 클라가 진짜 사진을 받아
/// 흐리게만 하면 URL을 뽑아 원본을 보는 길이 열린다. 그래서 받은 한 장(메인)을 **알아볼 수 없을 만큼**
/// 뭉개서 배경으로 깐다 — 보기에는 "가려진 사진"과 같고 제한은 그대로다.
/// 진짜 그 장을 흐리게 보여 줘야 한다면 서버가 **아주 작은 축소본**을 따로 만들어 줘야 한다.
class PhotoLockBackdrop extends StatelessWidget {
  const PhotoLockBackdrop({super.key, required this.mainPhotoUrl});

  final String mainPhotoUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 가장자리가 검게 번지지 않도록 clamp — 기본(decal)은 테두리로 투명이 스며든다.
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 36,
            sigmaY: 36,
            tileMode: TileMode.clamp,
          ),
          child: AuthedImage(url: mainPhotoUrl),
        ),
        // 시안(사진 등록 요청 안내)은 사진이 **거의 검게** 깔린다 — 글자가 그 위에 읽혀야 한다.
        const ColoredBox(color: Color(0xB3000000)),
      ],
    );
  }
}

/// 잠긴 장 위에 얹는 안내 문구 + [새 사진 등록하기].
///
/// 문구는 글자를 지나 아래 사진의 탭(좌우 넘기기)으로 흘려보낸다 — 버튼만 손가락을 받는다.
class PhotoLockGuide extends ConsumerWidget {
  const PhotoLockGuide({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IgnorePointer(
              child: Text(
                l10n.gardenPhotoLockedBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 28),
            // ✅ 버튼이 **그림으로 왔다**(시안 `288, 1674`의 `새 사진 등록하기`).
            // 문구가 그림 안에 있으므로 `gardenPhotoLockedAction`을 겹쳐 그리지 않는다.
            GestureDetector(
              // 열쇠는 상품이 아니라 **내 포스트**다 — 상점이 아니라 포스트 탭으로 보낸다.
              onTap: () =>
                  ref.read(selectedTabProvider.notifier).state = MainTab.post,
              child: ArtImage(
                GardenArt.btnAddPost,
                width: GardenArt.btnAddPostSize.width,
                height: GardenArt.btnAddPostSize.height,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
