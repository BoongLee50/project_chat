import 'package:flutter/material.dart';

import '../../features/garden/presentation/widgets/garden_art.dart';
import '../../features/store/presentation/screens/prime_screen.dart';
import 'design_canvas.dart';

/// 시안 화면들의 머리글 — **타이틀 그림 · Prime** 한 줄.
///
/// 포스트·달빛가든·대화방이 **같은 자리·같은 그림**을 쓴다(시안 `577,102`).
/// 타이틀만 화면마다 다르다. Prime 그림은 달빛가든 폴더로 전달돼 거기를 가리킨다.
///
/// 🗑 오른쪽 끝의 **루나상점 버튼은 없어졌다**(기획서 261111 — 루나 폐지, 사용자 2026-11-14).
/// Prime이 오른쪽 끝으로 간다.
///
/// 📌 포스트(`_TopBar`)와 달빛가든(`_GardenHeader`)에는 같은 코드가 따로 들어 있다 —
/// 대화방부터 이 위젯을 쓰고, 두 화면도 옮기면 셋이 한곳에서 움직인다(아직 안 옮겼다).
class ArtTopBar extends StatelessWidget {
  const ArtTopBar({super.key, required this.title, required this.titleSize});

  final String title;
  final Size titleSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ArtImage(title, width: titleSize.width, height: titleSize.height),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.of(context).push(PrimeScreen.route()),
          child: ArtImage(
            GardenArt.btnPrime,
            width: GardenArt.btnPrimeSize.width,
            height: GardenArt.btnPrimeSize.height,
          ),
        ),
      ],
    );
  }
}
