import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../features/garden/presentation/widgets/garden_art.dart';
import '../../features/store/presentation/providers/store_provider.dart';
import '../../features/store/presentation/screens/luna_store_screen.dart';
import '../../features/store/presentation/screens/prime_screen.dart';
import 'design_canvas.dart';

/// 시안 화면들의 머리글 — **타이틀 그림 · Prime · 루나상점** 한 줄.
///
/// 포스트·달빛가든·대화방이 **같은 자리·같은 그림**을 쓴다(시안 `577,102` / `838,102`).
/// 타이틀만 화면마다 다르다. Prime·루나 그림은 달빛가든 폴더로 전달돼 거기를 가리킨다.
///
/// 📌 포스트(`_TopBar`)와 달빛가든(`_GardenHeader`)에는 같은 코드가 따로 들어 있다 —
/// 대화방부터 이 위젯을 쓰고, 두 화면도 옮기면 셋이 한곳에서 움직인다(아직 안 옮겼다).
class ArtTopBar extends StatelessWidget {
  const ArtTopBar({super.key, required this.title, required this.titleSize});

  final String title;
  final Size titleSize;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
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
        SizedBox(
          width:
              (GardenArt.btnLunaAt.dx -
                  (GardenArt.btnPrimeAt.dx + GardenArt.btnPrimeSize.width)) *
              s,
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(LunaStoreScreen.route()),
          // 그림에는 별만 있고 **숫자가 없다** — 사람마다 다른 값이라 굽지 않는다.
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              ArtImage(
                GardenArt.btnLuna,
                width: GardenArt.btnLunaSize.width,
                height: GardenArt.btnLunaSize.height,
              ),
              const Padding(
                padding: EdgeInsets.only(right: 14),
                child: _LunaCount(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LunaCount extends ConsumerWidget {
  const _LunaCount();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final luna = ref.watch(walletProvider).valueOrNull?.luna;
    if (luna == null) return const SizedBox.shrink();
    return Text(
      '$luna',
      style: const TextStyle(
        color: AppColors.gold,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
