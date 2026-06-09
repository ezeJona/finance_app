import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final Function(int) onTap;

  // Colores de la UI de Balance para consistencia visual
  static const Color primaryYellow = Color(0xFFF1C40F);
  static const Color darkNavy = Color(0xFF2C3E50);
  static const Color textGray = Color(0xFF7F8C8D);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, -4), // Sombra suave hacia arriba
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent, // Usa el fondo del contenedor contenedor
            elevation: 0,
            currentIndex: selectedIndex,
            onTap: (index) => onTap(index),
            showUnselectedLabels: true,
            selectedItemColor: darkNavy,
            unselectedItemColor: textGray.withOpacity(0.6),
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.2),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            items: [
              _buildBottomItem(
                icon: const Icon(Icons.space_dashboard_outlined),
                activeIcon: const Icon(Icons.space_dashboard),
                label: 'Balance',
                index: 0,
              ),
              _buildBottomItem(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                activeIcon: const Icon(Icons.account_balance_wallet),
                label: 'Deudas',
                index: 1,
              ),
              _buildBottomItem(
                icon: const Icon(Icons.inventory_2_outlined),
                activeIcon: const Icon(Icons.inventory_2),
                label: 'Inventario',
                index: 2,
              ),
              _buildBottomItem(
                icon: const Icon(Icons.auto_awesome_outlined),
                activeIcon: const Icon(Icons.auto_awesome),
                label: 'Asistente',
                index: 3,
              ),
              _buildBottomItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: 'Perfil',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomItem({
    required Widget icon,
    required Widget activeIcon,
    required String label,
    required int index,
  }) {
    final bool isSelected = selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          // Píldora de fondo suave amarilla para el ítem seleccionado
          color: isSelected ? primaryYellow.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: isSelected ? activeIcon : icon,
      ),
      label: label,
    );
  }
}