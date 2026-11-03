import '../../domain/entities/category.dart';

/// Data-layer DTO for [Category]. Serialises [CategoryKind] as its enum name.
class CategoryModel {
  const CategoryModel({required this.kind, required this.label});

  final String kind;
  final String label;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      kind: json['kind'] as String,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'kind': kind, 'label': label};
  }

  factory CategoryModel.fromEntity(Category entity) {
    return CategoryModel(kind: entity.kind.name, label: entity.label);
  }

  Category toEntity() {
    return Category(kind: CategoryKind.values.byName(kind), label: label);
  }
}
