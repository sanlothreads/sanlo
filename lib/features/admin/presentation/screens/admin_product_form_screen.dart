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
  late final TextEditingController _description;
  final List<TextEditingController> _urlControllers = <TextEditingController>[];
  late CategoryKind _category;
  late ProductVisibility _visibility;
  bool _isSaving = false;

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
    _description = TextEditingController(text: p?.description ?? '');
    _category = p?.category ?? CategoryKind.women;
    _visibility = p?.visibility ?? ProductVisibility.live;

    if (p != null && p.imageUrls.isNotEmpty) {
      for (final String url in p.imageUrls) {
        _urlControllers.add(TextEditingController(text: url));
      }
    } else {
      _urlControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stitchDays.dispose();
    _rating.dispose();
    _description.dispose();
    for (final TextEditingController controller in _urlControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addUrlField() {
    if (_urlControllers.length < 6) {
      setState(() {
        _urlControllers.add(TextEditingController());
      });
    }
  }

  void _removeUrlField(int index) {
    if (_urlControllers.length > 1) {
      final TextEditingController controller = _urlControllers.removeAt(index);
      controller.dispose();
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    final List<String> urls = _urlControllers
        .map((c) => c.text.trim())
        .where((u) => u.isNotEmpty)
        .toList();

    if (urls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 1 image URL is mandatory')),
      );
      return;
    }

    if (urls.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 image URLs allowed')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final AdminProduct product = AdminProduct(
      id: widget.product?.id ?? 'p_${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      category: _category,
      priceInr: int.parse(_price.text.trim()),
      stitchDays: int.tryParse(_stitchDays.text.trim()) ?? 0,
      rating: double.tryParse(_rating.text.trim()) ?? 0,
      photoCount: urls.length,
      visibility: _visibility,
      description: _description.text.trim(),
      imageUrls: urls,
    );

    await context.read<AdminProductsCubit>().saveProduct(product);
    if (!mounted) return;
    widget.onDone();
  }

  Future<void> _delete() async {
    if (widget.product == null || _isSaving) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product'),
        content: Text('Are you sure you want to delete "${widget.product!.name}"?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSaving = true);
    await context.read<AdminProductsCubit>().deleteProduct(widget.product!.id);
    if (!mounted) return;
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
                  _imageUrlsSection(),
                  _visibilityField(),
                  _field(
                    label: 'Description',
                    controller: _description,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: _isEditing ? 'Save changes' : 'Add product',
                    loading: _isSaving,
                    onPressed: _save,
                  ),
                  if (_isEditing) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        onPressed: _isSaving ? null : _delete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete product'),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : widget.onDone,
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

  Widget _imageUrlsSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'Product Image URLs (Min 1, Max 6)*',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_urlControllers.length}/6',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (int i = 0; i < _urlControllers.length; i++) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _urlControllers[i],
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        hintText: 'Image URL ${i + 1} (e.g. https://...)',
                        isDense: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter image URL';
                        }
                        return null;
                      },
                    ),
                  ),
                  if (_urlControllers.length > 1) ...<Widget>[
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      onPressed: () => _removeUrlField(i),
                      tooltip: 'Remove URL',
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (_urlControllers.length < 6) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton.icon(
              onPressed: _addUrlField,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add image URL'),
            ),
          ],
        ],
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
