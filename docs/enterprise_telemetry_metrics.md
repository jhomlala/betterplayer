---
id: enterprise_telemetry_metrics
title: Telemetry & QoE Metrics
---

# Video Telemetry & QoE Metrics

The Enterprise telemetry engine collects real-time playback health and Quality of Experience (QoE) metrics across your audience.

Standard video players leave you blind once video leaves your CDN. When streams stall, users exit or complain without actionable context. Better Player Enterprise measures startup latency, rebuffer frequency, bitrate transitions, and errors, buffering events locally when connections drop and delivering them to Bitmovin Analytics, Mux Data, or your own ingest servers.

---

## What It Measures

* **Startup Latency**: Time to First Frame (TTFF) and player initialization duration.
* **QoE & Buffering**: Rebuffer stall count, total stall time, and rebuffer ratio.
* **Renditions & Bitrate**: Live ASMS/HLS track switches, bandwidth shifts, and resolution changes.
* **Viewer Engagement**: Actual playtime, pause duration, seek count, seek latency, and playhead completion percentage.
* **Exit Before Video Start (EBVS)**: Tracks viewers who bounce before the first frame renders.
* **VAST Ad Isolation**: Freezes content QoE timers during ad breaks so pre-rolls and mid-rolls do not inflate your video startup metrics.

---

## License Setup

Enterprise capabilities require license verification during app startup:

```dart
import 'package:better_player_enterprise/better_player_enterprise.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await BetterPlayerEnterprise.initialize(
    licenseId: 'YOUR_ENTERPRISE_LICENSE_KEY',
  );

  runApp(const MyApp());
}
```

---

## Quickstart

Attach `BetterPlayerMetricsExtension` directly to your `BetterPlayerController`:

```dart
import 'package:better_player/better_player.dart';
import 'package:better_player_enterprise/better_player_enterprise.dart';

final metricsExtension = BetterPlayerMetricsExtension(
  configuration: BetterPlayerMetricsConfiguration(
    exporter: BetterPlayerHttpMetricsExporter(
      endpointUrl: 'https://telemetry.yourdomain.com/v1/metrics',
    ),
    heartbeatInterval: const Duration(seconds: 15),
    batchSize: 10,
    customData: const <String, dynamic>{
      'userId': 'usr_94821',
      'plan': 'pro',
    },
  ),
);

final controller = BetterPlayerController(
  PlayerConfiguration(
    aspectRatio: 16 / 9,
    autoPlay: true,
    extensions: [metricsExtension],
  ),
  betterPlayerDataSource: PlayerDataSource(
    DataSourceType.network,
    'https://example.com/hls/stream.m3u8',
  ),
);

BetterPlayer(controller: controller);
```

---

## Accessing Live QoE Stats

Read live metrics from the extension anytime:

```dart
final stats = metricsExtension.playbackStats;
if (stats != null) {
  print('TTFF: ${stats.timeToFirstFrame?.inMilliseconds} ms');
  print('Rebuffer Ratio: ${(stats.rebufferRatio * 100).toStringAsFixed(2)}%');
  print('Total Watch Duration: ${stats.totalWatchDuration.inSeconds}s');
  print('Active Bitrate: ${stats.bitrateBps} bps');
}
```

Or listen to real-time changes in your UI via `ValueListenable`:

```dart
ValueListenableBuilder<BetterPlayerPlaybackStats>(
  valueListenable: metricsExtension.statsListenable!,
  builder: (context, stats, child) {
    return Text(
      'Rebuffer: ${(stats.rebufferRatio * 100).toStringAsFixed(1)}% '
      '(${stats.rebufferCount} stalls)',
    );
  },
);
```

---

## Cloud Exporters

### Bitmovin Analytics

Stream telemetry into your Bitmovin Analytics dashboard:

```dart
final exporter = BetterPlayerBitmovinMetricsExporter(
  apiKey: 'YOUR_BITMOVIN_ANALYTICS_KEY',
  customData: const <String, dynamic>{
    'customData1': 'premium_tier',
  },
);
```

### Mux Data

Stream QoE beacons into Mux Data:

```dart
final exporter = BetterPlayerMuxMetricsExporter(
  propertyKey: 'YOUR_MUX_ENVIRONMENT_KEY',
  customData: const <String, dynamic>{
    'viewer_plan': 'enterprise',
  },
);
```

### Multi-Destination Fan-Out

Broadcast telemetry events to multiple analytics backends simultaneously:

```dart
final exporter = BetterPlayerCompositeMetricsExporter(
  exporters: [
    BetterPlayerBitmovinMetricsExporter(apiKey: 'YOUR_BITMOVIN_KEY'),
    BetterPlayerMuxMetricsExporter(propertyKey: 'YOUR_MUX_KEY'),
    BetterPlayerHttpMetricsExporter(
      endpointUrl: 'https://internal-bi.company.com/ingest',
    ),
  ],
);
```

---

## Offline Storage & Resilience

When viewers lose internet connectivity (in tunnels, airplanes, or poor reception), telemetry events are queued to local persistent storage (`SharedPreferences`):

* **Priority-Aware Eviction**: If stored events reach the capacity ceiling (`maxPersistedEvents: 500`), routine heartbeats are dropped first. Critical milestones (`sessionStart`, `error`, `sessionEnd`) stay protected.
* **TTL Expiration**: Stored offline batches older than 72 hours (`eventTtl`) are pruned automatically.
* **Automatic Drain**: Once network returns, the dispatcher drains stored offline batches in sequential order with exponential backoff and jitter.

You can also trigger an immediate flush on demand:

```dart
await metricsExtension.flush();
```

---

## VAST Ad Isolation

When running ads via `BetterPlayerVastExtension`, ad viewing time must not inflate content startup latency or skew content playback stats.

`BetterPlayerMetricsManager` automatically links with `BetterPlayerVastExtension` when both extensions are attached:
* Ad break durations are excluded from content watch and rebuffer timers.
* Dedicated `adBreak` events are dispatched for ad start, quartiles (25%, 50%, 75%, 100%), skip, and completion.
