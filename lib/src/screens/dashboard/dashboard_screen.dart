import 'package:flutter/material.dart';

import '../../models/device_state.dart';
import '../../services/device_service.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_pill.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _device = DeviceService();
  bool _busy = false;

  Future<void> _seed() async {
    setState(() => _busy = true);
    try {
      await _device.seedDemoData();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DeviceState>(
      stream: _device.deviceStateStream(),
      builder: (context, snapshot) {
        final state = snapshot.data ?? DeviceState.empty();
        final cs = Theme.of(context).colorScheme;

        final isDry = state.soilMoisture <= state.thresholdDry;
        final statusLabel = isDry ? 'Dry — irrigate soon' : 'Moisture OK';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: [
              if (state.lastUpdated == null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilledButton.tonalIcon(
                    onPressed: _busy ? null : _seed,
                    icon: const Icon(Icons.auto_fix_high_rounded),
                    label: Text(_busy ? 'Creating…' : 'Demo data'),
                  ),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              SectionHeader(
                title: 'Device: ${_device.deviceId}',
                caption: state.lastUpdated == null
                    ? 'No device data yet. Tap “Demo data” to seed test readings.'
                    : 'Last updated: ${_prettyTime(state.lastUpdated!)}',
                trailing: StatusPill(label: state.pumpOn ? 'Pump ON' : 'Pump OFF', active: state.pumpOn),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: StatusPill(label: state.mode, active: true)),
                    const SizedBox(width: 12),
                    Expanded(child: StatusPill(label: statusLabel, active: !isDry)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _grid(
                  children: [
                    MetricCard(
                      title: 'Soil Moisture',
                      value: '${state.soilMoisture}%',
                      subtitle: isDry ? 'Below threshold (${state.thresholdDry}%)' : 'Above threshold (${state.thresholdDry}%)',
                      icon: Icons.grass_rounded,
                    ),
                    MetricCard(
                      title: 'Irrigation',
                      value: state.pumpOn ? 'Running' : 'Stopped',
                      subtitle: state.mode == 'AUTO' ? 'Auto mode controls this' : 'Manual control',
                      icon: Icons.water_rounded,
                    ),
                    MetricCard(
                      title: 'Threshold (Dry)',
                      value: '${state.thresholdDry}%',
                      subtitle: 'Auto turns pump ON when below this',
                      icon: Icons.trending_down_rounded,
                    ),
                    MetricCard(
                      title: 'Security',
                      value: 'Audit trail',
                      subtitle: 'Commands logged to Firestore',
                      icon: Icons.lock_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _device.setPump(!state.pumpOn),
                                icon: Icon(state.pumpOn ? Icons.stop_rounded : Icons.play_arrow_rounded),
                                label: Text(state.pumpOn ? 'Stop Pump' : 'Start Pump'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: () => _device.setMode(state.mode == 'AUTO' ? 'MANUAL' : 'AUTO'),
                                icon: const Icon(Icons.swap_horiz_rounded),
                                label: Text(state.mode == 'AUTO' ? 'Manual Mode' : 'Auto Mode'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tip: Your ESP32 can listen to /devices/${_device.deviceId}/commands and apply the latest command securely.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _grid({required List<Widget> children}) {
    // simple responsive 2-column grid without extra deps
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w > 520 ? 3 : 2;
        final spacing = 12.0;
        final itemW = (w - (cols - 1) * spacing) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: itemW, child: child))
              .toList(growable: false),
        );
      },
    );
  }

  String _prettyTime(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$mo/$dd ${hh}:$mm';
  }
}
