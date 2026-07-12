import 'package:flutter/material.dart';

/// 달빛톡 색상 팔레트 — "밤 / 달빛" 컨셉 다크 테마.
/// 로그인·달빛가든 시안에서 추출한 값.
class AppColors {
  const AppColors._();

  // 배경 (밤하늘) — 근검정 남보라 계열
  static const Color night = Color(0xFF0B0A14); // 페이지 배경
  static const Color surface = Color(0xFF17142A); // 카드 / 시트
  static const Color surfaceHigh = Color(0xFF211C3B); // 강조 서피스
  static const Color glass = Color(0xB817142A); // 반투명 유리 카드(≈72%)
  static const Color border = Color(0xFF2E2A45); // 헤어라인 테두리
  static const Color borderSoft = Color(0x33FFFFFF); // 화이트 20% 테두리

  // 포인트 컬러
  static const Color moonlight = Color(0xFF8B7CF6); // 문라이트 퍼플(주요 강조)
  static const Color moonlightDeep = Color(0xFF6C5CE7);
  static const Color gold = Color(0xFFFFD24C); // 골드/앰버(PICK·활성 탭)

  // 텍스트
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB9B5CC);
  static const Color textMuted = Color(0xFF6E6A85);

  // 소셜 브랜드
  static const Color line = Color(0xFF06C755);
  static const Color kakao = Color(0xFFFEE500);
  static const Color kakaoText = Color(0xFF191600);
  static const Color google = Color(0xFFFFFFFF);
  static const Color googleText = Color(0xFF1F1F1F);

  // 상태
  static const Color danger = Color(0xFFE2504A);

  /// 배경 사진 위에 덧입히는 밤하늘 스크림(아래로 갈수록 어두워짐).
  static const LinearGradient nightScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x000B0A14), Color(0xB30B0A14), Color(0xFF0B0A14)],
    stops: [0.0, 0.5, 0.82],
  );
}
