# Data Source Loading

To ensure a smooth user experience, you can programmatically verify if a data source has been loaded successfully. This is handled by monitoring the `Future` returned by the `setupDataSource` method.

## Handling Load Results

```dart
betterPlayerController!.setupDataSource(source)
.then((response) {
  // Data source loaded successfully
  setState(() {
    videoLoading = false;
  });
})
.catchError((error) async {
  // Failed to load data source (e.g., invalid URL)
  BetterPlayerUtils.log("Failed to load video: $error");
});
```
