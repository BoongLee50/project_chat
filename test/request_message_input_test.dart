import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_chat/shared/widgets/request_message_input.dart';

/// 대화·친구 신청 한마디 입력 규칙(기획사항 2026-09-19): 100자 · 줄바꿈 불가 · 이모지·공백도 한 글자.
///
/// 🚨 서버·DB는 **코드포인트**로 센다. Flutter `maxLength`(글자 모양 단위)로 막으면
/// 결합 이모지에서 "화면은 받고 서버는 거절"이 생긴다 — 이 테스트가 그 어긋남을 지킨다.
void main() {
  /// 빈 칸에 [text]를 한 번에 넣었을 때(붙여넣기) 입력칸에 남는 값.
  TextEditingValue apply(String text, {int max = 100}) {
    var value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    for (final f in RequestMessageInput.formatters(max)) {
      value = f.formatEditUpdate(TextEditingValue.empty, value);
    }
    return value;
  }

  test('줄바꿈은 공백으로 바뀐다(엔터·붙여넣기 모두)', () {
    expect(apply('안녕\n하세요\r\n반가워요').text, '안녕 하세요 반가워요');
  });

  test('길이는 코드포인트로 센다 — 👍🏽 는 2', () {
    expect(RequestMessageInput.length('👍🏽'), 2);
    expect(RequestMessageInput.length('a b'), 3); // 공백도 한 글자
  });

  test('넘치면 자르되 결합 이모지를 반쪽으로 남기지 않는다', () {
    // 99자 + 👍🏽(2) = 101 → 이모지 통째로 빠지고 99자만 남는다.
    final out = apply('${'a' * 99}👍🏽').text;
    expect(out, 'a' * 99);
    expect(RequestMessageInput.length(out) <= 100, isTrue);
  });

  test('정확히 100이면 그대로 둔다', () {
    final text = '👍🏽' * 50; // 코드포인트 100
    expect(apply(text).text, text);
  });

  test('기본 한도는 서버와 같은 100', () {
    expect(RequestMessageInput.defaultMax, 100);
  });
}
