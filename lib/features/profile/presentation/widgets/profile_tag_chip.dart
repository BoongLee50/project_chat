import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../data/models/profile_catalog.dart';

/// 관심사·활동 지역 칩 — [작성하기]와 [미리 보기]가 함께 쓴다(Scene_Profile).
///
/// 🚨 **칩은 그림이다**(기획 2026-09-19). 아이콘과 이름이 한 장에 구워져 온다 —
/// 관심사 `Interest_movie.png` 204×89, 지역 `region_seoul.png` 210×88.
/// 지금은 그 두 장뿐이라 나머지는 **같은 규격·같은 색의 자리 칩**을 코드가 그린다.
/// 그림이 오면 [ProfileCatalog.interestArt]·[ProfileCatalog.regionArt]에 한 줄씩 더하면 끝이다.
class ProfileTagChip extends StatelessWidget {
  const ProfileTagChip.interest(this.code, {super.key}) : isRegion = false;

  const ProfileTagChip.region(this.code, {super.key}) : isRegion = true;

  final String code;
  final bool isRegion;

  /// 시안 원본 규격(1080 캔버스).
  static const Size interestSize = Size(204, 89);
  static const Size regionSize = Size(210, 88);

  /// 그림의 바탕색(`region_seoul.png` 가운데 픽셀) — 자리 칩이 그림과 나란히 서도 튀지 않게.
  static const Color _fill = Color(0xFF454545);

  @override
  Widget build(BuildContext context) {
    final size = isRegion ? regionSize : interestSize;
    final art = isRegion
        ? ProfileCatalog.regionArt[code]
        : ProfileCatalog.interestArt[code];
    if (art != null) {
      return ArtImage(art, width: size.width, height: size.height);
    }

    final s = DesignCanvas.scaleOf(context);
    final l10n = L10n.of(context);
    final label = isRegion
        ? ProfileCatalog.cityLabel(l10n, code)
        : ProfileCatalog.interestLabel(l10n, code);

    return Container(
      width: size.width * s,
      height: size.height * s,
      padding: EdgeInsets.symmetric(horizontal: 18 * s),
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(size.height / 2 * s),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isRegion) ...[
            // 🚧 자리 표시 — 관심사 그림이 오면 사라진다(08 §0-2).
            Icon(
              ProfileCatalog.interestIcon(code),
              color: Colors.white,
              size: 42 * s,
            ),
            SizedBox(width: 12 * s),
          ],
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36 * s,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
