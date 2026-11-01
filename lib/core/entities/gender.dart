/// Shared gender enumeration used across features.
///
/// Placed in `core/entities` so both the `auth` and `profile` features can
/// depend on it without either feature depending on the other. This keeps the
/// clean-architecture dependency rule intact: features depend on `core`, never
/// on each other.
enum Gender { female, male, other }
