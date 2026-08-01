import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/config/app_config.dart';
import '../../core/providers.dart';

/// 인증이 필요한 서버 이미지(`GET /files?key=...`) 로더.
///
/// 서버는 **상대 경로**를 주고 그 엔드포인트는 JWT를 요구하므로,
/// base URL을 붙이고 Authorization 헤더를 직접 넘겨야 한다
/// (`Image.network`는 dio 인터셉터를 타지 않는다).
class AuthedImage extends ConsumerWidget {
  const AuthedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  final String url;
  final BoxFit fit;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headers = ref.watch(authHeadersProvider).valueOrNull;
    if (headers == null || headers.isEmpty) {
      return fallback ?? const ColoredBox(color: AppColors.surface);
    }
    return Image.network(
      absoluteUrl(url),
      fit: fit,
      headers: headers,
      errorBuilder: (_, _, _) =>
          fallback ?? const ColoredBox(color: AppColors.surface),
    );
  }

  /// 서버가 준 상대 경로에 API base URL을 붙인다(절대 URL이면 그대로).
  static String absoluteUrl(String url) =>
      url.startsWith('http') ? url : '${AppConfig.apiBaseUrl}$url';
}
