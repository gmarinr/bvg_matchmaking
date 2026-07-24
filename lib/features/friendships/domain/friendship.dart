enum FriendshipStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  cancelled('cancelled');

  const FriendshipStatus(this.wire);

  final String wire;

  static FriendshipStatus fromWire(String value) =>
      values.firstWhere((status) => status.wire == value);
}

class Friendship {
  const Friendship({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
  });

  final String id;
  final String requesterId;
  final String addresseeId;
  final FriendshipStatus status;

  factory Friendship.fromJson(Map<String, dynamic> json) => Friendship(
    id: json['id'] as String,
    requesterId: json['requester_id'] as String,
    addresseeId: json['addressee_id'] as String,
    status: FriendshipStatus.fromWire(json['status'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'requester_id': requesterId,
    'addressee_id': addresseeId,
    'status': status.wire,
  };
}
