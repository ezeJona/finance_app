import 'package:flutter/material.dart';

class SideNavBar extends StatelessWidget {
  const SideNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => onTap(index),
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          padding: EdgeInsets.symmetric(vertical: 8),
          icon: Icon(Icons.space_dashboard_outlined),
          selectedIcon: Icon(Icons.space_dashboard),
          label: Text('Balance'),
        ),
        NavigationRailDestination(
          padding: EdgeInsets.symmetric(vertical: 8),
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: Text('Historial'), // Antiguas 'Citas'
        ),
        NavigationRailDestination(
          padding: EdgeInsets.symmetric(vertical: 8),
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: Text('Reportes'), // Antiguo 'Mapa'
        ),
        NavigationRailDestination(
          padding: EdgeInsets.symmetric(vertical: 8),
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome),
          label: Text('Asistente'), // Antiguo 'Chat'
        ),
        NavigationRailDestination(
          padding: EdgeInsets.symmetric(vertical: 8),
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Perfil'),
        ),
      ],
    );
  }
}
