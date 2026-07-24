import 'package:bvg_matchmaking/features/communes/data/fake_commune_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el catálogo fake contiene las 346 comunas nacionales', () async {
    final communes = await FakeCommuneRepository().getCommunes();

    expect(communes, hasLength(346));
    expect(communes.map((commune) => commune.name).toSet(), hasLength(346));
    expect(communes.any((commune) => commune.name == 'Ñuñoa'), isTrue);
    expect(communes.any((commune) => commune.name == 'Arica'), isTrue);
  });
}
