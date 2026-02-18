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
  double _simulatedMoisture = 30;

  Future<void> _seed() async {
    setState(() => _busy = true);
    try {
      await _device.seedDemoData();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _simulateReading() async {
    setState(() => _busy = true);
    try {
      await _device.addSensorReading(_simulatedMoisture.round());
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
                    const MetricCard(
                      title: 'Security',
                      value: 'TLS + Encrypted cmd',
                      subtitle: 'Signed payload over Firestore',
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
                        Text('Controlled testing setup', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text('Inject synthetic moisture to validate auto-irrigation and command flow.', style: TextStyle(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Slider(
                          value: _simulatedMoisture,
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: '${_simulatedMoisture.round()}%',
                          onChanged: _busy ? null : (v) => setState(() => _simulatedMoisture = v),
                        ),
                        Row(
                          children: [
                            Text('Moisture: ${_simulatedMoisture.round()}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: _busy ? null : _simulateReading,
                              icon: const Icon(Icons.science_rounded),
                              label: Text(_busy ? 'Sending...' : 'Send reading'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                        Text('Implementation status', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        _bullet('Automated irrigation based on moisture level', true),
                        _bullet('Encrypted data transmission implemented', true),
                        _bullet('Stable cloud data storage', true),
                        _bullet('Mobile app can monitor and control irrigation', true),
                        _bullet('Initial cloud setup for sensor data', true),
                        _bullet('Web app support and responsive shell', true),
                        _bullet('System debugging and improvements', true),
                        _bullet('IoT prototype testing mode in-app', true),
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

  Widget _bullet(String text, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _grid({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w > 520 ? 3 : 2;
        final spacing = 12.0;
        final itemW = (w - (cols - 1) * spacing) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map((child) => SizedBox(width: itemW, child: child)).toList(growable: false),
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
