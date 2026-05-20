import 'package:flutter/material.dart';
import 'package:hospired/providers/destroy_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  PatientRes? patientData;
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
    final patient = await ApiService.getPatient(session.id);

    setState(() {
      userData = appUser;
      patientData = patient;
      isLoading = false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    await ApiService.signOutUser();
    // TODO: call destroySession();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
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

    final Map<String, String> profileMap = {
      "Nombre": "${userData!.firstName} ${userData!.secondName ?? ''}".trim(),
      "Apellidos":
          "${userData!.firstLastName} ${userData!.secondLastName ?? ''}".trim(),
      "Cédula": patientData?.nationalId ?? "Sin registrar",
      "Teléfono": patientData?.phoneNumber ?? "Sin registrar",
      "Ocupación": patientData?.occupation ?? "Sin registrar",
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
                      backgroundColor: HospiredColors.primary.withOpacity(0.2),
                      child: const Icon(
                        Icons.person,
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
                      patientData?.occupation ?? "Sin ocupación registrada",
                      style: HospiredTextStyle.body3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text("Información Personal", style: HospiredTextStyle.title3),
              const SizedBox(height: 8),
              ...profileMap.entries.map(
                (entry) => Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: _getIconForKey(entry.key),
                    title: Text(entry.key, style: HospiredTextStyle.body3),
                    subtitle: Text(entry.value),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Próximamente: Editar Perfil"),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Editar Perfil"),
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
      case "Nombre":
        return const Icon(Icons.badge, color: HospiredColors.primary);
      case "Apellidos":
        return const Icon(Icons.person, color: HospiredColors.primary);
      case "Cédula":
        return const Icon(Icons.credit_card, color: HospiredColors.primary);
      case "Teléfono":
        return const Icon(Icons.phone, color: HospiredColors.primary);
      case "Ocupación":
        return const Icon(Icons.work, color: HospiredColors.primary);
      default:
        return const Icon(Icons.info, color: HospiredColors.primary);
    }
  }
}
