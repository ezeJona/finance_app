import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/app_user.dart';
import '../providers/business.dart';
import '../providers/connectivity.dart';
import '../providers/sync_provider.dart';

class AppHeader extends HookConsumerWidget {
  final String? title;
  const AppHeader({super.key, this.title});

  // Colores consistentes
  static const Color primaryYellow = Color(0xFFF1C40F);
  static const Color darkNavy = Color(0xFF2C3E50);
  static const Color expenseRed = Color(0xFFFF2D55);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(appUserProvider);
    final business = ref.watch(businessProvider);
    final connectivity = ref.watch(connectivityStatusProvider);
    final syncCount = ref.watch(syncQueueCountProvider).value ?? 0;
    
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    // Título principal: Nombre del Negocio o el título pasado por parámetro
    String displayTitle = title ?? business?.name ?? "Cargando...";
    
    // Subtítulo: Tipo de cuenta y nombre del usuario para contexto
    String subTitle = "";
    if (title != null && business != null) {
      subTitle = business.name;
    } else if (business != null) {
      subTitle = "${business.businessType} • ${appUser?.firstName ?? 'Usuario'}";
    } else if (appUser != null) {
      subTitle = "${appUser.firstName} ${appUser.firstLastName}";
    }

    return Container(
      padding: EdgeInsets.only(top: statusBarHeight + 8, left: 16, right: 16, bottom: 20),
      decoration: const BoxDecoration(
        color: primaryYellow,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          if (connectivity == ConnectivityStatus.isDisconnected)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off, size: 14, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "⚠️ Modo Offline (Sin conexión)",
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          
          if (connectivity == ConnectivityStatus.isConnected && syncCount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 4, height: 4, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  const SizedBox(width: 8),
                  Text(
                    "Sincronizando $syncCount cambios...",
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

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
                      displayTitle,
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
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
