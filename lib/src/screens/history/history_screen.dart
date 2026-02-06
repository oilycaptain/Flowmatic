import 'package:flutter/material.dart';

import '../../models/device_state.dart';
import '../../models/reading.dart';
import '../../services/device_service.dart';
import '../../widgets/section_header.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final device = DeviceService();

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: StreamBuilder<DeviceState>(
        stream: device.deviceStateStream(),
        builder: (context, stateSnap) {
          final state = stateSnap.data ?? DeviceState.empty();
          return StreamBuilder<List<Reading>>(
            stream: device.readingsStream(limit: 80),
            builder: (context, snap) {
              final readings = snap.data ?? const <Reading>[];

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  SectionHeader(
                    title: 'Recent soil moisture readings',
                    caption: readings.isEmpty ? 'No readings yet.' : 'Showing the latest ${readings.length} readings',
                  ),
                  const SizedBox(height: 12),
                  if (readings.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Your device can write readings to: /devices/${device.deviceId}/readings\n\nFields: soilMoisture (0–100), createdAt (timestamp).',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    )
                  else
                    ...readings.map((r) => _ReadingTile(
                          reading: r,
                          threshold: state.thresholdDry,
                        )),
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({required this.reading, required this.threshold});

  final Reading reading;
  final int threshold;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDry = reading.soilMoisture <= threshold;
    final icon = isDry ? Icons.warning_rounded : Icons.check_circle_rounded;
    final iconColor = isDry ? cs.error : cs.primary;

    final dt = reading.createdAt.toLocal();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text('${reading.soilMoisture}% moisture', style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text('$mo/$dd $hh:$mm'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDry ? cs.errorContainer : cs.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isDry ? 'DRY' : 'OK',
              style: TextStyle(fontWeight: FontWeight.w900, color: isDry ? cs.onErrorContainer : cs.onPrimaryContainer),
            ),
          ),
        ),
      ),
    );
  }
}
