import '../domain/friendship.dart';
import '../domain/friendship_repository.dart';

class FakeFriendshipRepository implements FriendshipRepository {
  final List<Friendship> _friendships = [];

  @override
  Future<Friendship?> getBetween({
    required String currentUserId,
    required String otherUserId,
  }) async {
    await _tick();
    for (final friendship in _friendships.reversed) {
      final samePair =
          (friendship.requesterId == currentUserId &&
              friendship.addresseeId == otherUserId) ||
          (friendship.requesterId == otherUserId &&
              friendship.addresseeId == currentUserId);
      if (samePair &&
          friendship.status != FriendshipStatus.rejected &&
          friendship.status != FriendshipStatus.cancelled) {
        return friendship;
      }
    }
    return null;
  }

  @override
  Future<Friendship> sendRequest({
    required String requesterId,
    required String addresseeId,
  }) async {
    await _tick();
    if (requesterId == addresseeId) {
      throw ArgumentError('No puedes enviarte una solicitud.');
    }

    final active = await getBetween(
      currentUserId: requesterId,
      otherUserId: addresseeId,
    );
    if (active != null) {
      throw StateError('Ya existe una solicitud o amistad activa.');
    }

    final friendship = Friendship(
      id: 'fake-friendship-${_friendships.length + 1}',
      requesterId: requesterId,
      addresseeId: addresseeId,
      status: FriendshipStatus.pending,
    );
    _friendships.add(friendship);
    return friendship;
  }

  Future<void> _tick() =>
      Future<void>.delayed(const Duration(milliseconds: 300));
}
