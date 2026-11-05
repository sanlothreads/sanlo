import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sanlo/core/entities/gender.dart';
import 'package:sanlo/core/theme/app_colors.dart';
import 'package:sanlo/core/theme/app_spacing.dart';
import 'package:sanlo/core/widgets/responsive_center.dart';
import 'package:sanlo/core/widgets/section_card.dart';
import 'package:sanlo/features/auth/domain/entities/auth_user.dart';
import 'package:sanlo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sanlo/features/profile/domain/entities/user_profile.dart';
import 'package:sanlo/features/profile/domain/repositories/profile_repository.dart';
import 'package:sanlo/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:sanlo/features/profile/presentation/cubit/profile_state.dart';

/// The "Profile" tab — shows the signed-in customer's header (avatar, name,
/// contact), order stats (Total orders / In progress / Ready), and a
/// "Personal details" section (name, mobile, email, gender) per the Profile
/// mockup.
///
/// The bottom navigation bar is provided by the shell scaffold, so this screen
/// renders only the tab content inside a plain [Scaffold].
///
/// The [ProfileCubit] is provided locally, reading the [ProfileRepository]
/// from the widget tree and kicking off [ProfileCubit.load] immediately.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>(
      create: (context) =>
          ProfileCubit(context.read<ProfileRepository>())..load(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: ResponsiveCenter(
          child: BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              final AuthState auth = context.watch<AuthBloc>().state;
              final bool signedIn = auth.isAuthenticated;

              // A guest sees the dedicated "browsing as a Guest" screen rather
              // than the signed-in profile details.
              if (!signedIn) {
                return const _GuestProfileView();
              }

              if (state.loading && state.profile == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.error != null && state.profile == null) {
                return _ErrorBody(message: state.error!);
              }

              final UserProfile? baseProfile = state.profile;
              if (baseProfile == null) {
                return const _ErrorBody(message: 'Profile unavailable');
              }

              // When a real user is signed in, show *their* details rather than
              // the seeded mock profile. Stats stay from the profile repository.
              final UserProfile profile = signedIn
                  ? _mergeAuth(baseProfile, auth.user!)
                  : baseProfile;

              // Editing is only meaningful for a signed-in user (their record is
              // what gets persisted). Guests fall back to the read-only view.
              final bool editing = signedIn && state.editing;

              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                children: <Widget>[
                  _TitleRow(editing: editing, signedIn: signedIn),
                  const SizedBox(height: AppSpacing.lg),
                  _ProfileHeader(profile: profile),
                  const SizedBox(height: AppSpacing.lg),
                  _StatsRow(profile: profile),
                  const SizedBox(height: AppSpacing.lg),
                  if (editing)
                    _EditForm(user: auth.user!)
                  else
                    _PersonalDetails(
                      profile: profile,
                      address: signedIn ? auth.user!.address : null,
                    ),
                  if (signedIn && !editing) ...<Widget>[
                    const SizedBox(height: AppSpacing.lg),
                    const _LogoutButton(),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Overlays the signed-in user's identity onto the displayed profile, keeping
  /// the order stats from [base]. Empty name parts fall back to the base so the
  /// header never shows blanks.
  static UserProfile _mergeAuth(UserProfile base, AuthUser user) {
    final String first = (user.firstName ?? '').trim();
    final String last = (user.lastName ?? '').trim();
    return base.copyWith(
      firstName: first.isNotEmpty ? first : base.firstName,
      lastName: last.isNotEmpty ? last : base.lastName,
      mobile: (user.mobile ?? '').trim().isNotEmpty ? user.mobile : base.mobile,
      email: user.email ?? base.email,
      gender: user.gender ?? base.gender,
    );
  }
}

/// The Profile tab shown to a guest: a hero image, a "browsing as a Guest"
/// headline, Sign in / Continue-as-guest actions, a "Why create an account?"
/// card, and a "Track your order" lookup card.
class _GuestProfileView extends StatelessWidget {
  const _GuestProfileView();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'Profile',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Image.asset(
            'assets/image/sanlo_guest.png',
            height: 160,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          "You're browsing as a Guest",
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Sign in to place orders, save measurements, track orders and more.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.pushNamed('signIn'),
            icon: const Icon(Icons.person_outline),
            label: const Text('Sign in / Create account'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.smd),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.goNamed('home'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            child: const Text('Continue as Guest'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _WhyCreateAccountCard(),
        const SizedBox(height: AppSpacing.md),
        const _TrackOrderCard(),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// The "Why create an account?" benefits card shown to guests.
class _WhyCreateAccountCard extends StatelessWidget {
  const _WhyCreateAccountCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Why create an account?',
      child: Column(
        children: const <Widget>[
          _BenefitRow(
            icon: Icons.shopping_bag_outlined,
            label: 'Faster checkout',
          ),
          _RowDivider(),
          _BenefitRow(
            icon: Icons.straighten_rounded,
            label: 'Save your measurements',
          ),
          _RowDivider(),
          _BenefitRow(
            icon: Icons.inventory_2_outlined,
            label: 'Track your orders',
          ),
          _RowDivider(),
          _BenefitRow(
            icon: Icons.favorite_border_rounded,
            label: 'Save your favorite designs',
          ),
        ],
      ),
    );
  }
}

/// A single icon + label benefit row.
class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A "Track your order" card letting a guest look up an order by id and jump to
/// its tracking screen.
class _TrackOrderCard extends StatefulWidget {
  const _TrackOrderCard();

  @override
  State<_TrackOrderCard> createState() => _TrackOrderCardState();
}

class _TrackOrderCardState extends State<_TrackOrderCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _track() {
    final String raw = _controller.text.trim();
    if (raw.isEmpty) return;
    FocusScope.of(context).unfocus();
    // Normalize "#SN-1041" / "SN-1041" / "1041" to the stored id form.
    String id = raw.replaceAll('#', '').trim();
    if (!id.toUpperCase().startsWith('SN-') && RegExp(r'^\d+$').hasMatch(id)) {
      id = 'SN-$id';
    }
    context.pushNamed(
      'orderTracking',
      pathParameters: <String, String>{'id': id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.smAll,
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Track your order',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Already placed an order? Track it here.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _track(),
                  decoration: const InputDecoration(
                    hintText: 'Order ID : SN-1041',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                height: 48,
                width: 48,
                child: FilledButton(
                  onPressed: _track,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdAll,
                    ),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The "Log out" button shown at the bottom of the Profile screen for a
/// signed-in user. Dispatches [SignOutRequested] and returns to Sign in.
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          context.read<AuthBloc>().add(const SignOutRequested());
          context.goNamed('signIn');
        },
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Log out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
    );
  }
}

/// The screen title "Profile" with an "Edit" tonal button and a subtle
/// "Sign in" affordance (Requirement 7.2) on the trailing side.
class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.editing, required this.signedIn});

  final bool editing;

  /// Whether a real user is signed in. When true the "Sign in" affordance is
  /// hidden (logging out happens via the Log out button instead).
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(
            'Profile',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (!signedIn) ...<Widget>[
          TextButton(
            onPressed: () => context.pushNamed('signIn'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Sign in'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        // The Edit button is hidden while editing — Save / Cancel live in the
        // form itself.
        if (!editing)
          FilledButton.tonal(
            onPressed: () => context.read<ProfileCubit>().startEditing(),
            child: const Text('Edit'),
          ),
      ],
    );
  }
}

/// The circular initials avatar next to the customer's name and contact info.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _InitialsAvatar(
          firstName: profile.firstName,
          lastName: profile.lastName,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${profile.firstName} ${profile.lastName}',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                profile.mobile,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (profile.email != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  profile.email!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A circular indigo avatar showing the customer's initials (first letters of
/// their first and last names).
class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.firstName, required this.lastName});

  final String firstName;
  final String lastName;

  String get _initials {
    final String first = firstName.isNotEmpty ? firstName[0] : '';
    final String last = lastName.isNotEmpty ? lastName[0] : '';
    final String initials = '$first$last'.toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        _initials,
        style: textTheme.titleLarge?.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// The three order-stat tiles: Total orders, In progress, and Ready. The Ready
/// tile uses a light green background per the mockup.
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: _StatTile(value: profile.totalOrders, label: 'Total orders'),
          ),
          const SizedBox(width: AppSpacing.smd),
          Expanded(
            child: _StatTile(value: profile.inProgress, label: 'In progress'),
          ),
          const SizedBox(width: AppSpacing.smd),
          Expanded(
            child: _StatTile(
              value: profile.ready,
              label: 'Ready',
              backgroundColor: AppColors.statusReadyBg,
              valueColor: AppColors.statusReady,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single stat tile rendering a large count above a muted label.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    this.backgroundColor,
    this.valueColor,
  });

  final int value;
  final String label;
  final Color? backgroundColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        children: <Widget>[
          Text(
            '$value',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Personal details" section card listing name, mobile, email, and gender
/// as label/value rows.
class _PersonalDetails extends StatelessWidget {
  const _PersonalDetails({required this.profile, this.address});

  final UserProfile profile;

  /// Optional postal address shown as its own row (from the signed-in user).
  final String? address;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Personal details',
      child: Column(
        children: <Widget>[
          _DetailRow(
            label: 'Name',
            value: '${profile.firstName} ${profile.lastName}',
          ),
          const _RowDivider(),
          _DetailRow(label: 'Mobile', value: profile.mobile),
          const _RowDivider(),
          _DetailRow(label: 'Email', value: profile.email ?? '—'),
          const _RowDivider(),
          _DetailRow(label: 'Gender', value: _genderLabel(profile.gender)),
          const _RowDivider(),
          _DetailRow(
            label: 'Address',
            value: (address ?? '').trim().isEmpty ? '—' : address!.trim(),
          ),
        ],
      ),
    );
  }
}

/// The editable "Personal details" form shown when the user taps Edit.
///
/// Lets the signed-in user edit first name, last name, email, gender, and an
/// optional address. The mobile number is shown read-only and can't change.
/// Save dispatches [ProfileUpdated]; a successful save (bloc returns to
/// [AuthPhase.authenticated]) leaves edit mode. Cancel discards changes.
class _EditForm extends StatefulWidget {
  const _EditForm({required this.user});

  /// The signed-in user whose fields seed the form.
  final AuthUser user;

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late Gender _gender;

  @override
  void initState() {
    super.initState();
    final AuthUser u = widget.user;
    _firstNameController = TextEditingController(text: u.firstName ?? '');
    _lastNameController = TextEditingController(text: u.lastName ?? '');
    _emailController = TextEditingController(text: u.email ?? '');
    _addressController = TextEditingController(text: u.address ?? '');
    _gender = u.gender ?? Gender.female;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String text) {
    final String trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _onSave() {
    FocusScope.of(context).unfocus();
    // Carry the signed-in identity through; the repository pins uid + mobile,
    // so the edited fields are all that change.
    final AuthUser updated = widget.user.copyWith(
      firstName: _nullIfEmpty(_firstNameController.text),
      lastName: _nullIfEmpty(_lastNameController.text),
      email: _nullIfEmpty(_emailController.text),
      gender: _gender,
      address: _nullIfEmpty(_addressController.text),
    );
    context.read<AuthBloc>().add(ProfileUpdated(updated));
  }

  void _onCancel() {
    FocusScope.of(context).unfocus();
    context.read<ProfileCubit>().cancelEditing();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (AuthState p, AuthState c) => p.phase != c.phase,
      listener: (BuildContext context, AuthState state) {
        // Leave edit mode once the save completes successfully.
        if (state.phase == AuthPhase.authenticated) {
          context.read<ProfileCubit>().cancelEditing();
        }
      },
      builder: (BuildContext context, AuthState state) {
        final bool saving = state.phase == AuthPhase.savingProfile;
        final bool hasError =
            state.phase == AuthPhase.error && state.errorMessage != null;

        return SectionCard(
          title: 'Edit details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _FormField(
                      label: 'First name',
                      hint: 'First name',
                      controller: _firstNameController,
                      enabled: !saving,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _FormField(
                      label: 'Last name',
                      hint: 'Last name',
                      controller: _lastNameController,
                      enabled: !saving,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _FormField(
                label: 'Mobile number',
                hint: 'Mobile number',
                controller: TextEditingController(
                  text: widget.user.mobile ?? '',
                ),
                enabled: false,
                readOnly: true,
                helperText: "Mobile can't be changed",
              ),
              const SizedBox(height: AppSpacing.md),
              _FormField(
                label: 'Email (optional)',
                hint: 'Email',
                controller: _emailController,
                enabled: !saving,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Gender',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  _GenderPill(
                    label: 'Female',
                    selected: _gender == Gender.female,
                    onTap: saving
                        ? null
                        : () => setState(() => _gender = Gender.female),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _GenderPill(
                    label: 'Male',
                    selected: _gender == Gender.male,
                    onTap: saving
                        ? null
                        : () => setState(() => _gender = Gender.male),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _GenderPill(
                    label: 'Other',
                    selected: _gender == Gender.other,
                    onTap: saving
                        ? null
                        : () => setState(() => _gender = Gender.other),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _FormField(
                label: 'Address (optional)',
                hint: 'House no., street, area, city',
                controller: _addressController,
                enabled: !saving,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
              ),
              if (hasError) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.errorMessage!,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: saving ? null : _onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.smd,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: saving ? null : _onSave,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.smd,
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A labeled text field used by [_EditForm].
class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.helperText,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          enabled: enabled,
          readOnly: readOnly,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint, helperText: helperText),
        ),
      ],
    );
  }
}

/// A selectable pill for the gender segmented control in [_EditForm]. Mirrors
/// the sign-up screen's pill styling. A null [onTap] disables it.
class _GenderPill extends StatelessWidget {
  const _GenderPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Expanded(
      child: Material(
        color: selected ? AppColors.primaryLight : AppColors.surfaceMuted,
        borderRadius: AppRadius.mdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdAll,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.smd),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single label (muted, left) / value (bold, right) row.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A hairline divider between personal-detail rows.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.border);
  }
}

/// A centered error message shown when the profile fails to load.
class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}

/// Returns a capitalized, human-readable label for [gender], or "—" when null.
String _genderLabel(Gender? gender) {
  switch (gender) {
    case Gender.female:
      return 'Female';
    case Gender.male:
      return 'Male';
    case Gender.other:
      return 'Other';
    case null:
      return '—';
  }
}
