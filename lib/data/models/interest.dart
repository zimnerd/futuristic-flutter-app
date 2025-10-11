class Interest {
  final String id;
  final String name;
  final String categoryId;
  final String? description;
  final bool isActive;
  final int sortOrder;
  final String? iconName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Interest({
    required this.id,
    required this.name,
    required this.categoryId,
    this.description,
    required this.isActive,
    required this.sortOrder,
    this.iconName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      id: json['id'] as String,
      name: json['name'] as String,
      categoryId: json['categoryId'] as String,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
      iconName: json['iconName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'description': description,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'iconName': iconName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Interest &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Interest(id: $id, name: $name)';
}
