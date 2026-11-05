import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/step_indicator.dart';
import '../../domain/entities/measurement_set.dart';
import '../bloc/place_order_bloc.dart';
import '../bloc/place_order_event.dart';

/// Step 2 of the 3-step order flow — "Measurements".
///
/// Lets the customer either enter their blouse measurements now ("I know my
/// measurements") or defer them to an in-shop fitting ("Not sure"). The
/// [PlaceOrderBloc] is provided by the parent `/order` ShellRoute, so this
/// screen reads the bloc with `context.read` and does NOT create its own
/// [BlocProvider].
///
/// On "Review order" it builds a [MeasurementSet] from the current selection —
/// parsing each entered numeric field leniently (empty stays `null`) when the
/// customer knows their measurements, or leaving all numeric fields `null` when
/// they are "Not sure" — dispatches [MeasurementsSubmitted], and navigates to
/// the review step.
///
/// Matches the "Order 2/3 – Measurements" mockup.
class OrderMeasurementsStepScreen extends StatefulWidget {
  const OrderMeasurementsStepScreen({super.key});

  @override
  State<OrderMeasurementsStepScreen> createState() =>
      _OrderMeasurementsStepScreenState();
}

class _OrderMeasurementsStepScreenState
    extends State<OrderMeasurementsStepScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Whether the customer is entering measurements now. Defaults to `true`
  /// ("I know my measurements" selected) per the mockup.
  bool _knowsMeasurements = true;

  late final TextEditingController _bustController;
  late final TextEditingController _waistController;
  late final TextEditingController _shoulderController;
  late final TextEditingController _sleeveLengthController;
  late final TextEditingController _armholeController;
  late final TextEditingController _blouseLengthController;
  late final TextEditingController _designNotesController;

  @override
  void initState() {
    super.initState();
    // Prefill from the existing draft measurements (edit case).
    final MeasurementSet? measurements = context
        .read<PlaceOrderBloc>()
        .state
        .draft
        ?.measurements;
    if (measurements != null) {
      _knowsMeasurements = measurements.knowsMeasurements;
    }
    _bustController = TextEditingController(text: _fmt(measurements?.bust));
    _waistController = TextEditingController(text: _fmt(measurements?.waist));
    _shoulderController = TextEditingController(
      text: _fmt(measurements?.shoulder),
    );
    _sleeveLengthController = TextEditingController(
      text: _fmt(measurements?.sleeveLength),
    );
    _armholeController = TextEditingController(
      text: _fmt(measurements?.armhole),
    );
    _blouseLengthController = TextEditingController(
      text: _fmt(measurements?.blouseLength),
    );
    _designNotesController = TextEditingController(
      text: measurements?.designNotes ?? '',
    );
  }

  /// Formats a nullable measurement for prefilling a text field, dropping a
  /// trailing `.0` so e.g. `34.0` shows as "34".
  String _fmt(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  @override
  void dispose() {
    _bustController.dispose();
    _waistController.dispose();
    _shoulderController.dispose();
    _sleeveLengthController.dispose();
    _armholeController.dispose();
    _blouseLengthController.dispose();
    _designNotesController.dispose();
    super.dispose();
  }

  /// Parses a numeric field leniently: empty stays `null`, otherwise
  /// `double.tryParse`. Non-empty values are validated via the form.
  double? _parse(TextEditingController controller) {
    final String text = controller.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  /// Form validator for a measurement field: lenient on empty, but a non-empty
  /// value must be a valid positive measurement.
  String? _measurementValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return Validators.isValidMeasurement(value)
        ? null
        : 'Enter a valid measurement';
  }

  void _onReview() {
    FocusScope.of(context).unfocus();

    final MeasurementSet measurements;
    if (_knowsMeasurements) {
      // Validate only the entered (non-empty) fields.
      if (!(_formKey.currentState?.validate() ?? false)) return;
      final String notes = _designNotesController.text.trim();
      measurements = MeasurementSet(
        knowsMeasurements: true,
        bust: _parse(_bustController),
        waist: _parse(_waistController),
        shoulder: _parse(_shoulderController),
        sleeveLength: _parse(_sleeveLengthController),
        armhole: _parse(_armholeController),
        blouseLength: _parse(_blouseLengthController),
        designNotes: notes.isEmpty ? null : notes,
      );
    } else {
      // "Not sure" — the shop will measure in person; all numeric fields null.
      measurements = const MeasurementSet(knowsMeasurements: false);
    }

    context.read<PlaceOrderBloc>().add(
      MeasurementsSubmitted(measurements: measurements),
    );

    context.pushNamed('orderReview');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('home');
            }
          },
        ),
        title: const Text('Place order'),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    children: <Widget>[
                      const StepIndicator(
                        currentStep: 2,
                        totalSteps: 3,
                        label: 'Measurements',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _OptionCard(
                        title: 'I know my measurements',
                        subtitle: 'Enter them now and we start sooner.',
                        selected: _knowsMeasurements,
                        onTap: () => setState(() => _knowsMeasurements = true),
                      ),
                      const SizedBox(height: AppSpacing.smd),
                      _OptionCard(
                        title: 'Not sure',
                        subtitle: "Visit the shop and we'll measure you.",
                        selected: !_knowsMeasurements,
                        onTap: () => setState(() => _knowsMeasurements = false),
                      ),
                      if (_knowsMeasurements) ...<Widget>[
                        const SizedBox(height: AppSpacing.lg),
                        _MeasurementsHeader(),
                        const SizedBox(height: AppSpacing.md),
                        _MeasurementsGrid(
                          fields: <_MeasurementFieldData>[
                            _MeasurementFieldData(
                              label: 'Bust',
                              hint: '34',
                              controller: _bustController,
                            ),
                            _MeasurementFieldData(
                              label: 'Waist',
                              hint: '28',
                              controller: _waistController,
                            ),
                            _MeasurementFieldData(
                              label: 'Shoulder',
                              hint: '14',
                              controller: _shoulderController,
                            ),
                            _MeasurementFieldData(
                              label: 'Sleeve length',
                              hint: '10',
                              controller: _sleeveLengthController,
                            ),
                            _MeasurementFieldData(
                              label: 'Armhole',
                              hint: '16',
                              controller: _armholeController,
                            ),
                            _MeasurementFieldData(
                              label: 'Blouse length',
                              hint: '15',
                              controller: _blouseLengthController,
                            ),
                          ],
                          validator: _measurementValidator,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _FieldLabel('Design notes (optional)'),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _designNotesController,
                          keyboardType: TextInputType.multiline,
                          minLines: 3,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'e.g. deep back neck, puff sleeves',
                          ),
                        ),
                      ] else ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        _NotSureNote(),
                      ],
                    ],
                  ),
                ),
              ),
              _BottomBar(onReview: _onReview),
            ],
          ),
        ),
      ),
    );
  }
}

/// A selectable radio-style option card. When [selected] it draws an indigo
/// border and tinted fill with a filled radio dot.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Container(
          width: double.infinity,
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _RadioDot(selected: selected),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small circular radio indicator — filled indigo with an inner dot when
/// [selected], hollow grey otherwise.
class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.textTertiary,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }
}

/// "Blouse measurements" heading with a right-aligned "in inches" hint.
class _MeasurementsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Expanded(
          child: Text('Blouse measurements', style: textTheme.titleMedium),
        ),
        Text(
          'in inches',
          style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Immutable description of a single labelled measurement field.
class _MeasurementFieldData {
  const _MeasurementFieldData({
    required this.label,
    required this.hint,
    required this.controller,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
}

/// A responsive 2-column grid of labelled number fields.
class _MeasurementsGrid extends StatelessWidget {
  const _MeasurementsGrid({required this.fields, required this.validator});

  final List<_MeasurementFieldData> fields;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = AppSpacing.md;
        final double columnWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: AppSpacing.md,
          children: <Widget>[
            for (final _MeasurementFieldData field in fields)
              SizedBox(
                width: columnWidth,
                child: _MeasurementField(data: field, validator: validator),
              ),
          ],
        );
      },
    );
  }
}

/// A single labelled numeric measurement field.
class _MeasurementField extends StatelessWidget {
  const _MeasurementField({required this.data, required this.validator});

  final _MeasurementFieldData data;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _FieldLabel(data.label),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: data.controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(hintText: data.hint),
          validator: validator,
        ),
      ],
    );
  }
}

/// Short reassurance note shown when "Not sure" is selected.
class _NotSureNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SectionCard(
      backgroundColor: AppColors.surfaceMuted,
      child: Text(
        "No problem — we'll take your measurements when you visit the shop. "
        'You can continue placing the order now.',
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

/// A small bold label rendered above each form field.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Pinned bottom bar hosting the primary "Review order" action.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onReview});

  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.smd,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: PrimaryButton(label: 'Review order', onPressed: onReview),
      ),
    );
  }
}
