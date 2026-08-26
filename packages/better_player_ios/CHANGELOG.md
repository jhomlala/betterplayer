## Unreleased
* Updated: Added package-specific `analysis_options.yaml` inheriting from root.
* Updated: Enhanced unit tests for `BetterPlayerIOS`, adding tests for `registerWith` and `buildView`.
* Fixed: Correctly store data source information in `dataSourceDict` during `setDataSource` to enable remote notification (lock screen) controls.
* Updated: Overrode `dataSourceToMap` to explicitly block DASH streams on iOS with a descriptive exception, improving error feedback.

## 1.0.0
* Updated: Migrated to federated plugin.
