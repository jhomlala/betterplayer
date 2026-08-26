## Unreleased
* Updated: Renamed `isPictureInPictureEnabled` to `isPictureInPictureSupported` to better reflect that the method checks for device/texture support.
* Added: `dataSourceToMap` method to `MethodChannelVideoPlayer` for centralized and customizable `DataSource` serialization.
* Updated: Refactored `setDataSource` and `preCache` to use the new `dataSourceToMap` method.

## 1.0.0
* Updated: Migrated to federated plugin.
