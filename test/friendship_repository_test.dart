import 'package:bvg_matchmaking/features/friendships/data/fake_friendship_repository.dart';
import 'package:bvg_matchmaking/features/friendships/domain/friendship.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('permite enviar, aceptar y eliminar una amistad', () async {
    final repository = FakeFriendshipRepository();

    final request = await repository.sendRequest(
      requesterId: 'user-a',
      addresseeId: 'user-b',
    );
    expect(request.status, FriendshipStatus.pending);
    expect(
      (await repository.getReceivedPending('user-b')).single.id,
      request.id,
    );

    final accepted = await repository.acceptRequest(request.id);
    expect(accepted.status, FriendshipStatus.accepted);
    expect((await repository.getAccepted('user-a')).single.id, request.id);

    final removed = await repository.removeFriendship(request.id);
    expect(removed.status, FriendshipStatus.cancelled);
    expect(await repository.getAccepted('user-a'), isEmpty);
  });

  test('no permite solicitudes activas duplicadas', () async {
    final repository = FakeFriendshipRepository();
    await repository.sendRequest(requesterId: 'user-a', addresseeId: 'user-b');

    await expectLater(
      repository.sendRequest(
        requesterId: 'user-b',
        addresseeId: 'user-a',
      ),
      throwsA(isA<StateError>()),
    );
  });
}
