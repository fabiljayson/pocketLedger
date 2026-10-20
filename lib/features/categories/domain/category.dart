import '../../../core/constants/categories.dart';

// ── Category model ───────────────────────────────────────────────────────

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorHex,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String iconKey;
  final String colorHex;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Category.fromMap(Map<String, Object?> map) => Category(
    id: map['id'] as int,
    name: map['name'] as String,
    iconKey: map['icon_key'] as String? ?? fallbackCategoryIconKey,
    colorHex: map['color_hex'] as String? ?? '#64748B',
    isDefault: (map['is_default'] as int? ?? 0) != 0,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'icon_key': iconKey,
    'color_hex': colorHex,
    'is_default': isDefault ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  Category copyWith({
    int? id,
    String? name,
    String? iconKey,
    String? colorHex,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    iconKey: iconKey ?? this.iconKey,
    colorHex: colorHex ?? this.colorHex,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) => other is Category && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
