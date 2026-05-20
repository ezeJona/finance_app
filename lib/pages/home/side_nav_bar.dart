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
          icon: Icon(Icons.space_dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          padding: EdgeInsets.symmetric(vertical: 8),
          icon: Icon(Icons.calendar_today),
          label: Text('Citas'),
        ),
        /*
        // Enable again when treatments logic is implemented
        NavigationRailDestination(
          padding: EdgeInsets.symmetric(vertical: 8),
          icon: Icon(Icons.medical_services),
          label: Text('Tratamiento'),
        ),
        */
        NavigationRailDestination(
          padding: EdgeInsets.symmetric(vertical: 8),
          icon: Icon(Icons.map),
          label: Text('Mapa'),
        ),

        NavigationRailDestination(
          padding: EdgeInsets.symmetric(vertical: 8),
          icon: Icon(Icons.chat),
          label: Text('Chat'),
        ),

        NavigationRailDestination(
          padding: EdgeInsets.symmetric(vertical: 8),
          icon: Icon(Icons.person),
          label: Text('Perfil'),
        ),
      ],
    );
  }
}
