import 'package:flutter/material.dart';

import '../control/control_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  final _pages = const [
    DashboardScreen(),
    ControlScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;

        if (desktop) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dashboard_rounded), label: Text('Dashboard')),
                    NavigationRailDestination(icon: Icon(Icons.tune_rounded), label: Text('Control')),
                    NavigationRailDestination(icon: Icon(Icons.history_rounded), label: Text('History')),
                    NavigationRailDestination(icon: Icon(Icons.person_rounded), label: Text('Profile')),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _pages[_index]),
              ],
            ),
          );
        }

        return Scaffold(
          body: _pages[_index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
              NavigationDestination(icon: Icon(Icons.tune_rounded), label: 'Control'),
              NavigationDestination(icon: Icon(Icons.history_rounded), label: 'History'),
              NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}
