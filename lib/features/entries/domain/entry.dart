import 'package:cloud_firestore/cloud_firestore.dart';

final class TournamentEntry {
  const TournamentEntry({
    required this.id,
    required this.tournamentId,
    required this.playerOne,
    required this.playerTwo,
    required this.categoryName,
    required this.checkedIn,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tournamentId;
  final String playerOne;
  final String playerTwo;
  final String categoryName;
  final bool checkedIn;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TournamentEntry.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return TournamentEntry(
      id: doc.id,
      tournamentId: data['tournamentId'] as String? ?? '',
      playerOne: (data['playerOne'] as String?)?.trim().isNotEmpty == true
          ? (data['playerOne'] as String).trim()
          : 'Player One',
      playerTwo: (data['playerTwo'] as String?)?.trim().isNotEmpty == true
          ? (data['playerTwo'] as String).trim()
          : 'Player Two',
      categoryName: (data['categoryName'] as String?)?.trim().isNotEmpty == true
          ? (data['categoryName'] as String).trim()
          : 'Unassigned',
      checkedIn: data['checkedIn'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, Object> toCreateMap({
    required String tournamentId,
    required String playerOne,
    required String playerTwo,
    required String categoryName,
  }) {
    final now = FieldValue.serverTimestamp();
    return <String, Object>{
      'tournamentId': tournamentId,
      'playerOne': playerOne.trim(),
      'playerTwo': playerTwo.trim(),
      'categoryName': categoryName.trim(),
      'checkedIn': checkedIn,
      'createdAt': now,
      'updatedAt': now,
    };
  }
}
