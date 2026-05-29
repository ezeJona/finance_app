import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/app_user.dart';
import '../providers/business.dart';

class AppHeader extends HookConsumerWidget {
  const AppHeader({super.key});

  // Colores consistentes
  static const Color primaryYellow = Color(0xFFF1C40F);
  static const Color darkNavy = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(appUserProvider);
    final business = ref.watch(businessProvider);
    
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    // Título principal: Nombre del Negocio
    String businessName = business?.name ?? "Cargando...";
    
    // Subtítulo: Tipo de cuenta y nombre del usuario para contexto
    String subTitle = "";
    if (business != null) {
      subTitle = "${business.businessType} • ${appUser?.firstName ?? 'Usuario'}";
    } else if (appUser != null) {
      subTitle = "${appUser.firstName} ${appUser.firstLastName}";
    }

    return Container(
      padding: EdgeInsets.only(top: statusBarHeight + 16, left: 16, right: 16, bottom: 20),
      decoration: const BoxDecoration(
        color: primaryYellow,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Fila superior: Perfil, Nombre del Negocio y Ayuda
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      businessName,
                      style: const TextStyle(
                        fontSize: 19, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                        letterSpacing: 0.5
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subTitle,
                      style: TextStyle(
                        fontSize: 13, 
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                child: const Text('?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
