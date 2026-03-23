import 'package:cloud_firestore/cloud_firestore.dart';

enum TournamentStatus { draft, setup, live, completed }

extension TournamentStatusX on TournamentStatus {
  String get value => switch (this) {
    TournamentStatus.draft => 'draft',
    TournamentStatus.setup => 'setup',
    TournamentStatus.live => 'live',
    TournamentStatus.completed => 'completed',
  };

  String get label => switch (this) {
    TournamentStatus.draft => 'Draft',
    TournamentStatus.setup => 'Setup',
    TournamentStatus.live => 'Live',
    TournamentStatus.completed => 'Completed',
  };

  static TournamentStatus fromValue(String value) => switch (value) {
    'setup' => TournamentStatus.setup,
    'live' => TournamentStatus.live,
    'completed' => TournamentStatus.completed,
    _ => TournamentStatus.draft,
  };
}

final class TournamentStats {
  const TournamentStats({
    required this.categories,
    required this.entries,
    required this.matches,
  });

  final int categories;
  final int entries;
  final int matches;

  factory TournamentStats.fromMap(Map<String, dynamic>? map) {
    return TournamentStats(
      categories: (map?['categories'] as num?)?.toInt() ?? 0,
      entries: (map?['entries'] as num?)?.toInt() ?? 0,
      matches: (map?['matches'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object> toMap() {
    return <String, Object>{
      'categories': categories,
      'entries': entries,
      'matches': matches,
    };
  }
}

final class Tournament {
  const Tournament({
    required this.id,
    required this.name,
    required this.venue,
    required this.startDate,
    required this.organizerUid,
    required this.status,
    required this.activeCourtCount,
    required this.stats,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String venue;
  final DateTime startDate;
  final String organizerUid;
  final TournamentStatus status;
  final int activeCourtCount;
  final TournamentStats stats;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Tournament.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Tournament(
      id: doc.id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : 'Untitled tournament',
      venue: (data['venue'] as String?)?.trim().isNotEmpty == true
          ? (data['venue'] as String).trim()
          : 'Venue TBD',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      organizerUid: data['organizerUid'] as String? ?? '',
      status: TournamentStatusX.fromValue(
        data['status'] as String? ?? TournamentStatus.draft.value,
      ),
      activeCourtCount: (data['activeCourtCount'] as num?)?.toInt() ?? 0,
      stats: TournamentStats.fromMap(data['stats'] as Map<String, dynamic>?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
