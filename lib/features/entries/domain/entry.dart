import 'package:cloud_firestore/cloud_firestore.dart';

final class TournamentEntry {
  const TournamentEntry({
    required this.id,
    required this.tournamentId,
    required this.categoryId,
    required this.teamName,
    required this.playerOne,
    required this.playerTwo,
    required this.seedNumber,
    required this.categoryName,
    required this.checkedIn,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tournamentId;
  final String categoryId;
  final String teamName;
  final String playerOne;
  final String playerTwo;
  final int? seedNumber;
  final String categoryName;
  final bool checkedIn;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasAssignedSeed => seedNumber != null;

  String get rosterLabel {
    final participants = <String>[
      if (playerOne.trim().isNotEmpty) playerOne.trim(),
      if (playerTwo.trim().isNotEmpty) playerTwo.trim(),
    ];
    return participants.join(' / ');
  }

  String get displayLabel {
    if (teamName.trim().isNotEmpty) {
      return teamName.trim();
    }
    if (rosterLabel.isNotEmpty) {
      return rosterLabel;
    }
    return 'Unnamed team';
  }

  String get detailLabel {
    if (teamName.trim().isNotEmpty && rosterLabel.isNotEmpty) {
      return '$teamName · $rosterLabel';
    }
    return displayLabel;
  }

  factory TournamentEntry.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return TournamentEntry(
      id: doc.id,
      tournamentId: data['tournamentId'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      teamName: (data['teamName'] as String?)?.trim() ?? '',
      playerOne: (data['playerOne'] as String?)?.trim().isNotEmpty == true
          ? (data['playerOne'] as String).trim()
          : 'Player One',
      playerTwo: (data['playerTwo'] as String?)?.trim().isNotEmpty == true
          ? (data['playerTwo'] as String).trim()
          : 'Player Two',
      seedNumber: _normalizeSeedNumber((data['seedNumber'] as num?)?.toInt()),
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
    required String categoryId,
    required String teamName,
    required String playerOne,
    required String playerTwo,
    required int? seedNumber,
    required String categoryName,
    required bool checkedIn,
  }) {
    final now = FieldValue.serverTimestamp();
    final map = <String, Object>{
      'tournamentId': tournamentId,
      'categoryId': categoryId,
      'playerOne': playerOne.trim(),
      'playerTwo': playerTwo.trim(),
      'categoryName': categoryName.trim(),
      'checkedIn': checkedIn,
      'createdAt': now,
      'updatedAt': now,
    };
    final normalizedTeamName = teamName.trim();
    if (normalizedTeamName.isNotEmpty) {
      map['teamName'] = normalizedTeamName;
    }
    final normalizedSeedNumber = _normalizeSeedNumber(seedNumber);
    if (normalizedSeedNumber != null) {
      map['seedNumber'] = normalizedSeedNumber;
    }
    return map;
  }
}

int compareEntriesForSeeding(TournamentEntry left, TournamentEntry right) {
  final leftSeed = left.seedNumber;
  final rightSeed = right.seedNumber;
  if (leftSeed != null && rightSeed != null) {
    final bySeed = leftSeed.compareTo(rightSeed);
    if (bySeed != 0) {
      return bySeed;
    }
  } else if (leftSeed != null) {
    return -1;
  } else if (rightSeed != null) {
    return 1;
  }

  final leftCreatedAt = left.createdAt ?? left.updatedAt;
  final rightCreatedAt = right.createdAt ?? right.updatedAt;

  final leftTime = leftCreatedAt?.millisecondsSinceEpoch ?? 0;
  final rightTime = rightCreatedAt?.millisecondsSinceEpoch ?? 0;
  final byTime = leftTime.compareTo(rightTime);
  if (byTime != 0) {
    return byTime;
  }

  final byLabel = left.displayLabel.toLowerCase().compareTo(
    right.displayLabel.toLowerCase(),
  );
  if (byLabel != 0) {
    return byLabel;
  }

  return left.id.compareTo(right.id);
}

int? _normalizeSeedNumber(int? value) {
  if (value == null || value <= 0) {
    return null;
  }
  return value;
}
