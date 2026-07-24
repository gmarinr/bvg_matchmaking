import '../domain/friendship.dart';
import '../domain/friendship_repository.dart';

class FakeFriendshipRepository implements FriendshipRepository {
  final List<Friendship> _friendships = [];

  @override
  Future<List<Friendship>> getReceivedPending(String userId) async {
    await _tick();
    return _friendships
        .where(
          (friendship) =>
              friendship.addresseeId == userId &&
              friendship.status == FriendshipStatus.pending,
        )
        .toList()
        .reversed
        .toList();
  }

  @override
  Future<List<Friendship>> getSentPending(String userId) async {
    await _tick();
    return _friendships
        .where(
          (friendship) =>
              friendship.requesterId == userId &&
              friendship.status == FriendshipStatus.pending,
        )
        .toList()
        .reversed
        .toList();
  }

  @override
  Future<List<Friendship>> getAccepted(String userId) async {
    await _tick();
    return _friendships
        .where(
          (friendship) =>
              friendship.status == FriendshipStatus.accepted &&
              (friendship.requesterId == userId ||
                  friendship.addresseeId == userId),
        )
        .toList()
        .reversed
        .toList();
  }

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

  @override
  Future<Friendship> acceptRequest(String friendshipId) =>
      _changeStatus(friendshipId, FriendshipStatus.accepted);

  @override
  Future<Friendship> rejectRequest(String friendshipId) =>
      _changeStatus(friendshipId, FriendshipStatus.rejected);

  @override
  Future<Friendship> cancelRequest(String friendshipId) =>
      _changeStatus(friendshipId, FriendshipStatus.cancelled);

  @override
  Future<Friendship> removeFriendship(String friendshipId) =>
      _changeStatus(friendshipId, FriendshipStatus.cancelled);

  Future<Friendship> _changeStatus(
    String friendshipId,
    FriendshipStatus status,
  ) async {
    await _tick();
    final index = _friendships.indexWhere(
      (friendship) => friendship.id == friendshipId,
    );
    if (index < 0) throw StateError('No encontramos la solicitud.');
    final updated = _friendships[index].copyWith(status: status);
    _friendships[index] = updated;
    return updated;
  }

  Future<void> _tick() =>
      Future<void>.delayed(const Duration(milliseconds: 300));
}
