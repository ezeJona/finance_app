import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const Color darkNavy = Color(0xFF1E2530); // Tono oscuro
  static const Color textGray = Color(0xFF333333);
  static const Color subtitleGray = Color(0xFF4A4A4A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // 1. SECCIÓN DE IMAGEN
              Expanded(
                flex: 55, // Ocupa el 55% del alto de la pantalla
                child: Stack(
                  children: [
                    // Contenedor preparado para la imagen real
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey[200], // Fondo provisional gris claro
                      child: Image.asset(
                        'assets/bienvenida.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. PANEL DE TEXTO Y BOTONES (PARTE INFERIOR)
              Expanded(
                flex: 45, // Ocupa el 45% restante de la pantalla
                child: Container(
                  transform: Matrix4.translationValues(0.0, -24.0, 0.0), // Eleva el panel para superponerlo sutilmente a la imagen
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Bloque de Textos (Título y Subtítulo)
                        Column(
                          children: [
                            const Text(
                              'Administra tu negocio fácil y seguro',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: darkNavy,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Lleva el control de tus ventas, deudas e clientes sin estrés, ni complicaciones.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: subtitleGray,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),

                        // Bloque de Botones de Acción
                        Column(
                          children: [
                            _buildPrimaryButton(context),
                            const SizedBox(height: 12),
                            _buildSecondaryButton(context),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Botón "Empezar" (Relleno Oscuro)
  Widget _buildPrimaryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56, // Altura generosa y cómoda para el pulgar
      child: FilledButton(
        onPressed: () {
          Navigator.pushNamed(context, '/login/sign-up');
        },
        style: FilledButton.styleFrom(
          backgroundColor: darkNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Empezar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Botón "Ya tengo una cuenta" (Bordeado Delineado)
  Widget _buildSecondaryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pushNamed(context, '/login');
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: darkNavy, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Ya tengo una cuenta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: darkNavy,
          ),
        ),
      ),
    );
  }
}