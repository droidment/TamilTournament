import 'package:cloud_firestore/cloud_firestore.dart';

enum CategoryFormat { group, knockout }

extension CategoryFormatX on CategoryFormat {
  String get value => switch (this) {
    CategoryFormat.group => 'group',
    CategoryFormat.knockout => 'knockout',
  };

  String get label => switch (this) {
    CategoryFormat.group => 'Group',
    CategoryFormat.knockout => 'Knockout',
  };

  static CategoryFormat fromValue(String value) => switch (value) {
    'knockout' => CategoryFormat.knockout,
    _ => CategoryFormat.group,
  };
}

final class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.tournamentId,
    required this.name,
    required this.format,
    required this.minPlayers,
    required this.checkedInPairs,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tournamentId;
  final String name;
  final CategoryFormat format;
  final int minPlayers;
  final int checkedInPairs;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CategoryItem.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CategoryItem(
      id: doc.id,
      tournamentId: data['tournamentId'] as String? ?? '',
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : 'Untitled category',
      format: CategoryFormatX.fromValue(data['format'] as String? ?? 'group'),
      minPlayers: (data['minPlayers'] as num?)?.toInt() ?? 2,
      checkedInPairs: (data['checkedInPairs'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
