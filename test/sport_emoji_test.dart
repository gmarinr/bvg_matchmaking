import 'package:flutter_test/flutter_test.dart';

import 'package:bvg_matchmaking/core/utils/sport_emojis.dart';

void main() {
  test('resuelve un emoji por id y comparte tenis/padel', () {
    expect(sportEmoji('futbol'), '\u{26BD}');
    expect(sportEmoji('basquetbol'), '\u{1F3C0}');
    expect(sportEmoji('tenis'), '\u{1F3BE}');
    expect(sportEmoji('padel'), '\u{1F3BE}');
  });

  test('usa un fallback neutro para deportes no mapeados', () {
    expect(sportEmoji('deporte-nuevo'), '\u{1F3C5}');
  });
}
