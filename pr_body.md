Fixes #1016

When `customControlsBuilder` is provided in the configuration, but `playerTheme` is not explicitly set to `PlayerTheme.custom`, the custom controls were ignored and the player fell back to the default Material or Cupertino controls. 

This PR updates the default theme resolution so that if `customControlsBuilder` is non-null, the theme defaults to `PlayerTheme.custom` automatically.
