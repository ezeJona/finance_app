import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/auth_user.dart';

class StartPage extends HookConsumerWidget {
  const StartPage({super.key});

  // Paleta de colores consistente con el nuevo diseño
  static const Color primaryYellow = Color(0xFFF1C40F);
  static const Color darkNavy = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Animación de entrada
    final opacity = useAnimationController(duration: const Duration(milliseconds: 1000));
    
    final checkSessionState = useCallback(() async {
      // Damos tiempo a la animación y al impacto visual
      await Future.delayed(const Duration(milliseconds: 2500));
      
      final authUserRes = ref.read(authUserProvider.notifier).checkSession();
      
      if (context.mounted) {
        if (authUserRes != null) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
        }
      }
    }, []);

    useEffect(() {
      opacity.forward();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkSessionState();
      });
      return;
    }, []);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              darkNavy,
              Color(0xFF1A252F), // Un azul aún más profundo para el fondo
            ],
          ),
        ),
        child: Stack(
          children: [
            // Elementos decorativos de fondo (Sutiles círculos)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: primaryYellow.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            Center(
              child: FadeTransition(
                opacity: opacity,
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: opacity,
                    curve: Curves.easeOutBack,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // El nuevo logotipo Finora
                      Image.asset(
                        "assets/finora f.png",
                        height: 180,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "FINORA",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "TU ALIADO FINANCIERO",
                        style: TextStyle(
                          color: primaryYellow.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Indicador de carga sutil en la parte inferior
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(
                      width: 40,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        color: primaryYellow,
                        minHeight: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Iniciando sesión segura...",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
