import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sanlo/core/entities/gender.dart';
import 'package:sanlo/core/theme/app_colors.dart';
import 'package:sanlo/core/theme/app_spacing.dart';
import 'package:sanlo/core/widgets/section_card.dart';
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
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state.loading && state.profile == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.error != null && state.profile == null) {
              return _ErrorBody(message: state.error!);
            }

            final UserProfile? profile = state.profile;
            if (profile == null) {
              return const _ErrorBody(message: 'Profile unavailable');
            }

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              children: <Widget>[
                _TitleRow(editing: state.editing),
                const SizedBox(height: AppSpacing.lg),
                _ProfileHeader(profile: profile),
                const SizedBox(height: AppSpacing.lg),
                _StatsRow(profile: profile),
                const SizedBox(height: AppSpacing.lg),
                _PersonalDetails(profile: profile),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The screen title "Profile" with an "Edit" tonal button and a subtle
/// "Sign in" affordance (Requirement 7.2) on the trailing side.
class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.editing});

  final bool editing;

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
        FilledButton.tonal(
          onPressed: () => context.read<ProfileCubit>().startEditing(),
          child: Text(editing ? 'Editing' : 'Edit'),
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
            child: _StatTile(
              value: profile.totalOrders,
              label: 'Total orders',
            ),
          ),
          const SizedBox(width: AppSpacing.smd),
          Expanded(
            child: _StatTile(
              value: profile.inProgress,
              label: 'In progress',
            ),
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
  const _PersonalDetails({required this.profile});

  final UserProfile profile;

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
          _DetailRow(
            label: 'Gender',
            value: _genderLabel(profile.gender),
          ),
        ],
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
