import 'package:material_ui/material_ui.dart';

/// Overlay rendered above the local video surface while media is casting to a remote receiver.
class CastPlayerOverlay extends StatelessWidget {
  /// Creates a Cast player overlay.
  const CastPlayerOverlay({
    required this.castingStream,
    required this.isCastingProvider,
    required this.deviceNameProvider,
    super.key,
  });

  /// Stream of casting connection state updates.
  final Stream<bool> castingStream;

  /// Callback returning whether a Cast session is currently active.
  final bool Function() isCastingProvider;

  /// Callback returning the friendly name of the connected Cast receiver.
  final String? Function() deviceNameProvider;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: castingStream,
      initialData: isCastingProvider(),
      builder: (context, snapshot) {
        final active = (snapshot.data ?? false) || isCastingProvider();
        if (!active) {
          return const SizedBox.shrink();
        }
        final deviceName = deviceNameProvider() ?? 'Cast device';
        return IgnorePointer(
          child: ColoredBox(
            color: const Color(0xE6000000),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cast_connected,
                      color: Colors.white70,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Casting to $deviceName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
