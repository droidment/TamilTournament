import 'package:cloud_firestore/cloud_firestore.dart';

enum TournamentRoleType { organizer, assistant, referee }

extension TournamentRoleTypeX on TournamentRoleType {
  String get value => switch (this) {
    TournamentRoleType.organizer => 'organizer',
    TournamentRoleType.assistant => 'assistant',
    TournamentRoleType.referee => 'referee',
  };

  String get label => switch (this) {
    TournamentRoleType.organizer => 'Organizer',
    TournamentRoleType.assistant => 'Assistant',
    TournamentRoleType.referee => 'Referee',
  };

  static TournamentRoleType fromValue(String value) => switch (value) {
    'assistant' => TournamentRoleType.assistant,
    'referee' => TournamentRoleType.referee,
    _ => TournamentRoleType.organizer,
  };
}

final class TournamentRole {
  const TournamentRole({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.assignedAt,
    required this.assignedBy,
  });

  final String id;
  final String tournamentId;
  final String userId;
  final String email;
  final String displayName;
  final TournamentRoleType role;
  final bool isActive;
  final DateTime? assignedAt;
  final String assignedBy;

  factory TournamentRole.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String tournamentId,
  }) {
    final data = doc.data() ?? <String, dynamic>{};
    return TournamentRole(
      id: doc.id,
      tournamentId: tournamentId,
      userId: data['userId'] as String? ?? '',
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: TournamentRoleTypeX.fromValue(data['role'] as String? ?? ''),
      isActive: data['isActive'] as bool? ?? true,
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate(),
      assignedBy: data['assignedBy'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'role': role.value,
      'isActive': isActive,
      'assignedAt': assignedAt != null
          ? Timestamp.fromDate(assignedAt!)
          : FieldValue.serverTimestamp(),
      'assignedBy': assignedBy,
    };
  }
}
