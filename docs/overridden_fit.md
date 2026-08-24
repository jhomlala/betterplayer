---
id: overridden_fit
title: Overridden BoxFit
---

# Overridden BoxFit

You can dynamically override the `fit` parameter defined in `BetterPlayerConfiguration` during runtime using the `setOverriddenFit` method.

## Implementation Example

```dart
// Changes the video fit to 'contain'
betterPlayerController.setOverriddenFit(BoxFit.contain);
```
