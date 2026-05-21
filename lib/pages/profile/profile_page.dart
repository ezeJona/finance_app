import 'package:flutter/material.dart';

import '../../backend-api/api_service.dart';
import '../../backend-api/dtos.dart';
import '../../breakpoints.dart';
import '../../colors.dart';
import '../../text_styles.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AppUserRes? userData;
  // Mantenemos la referencia al DTO existente para no romper la compatibilidad
  PatientRes? entrepreneurData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final session = ApiService.checkAndGetUserSession();
    if (session == null) return;

    final appUser = await ApiService.getAppUser(session.id);
    final patient = await ApiService.getPatient(session.id); // Consumo del método existente

    setState(() {
      userData = appUser;
      entrepreneurData = patient; // Mapeado internamente como los datos del negocio
      isLoading = false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    await ApiService.signOutUser();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil Comercial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    if (userData == null) {
      return const Center(child: Text("No se encontraron datos del usuario."));
    }

    // Redefinimos las etiquetas visuales para orientarlas al ecosistema emprendedor
    final Map<String, String> profileMap = {
      "Propietario": "${userData!.firstName} ${userData!.secondName ?? ''}".trim(),
      "Apellidos": "${userData!.firstLastName} ${userData!.secondLastName ?? ''}".trim(),
      "Identificación / Cédula": entrepreneurData?.nationalId ?? "Sin registrar",
      "Teléfono de Contacto": entrepreneurData?.phoneNumber ?? "Sin registrar",
      "Giro Comercial / Ocupación": entrepreneurData?.occupation ?? "Sin registrar",
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
                      // Usamos el esquema de color existente pero con semántica de billetera/negocio
                      backgroundColor: HospiredColors.primary.withOpacity(0.15),
                      child: const Icon(
                        Icons.storefront_rounded, // Ícono comercial en lugar de médico/paciente
                        size: 50,
                        color: HospiredColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "${userData!.firstName} ${userData!.firstLastName}",
                      style: HospiredTextStyle.title2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entrepreneurData?.occupation ?? "Emprendedor Independiente",
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
      case "Identificación / Cédula":
        return const Icon(Icons.badge_rounded, color: HospiredColors.primary);
      case "Teléfono de Contacto":
        return const Icon(Icons.phone_android_rounded, color: HospiredColors.primary);
      case "Giro Comercial / Ocupación":
        return const Icon(Icons.business_center_rounded, color: HospiredColors.primary);
      default:
        return const Icon(Icons.info_outline_rounded, color: HospiredColors.primary);
    }
  }
}