import 'commune.dart';

abstract interface class CommuneRepository {
  Future<List<Commune>> getCommunes();
}
