import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../domain/entities/admin_product.dart';
import '../cubit/admin_products_cubit.dart';

/// Add/Edit product form. When [product] is null the form adds a new product;
/// otherwise it pre-fills and updates the existing one. Saving upserts through
/// [AdminProductsCubit] and pops.
class AdminProductFormScreen extends StatefulWidget {
  const AdminProductFormScreen({super.key, this.product, required this.onDone});

  final AdminProduct? product;
  final VoidCallback onDone;

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _stitchDays;
  late final TextEditingController _rating;
  late final TextEditingController _photoCount;
  late final TextEditingController _description;
  late CategoryKind _category;
  late ProductVisibility _visibility;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final AdminProduct? p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: p != null ? '${p.priceInr}' : '');
    _stitchDays = TextEditingController(
      text: p != null ? '${p.stitchDays}' : '',
    );
    _rating = TextEditingController(text: p != null ? '${p.rating}' : '');
    _photoCount = TextEditingController(
      text: p != null ? '${p.photoCount}' : '',
    );
    _description = TextEditingController(text: p?.description ?? '');
    _category = p?.category ?? CategoryKind.women;
    _visibility = p?.visibility ?? ProductVisibility.live;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stitchDays.dispose();
    _rating.dispose();
    _photoCount.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final AdminProduct product = AdminProduct(
      id: widget.product?.id ?? 'p_${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      category: _category,
      priceInr: int.parse(_price.text.trim()),
      stitchDays: int.tryParse(_stitchDays.text.trim()) ?? 0,
      rating: double.tryParse(_rating.text.trim()) ?? 0,
      photoCount: int.tryParse(_photoCount.text.trim()) ?? 0,
      visibility: _visibility,
      description: _description.text.trim(),
    );

    context.read<AdminProductsCubit>().upsertProduct(product);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(title: Text(_isEditing ? 'Edit product' : 'Add product')),
      body: SafeArea(
        child: ResponsiveCenter(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _field(
                    label: 'Product name',
                    controller: _name,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter a product name'
                        : null,
                  ),
                  _categoryField(),
                  _field(
                    label: 'Price (\u20B9)',
                    controller: _price,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (v) {
                      final int? n = int.tryParse((v ?? '').trim());
                      if (n == null || n <= 0) return 'Enter a valid price';
                      return null;
                    },
                  ),
                  _field(
                    label: 'Stitch time (days)',
                    controller: _stitchDays,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  _field(
                    label: 'Rating',
                    controller: _rating,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  _field(
                    label: 'Photos',
                    controller: _photoCount,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  _visibilityField(),
                  _field(
                    label: 'Description',
                    controller: _description,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: _isEditing ? 'Save changes' : 'Add product',
                    onPressed: _save,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: widget.onDone,
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
          ),
        ],
      ),
    );
  }

  Widget _categoryField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Category',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          DropdownButtonFormField<CategoryKind>(
            initialValue: _category,
            items: const <DropdownMenuItem<CategoryKind>>[
              DropdownMenuItem(value: CategoryKind.women, child: Text('Women')),
              DropdownMenuItem(value: CategoryKind.men, child: Text('Men')),
              DropdownMenuItem(value: CategoryKind.kids, child: Text('Kids')),
            ],
            onChanged: (v) =>
                setState(() => _category = v ?? CategoryKind.women),
          ),
        ],
      ),
    );
  }

  Widget _visibilityField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Text(
              'Visible to customers',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: _visibility == ProductVisibility.live,
            onChanged: (on) => setState(
              () => _visibility = on
                  ? ProductVisibility.live
                  : ProductVisibility.hidden,
            ),
          ),
        ],
      ),
    );
  }
}
