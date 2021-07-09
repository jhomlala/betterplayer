## Source load
You can check whether your data source has been loaded successfully by checking result of the future method of `setupDataSource` in `BetterPlayerController`:

```dart
betterPlayerController!.setupDataSource(source)
.then((response) {
  // Source loaded successfully
  videoLoading = false;
})
.catchError((error) async {
  // Source did not load, url might be invalid
  inspect(error);
});
```
