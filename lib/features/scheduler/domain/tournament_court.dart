import 'package:cloud_firestore/cloud_firestore.dart';

enum TournamentCourtStatus { available, unavailable }

extension TournamentCourtStatusX on TournamentCourtStatus {
  String get value => switch (this) {
    TournamentCourtStatus.available => 'available',
    TournamentCourtStatus.unavailable => 'unavailable',
  };

  String get label => switch (this) {
    TournamentCourtStatus.available => 'Available',
    TournamentCourtStatus.unavailable => 'Unavailable',
  };

  static TournamentCourtStatus fromValue(String value) => switch (value) {
    'unavailable' => TournamentCourtStatus.unavailable,
    _ => TournamentCourtStatus.available,
  };
}

final class TournamentCourt {
  const TournamentCourt({
    required this.id,
    required this.tournamentId,
    required this.code,
    required this.name,
    required this.status,
    required this.orderIndex,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tournamentId;
  final String code;
  final String name;
  final TournamentCourtStatus status;
  final int orderIndex;
  final String note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAvailable => status == TournamentCourtStatus.available;

  factory TournamentCourt.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return TournamentCourt(
      id: doc.id,
      tournamentId: data['tournamentId'] as String? ?? '',
      code: (data['code'] as String?)?.trim().isNotEmpty == true
          ? (data['code'] as String).trim()
          : 'C${((data['orderIndex'] as num?)?.toInt() ?? 0) + 1}',
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : 'Court',
      status: TournamentCourtStatusX.fromValue(
        data['status'] as String? ?? TournamentCourtStatus.available.value,
      ),
      orderIndex: (data['orderIndex'] as num?)?.toInt() ?? 0,
      note: (data['note'] as String?)?.trim() ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
