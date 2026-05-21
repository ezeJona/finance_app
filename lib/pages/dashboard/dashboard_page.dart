import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.onSelectNavIndex});

  final Function onSelectNavIndex;

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("No se pudo abrir el enlace: $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Sección 1 - Encabezado oscuro con imagen alineada a la derecha
        Container(
          width: double.infinity,
          color: const Color(0xFF29235c),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Center(child: Image.asset("assets/logotipo.png", height: 80)),
        ),

        // Sección 2 - Bienvenida
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          color: Colors.white,
          child: Column(
            children: const [
              Text(
                "¡Bienvenido a tu Panel Financiero!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                "Controla tus ingreos, egresos y el crecimiento de tu negocio",
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Sección 3 - Cards
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            children: [
              _buildCard(
                title: "Resumen de Cuenta",
                description:
                    "Aquí visualizaremos los balances diarios y mensuales pronto",
                icon: Icons.account_balance_wallet,
                onTap: () => _launchURL("https://hospired.github.io/hospired/"),
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: "Facebook",
                description:
                    "Síguenos en Facebook para estar al día con nuestras noticias.",
                icon: Icons.facebook,
                onTap: () => _launchURL("https://facebook.com"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.blueAccent),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
