/// Representation of possible UI themes in Better Player.
///
/// For Android, default theme is [material]. For iOS, default theme is [cupertino].
/// For Web and desktop platforms (Windows, macOS, Linux), default theme is [web] / [desktop].
/// To use a custom theme, set [custom].
enum PlayerTheme {
  material,
  cupertino,
  web,
  custom,
  desktop,
}
