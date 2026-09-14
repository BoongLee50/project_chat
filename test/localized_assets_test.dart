import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_chat/shared/widgets/design_canvas.dart';

/// 🇯🇵 **언어별 그림(`ja/`)이 실제로 갖춰졌는지** 검사한다.
///
/// 이 앱의 UI 언어는 두 종류다 — 폰트(ARB)와 **글자가 구워진 이미지**.
/// 이미지 쪽은 언어에 따라 **파일 자체가 교체**되는데(docs/14 §2), 그 교체는
/// **한국어로 앱을 켜면 절대 드러나지 않는다.** 일본어로 켠 사람에게만 깨진다.
///
/// 그래서 사람 눈 대신 여기서 잡는다:
///   ① 등록된 그림은 한국어판·일본어판이 **둘 다 디스크에 있는가**
///   ② 두 폴더가 **`pubspec.yaml`에 선언**돼 있는가 (폴더 선언은 **재귀가 아니다**)
///   ③ 두 판의 **규격이 같은가** (다르면 레이아웃이 틀어진다 — `ArtImage`가 원본 크기를 쓴다)
///   ④ `ja/`에 파일만 넣고 **등록을 빠뜨리지 않았는가**
void main() {
  final pubspecAssetDirs = _pubspecAssetDirs();

  group('언어별 그림(ja/)', () {
    test('등록된 그림은 한국어판·일본어판이 둘 다 있다', () {
      for (final ko in DesignCanvas.localizedAssets.keys) {
        final ja = DesignCanvas.japanesePathOf(ko);
        expect(File(ko).existsSync(), isTrue,
            reason: '한국어 원본이 없다: $ko');
        expect(File(ja).existsSync(), isTrue,
            reason: '일본어판이 없다: $ja\n'
                '→ 파일을 넣거나, 아직 못 받았다면 DesignCanvas.localizedAssets에서 $ko 를 뺄 것. '
                '목록에 없으면 한국어가 그대로 나가므로 깨지지 않는다.');
      }
    });

    test('두 폴더가 pubspec.yaml에 선언돼 있다', () {
      // 🚨 Flutter의 에셋 폴더 선언은 **재귀가 아니다.**
      // `assets/images/post/`는 그 폴더의 파일만 포함하고 `post/ja/`는 안 들어간다.
      for (final ko in DesignCanvas.localizedAssets.keys) {
        for (final path in [ko, DesignCanvas.japanesePathOf(ko)]) {
          final dir = '${path.substring(0, path.lastIndexOf('/'))}/';
          expect(pubspecAssetDirs, contains(dir),
              reason: 'pubspec.yaml의 assets에 `- $dir` 줄이 없다. '
                  '파일이 디스크에 있어도 번들에 안 들어간다(함정 #30).');
        }
      }
    });

    test('적어 둔 일본어판 규격이 실제 파일과 맞는다', () {
      // `ArtImage`가 **상수로 받은 크기**로 그리므로, 적어 둔 값이 파일과 다르면
      // 일본어에서만 그림이 눌리거나 늘어난다.
      //   · 값이 null  → 두 판의 규격이 같아야 한다
      //   · 값이 있음  → 그 값이 일본어판 파일의 실제 규격이어야 한다
      DesignCanvas.localizedAssets.forEach((ko, declaredJaSize) {
        final ja = DesignCanvas.japanesePathOf(ko);
        final koSize = _pngSize(File(ko));
        final jaSize = _pngSize(File(ja));
        if (koSize == null || jaSize == null) return; // PNG가 아니면 헤더를 못 읽는다

        if (declaredJaSize == null) {
          expect(jaSize, equals(koSize),
              reason: '규격이 다르다: $ko $koSize vs $ja $jaSize\n'
                  '→ 같은 규격으로 다시 받거나, localizedAssets에 일본어판 규격을 적을 것.');
        } else {
          expect(
              (width: declaredJaSize.width.toInt(),
                  height: declaredJaSize.height.toInt()),
              equals(jaSize),
              reason: 'localizedAssets에 적어 둔 규격이 파일과 다르다: $ja\n'
                  '적은 값 $declaredJaSize / 실제 $jaSize');
        }
      });
    });

    test('ja/ 안의 파일은 빠짐없이 등록돼 있다', () {
      // 파일만 넣고 목록에 안 적으면 **아무 일도 일어나지 않는다** —
      // 한국어가 계속 나가므로 "일본어판을 넣었는데 안 바뀐다"로 한참 헤맨다.
      final registered = {
        for (final ko in DesignCanvas.localizedAssets.keys)
          DesignCanvas.japanesePathOf(ko),
      };

      for (final file in _filesUnderJaFolders()) {
        expect(registered, contains(file),
            reason: '$file 이 목록에 없다.\n'
                '→ DesignCanvas.localizedAssets에 원문 경로를 추가할 것.');
      }
    });
  });

  group('localizedAssetFor', () {
    const registered = 'assets/images/scene_post/back_nopost.png';
    const unregistered = 'assets/images/scene_post/title_post.png';

    test('한국어는 언제나 원문 경로', () {
      expect(DesignCanvas.localizedAssetFor(registered, 'ko'), registered);
      expect(DesignCanvas.localizedAssetFor(unregistered, 'ko'), unregistered);
    });

    test('등록된 그림만 일본어 경로로 바뀐다', () {
      expect(DesignCanvas.localizedAssetFor(registered, 'ja'),
          'assets/images/scene_post/ja/back_nopost.png');
    });

    test('🚨 등록되지 않은 그림은 일본어에서도 원문 그대로', () {
      // 여기가 이 장치의 핵심이다. 없는 `ja/` 경로를 만들면 일본어 사용자에게만 깨진다.
      expect(DesignCanvas.localizedAssetFor(unregistered, 'ja'), unregistered);
    });

    test('두 번 적용해도 결과가 같다', () {
      final once = DesignCanvas.localizedAssetFor(registered, 'ja');
      expect(DesignCanvas.localizedAssetFor(once, 'ja'), once);
    });
  });
}

/// `pubspec.yaml`의 `assets:` 목록에 적힌 폴더들. (`yaml` 패키지 없이 줄만 읽는다)
Set<String> _pubspecAssetDirs() {
  final dirs = <String>{};
  var inAssets = false;
  for (final raw in File('pubspec.yaml').readAsLinesSync()) {
    final line = raw.split('#').first.trimRight();
    if (line.trim() == 'assets:') {
      inAssets = true;
      continue;
    }
    if (!inAssets) continue;

    final match = RegExp(r'^\s*-\s*(\S+)$').firstMatch(line);
    if (match != null) {
      dirs.add(match.group(1)!);
      continue;
    }
    if (line.trim().isNotEmpty) inAssets = false; // 목록이 끝났다
  }
  return dirs;
}

/// `assets/` 아래 이름이 `ja`인 폴더 안의 모든 파일.
List<String> _filesUnderJaFolders() {
  final root = Directory('assets');
  if (!root.existsSync()) return const [];

  return root
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path.replaceAll(r'\', '/'))
      .where((p) => p.contains('/ja/'))
      .toList();
}

/// PNG 헤더(IHDR)에서 규격만 읽는다. PNG가 아니면 null.
({int width, int height})? _pngSize(File file) {
  if (!file.existsSync()) return null;

  final RandomAccessFile handle = file.openSync();
  try {
    final Uint8List head = handle.readSync(24);
    if (head.length < 24) return null;

    const signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    for (var i = 0; i < signature.length; i++) {
      if (head[i] != signature[i]) return null;
    }

    final data = ByteData.sublistView(head);
    return (width: data.getUint32(16), height: data.getUint32(20));
  } finally {
    handle.closeSync();
  }
}
