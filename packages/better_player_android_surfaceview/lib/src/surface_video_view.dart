import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Platform view id; must match `BetterPlayerSurfaceViewFactory.VIEW_TYPE`.
const surfaceViewType = 'better_player_android_surfaceview/video';

/// Renders the player [playerId] through a native `SurfaceView`.
///
/// Mirrors `PlatformViewPlayer` from video_player_android:
/// `initSurfaceAndroidView` falls back to hybrid composition for a
/// SurfaceView, so frames never go through Flutter's texture pipeline.
class SurfaceVideoView extends StatelessWidget {
  const SurfaceVideoView({required this.playerId, super.key});

  final int playerId;

  @override
  Widget build(BuildContext context) {
    // IgnorePointer: gestures on the controls above the video stay with Flutter.
    return IgnorePointer(
      child: PlatformViewLink(
        viewType: surfaceViewType,
        surfaceFactory: (context, controller) => AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        ),
        onCreatePlatformView: (params) =>
            PlatformViewsService.initSurfaceAndroidView(
                id: params.id,
                viewType: surfaceViewType,
                layoutDirection:
                    Directionality.maybeOf(context) ?? TextDirection.ltr,
                creationParams: <String, Object>{'playerId': playerId},
                creationParamsCodec: const StandardMessageCodec(),
                onFocus: () => params.onFocusChanged(true),
              )
              ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
              ..create(),
      ),
    );
  }
}
