import 'package:equatable/equatable.dart';

/// The catalog category a product belongs to.
///
/// [all] is the sentinel value used by the Category_Filter to mean
/// "no filter" (show every product); it is never used as a product's own
/// category.
enum CategoryKind { all, women, men, kids }

/// A selectable catalog category shown in the Category_Filter chips.
///
/// The [all] kind is the sentinel meaning "no filter".
class Category extends Equatable {
  const Category({required this.kind, required this.label});

  /// The category this entry represents. [CategoryKind.all] is the
  /// sentinel meaning no filter is applied.
  final CategoryKind kind;

  /// Human-readable label, e.g. "All", "Women", "Men", "Kids".
  final String label;

  Category copyWith({CategoryKind? kind, String? label}) {
    return Category(
      kind: kind ?? this.kind,
      label: label ?? this.label,
    );
  }

  @override
  List<Object?> get props => [kind, label];
}
