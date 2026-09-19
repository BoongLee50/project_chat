import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 대화 신청 · 친구 신청 한마디의 입력 규칙(기획사항 2026-09-19 변경사항).
///
/// *"대화신청과 친구신청의 요청문구의 최대숫자는 100자로 변경 및 통일.
/// 공백, 이모지, 특수문자 까지 모두 문구로 취급. 줄바꾸기는 불가."*
///
/// 두 신청이 **같은 규칙**이라 한 곳에 둔다. 서버의 `common.text.RequestMessages`와 짝이다.
///
/// 🚨 **글자 수는 코드포인트로 센다** — Flutter의 `maxLength`는 *글자 모양*(grapheme) 단위라
/// `👍🏽`·`👨‍👩‍👧`처럼 여러 코드포인트로 된 이모지를 1로 센다. 서버와 DB(`VARCHAR`)는
/// 코드포인트로 세므로, 그대로 두면 **화면은 받아 놓고 서버가 거절**한다.
/// 그래서 `maxLength`를 쓰지 않고 이 규칙으로 막는다.
class RequestMessageInput {
  const RequestMessageInput._();

  /// 대화 신청 한도를 서버에서 못 받았을 때의 기본값. 친구 신청은 서버가 숫자를 주지 않아 이 값을 쓴다.
  /// ⚠️ 서버 `app.chat/friend.request-message-max-length`와 같아야 한다.
  static const int defaultMax = 100;

  /// 서버와 같은 단위의 길이.
  static int length(String text) => text.runes.length;

  static List<TextInputFormatter> formatters(int max) => [
    const _NoLineBreak(),
    _CodePointLimit(max),
  ];
}

/// 줄바꿈을 공백으로 바꾼다 — 엔터·붙여넣기 모두. (서버도 같은 일을 한다)
class _NoLineBreak extends TextInputFormatter {
  const _NoLineBreak();

  static final _breaks = RegExp('\r\n|[\r\n  ]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!_breaks.hasMatch(newValue.text)) return newValue;
    final text = newValue.text.replaceAll(_breaks, ' ');
    // 바꾼 뒤 길이가 달라질 수 있어(\r\n → 공백 하나) 커서는 끝 쪽으로 맞춘다.
    final offset = (newValue.selection.baseOffset -
            (newValue.text.length - text.length))
        .clamp(0, text.length);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// 코드포인트 [max]개까지만. 넘치면 **글자 모양 단위로** 뒤를 자른다 —
/// 결합 이모지가 반쪽으로 남지 않게 한다.
class _CodePointLimit extends TextInputFormatter {
  const _CodePointLimit(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.runes.length <= max) return newValue;
    final buffer = StringBuffer();
    var used = 0;
    for (final ch in newValue.text.characters) {
      final n = ch.runes.length;
      if (used + n > max) break;
      buffer.write(ch);
      used += n;
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
