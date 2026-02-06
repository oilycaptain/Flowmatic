import 'package:flutter/material.dart';

import '../../models/device_state.dart';
import '../../services/device_service.dart';
import '../../widgets/section_header.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final _device = DeviceService();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<DeviceState>(
      stream: _device.deviceStateStream(),
      builder: (context, snapshot) {
        final state = snapshot.data ?? DeviceState.empty();

        return Scaffold(
          appBar: AppBar(title: const Text('Control')),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              SectionHeader(
                title: 'Device settings',
                caption: 'Changes are saved to Firestore and logged as commands.',
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
                        Text('Mode', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'AUTO', label: Text('AUTO'), icon: Icon(Icons.auto_awesome_rounded)),
                            ButtonSegment(value: 'MANUAL', label: Text('MANUAL'), icon: Icon(Icons.handyman_rounded)),
                          ],
                          selected: {state.mode},
                          onSelectionChanged: (s) => _device.setMode(s.first),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          state.mode == 'AUTO'
                              ? 'AUTO: irrigation turns ON when soil moisture drops below the threshold.'
                              : 'MANUAL: you can start/stop the pump anytime.',
                          style: TextStyle(color: cs.onSurfaceVariant),
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
                        Row(
                          children: [
                            Expanded(
                              child: Text('Pump', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                            ),
                            Switch.adaptive(
                              value: state.pumpOn,
                              onChanged: (v) => _device.setPump(v),
                            )
                          ],
                        ),
                        Text(
                          state.pumpOn ? 'Pump is currently ON.' : 'Pump is currently OFF.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        if (state.mode == 'AUTO') ...[
                          const SizedBox(height: 10),
                          Text(
                            'Note: In AUTO mode, the device firmware should still enforce safety checks and may override manual commands.',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ],
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
                        Text('Dry threshold', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text(
                          'Auto irrigation triggers when soil moisture is below this value.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: state.thresholdDry.toDouble(),
                                min: 0,
                                max: 100,
                                divisions: 100,
                                label: '${state.thresholdDry}%',
                                onChanged: (v) => _device.setThresholdDry(v.round()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('${state.thresholdDry}%', style: TextStyle(fontWeight: FontWeight.w900, color: cs.onPrimaryContainer)),
                            ),
                          ],
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
}
