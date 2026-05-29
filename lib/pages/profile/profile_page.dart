import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../backend-api/api_service.dart';
import '../../backend-api/dtos.dart';
import '../../breakpoints.dart';
import '../../colors.dart';
import '../../text_styles.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header.dart';

class ProfilePage extends HookConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await ApiService.signOutUser();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usamos FutureBuilder para mantener la lógica de carga asíncrona que tenía el StatefulWidget
    return Scaffold(
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: FutureBuilder(
                future: _loadProfileData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return const Center(child: Text("Error al cargar perfil"));
                  }
                  
                  final data = snapshot.data as Map<String, dynamic>;
                  final userData = data['user'] as AppUserRes?;
                  final businessData = data['business'] as BusinessRes?;
                  
                  return _buildProfileView(context, userData, businessData);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadProfileData() async {
    final session = ApiService.checkAndGetUserSession();
    if (session == null) throw Exception("Sin sesión");

    final appUser = await ApiService.getAppUser(session.id);
    final business = await ApiService.getBusiness(session.id);
    
    return {'user': appUser, 'business': business};
  }

  Widget _buildProfileView(BuildContext context, AppUserRes? userData, BusinessRes? businessData) {
    if (userData == null) {
      return const Center(child: Text("No se encontraron datos del usuario."));
    }

    final Map<String, String> profileMap = {
      "Propietario": "${userData.firstName} ${userData.secondName ?? ''}".trim(),
      "Apellidos": "${userData.firstLastName} ${userData.secondLastName ?? ''}".trim(),
      "Nombre del Negocio": businessData?.name ?? "Sin registrar",
      "Tipo de Negocio": businessData?.businessType ?? "Sin registrar",
      "Moneda Principal": businessData?.currencyCode ?? "Sin registrar",
    };

    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
          constraints: const BoxConstraints(maxWidth: Breakpoint.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: HospiredColors.primary.withOpacity(0.15),
                      child: const Icon(
                        Icons.storefront_rounded,
                        size: 50,
                        color: HospiredColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "${userData.firstName} ${userData.firstLastName}",
                      style: HospiredTextStyle.title2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      businessData?.name ?? "Emprendedor Independiente",
                      style: HospiredTextStyle.body3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text("Información de la Microempresa", style: HospiredTextStyle.title3),
              const SizedBox(height: 8),
              ...profileMap.entries.map(
                    (entry) => Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: _getIconForKey(entry.key),
                    title: Text(entry.key, style: HospiredTextStyle.body3),
                    subtitle: Text(entry.value),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Próximamente: Modificar datos de facturación"),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text("Editar Información"),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, color: HospiredColors.danger),
                label: const Text("Cerrar Sesión", style: TextStyle(color: HospiredColors.danger)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Icon _getIconForKey(String key) {
    switch (key) {
      case "Propietario":
        return const Icon(Icons.admin_panel_settings_rounded, color: HospiredColors.primary);
      case "Apellidos":
        return const Icon(Icons.person_outline_rounded, color: HospiredColors.primary);
      case "Nombre del Negocio":
        return const Icon(Icons.business_rounded, color: HospiredColors.primary);
      case "Tipo de Negocio":
        return const Icon(Icons.category_rounded, color: HospiredColors.primary);
      case "Moneda Principal":
        return const Icon(Icons.payments_rounded, color: HospiredColors.primary);
      default:
        return const Icon(Icons.info_outline_rounded, color: HospiredColors.primary);
    }
  }
}
