import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../breakpoints.dart';
import '../../colors.dart';
import '../../providers/auth_user.dart';
import '../../providers/app_user.dart';
import '../../providers/business.dart';
import '../../text_styles.dart';
import '../dashboard/balance_page.dart';
import '../debts/debts_page.dart';
import '../profile/profile_page.dart';
import '../chat/chat_page.dart';
import '../inventory/inventory_view.dart';
import 'bottom_nav_bar.dart';
import 'side_nav_bar.dart';
import '../../providers/sync_provider.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activar el servicio de sincronización
    ref.watch(syncProvider);

    final loading = useState<bool>(true);
    final loadingError = useState<bool>(false);
    final appUser = ref.watch(appUserProvider);
    final authUser = ref.watch(authUserProvider);
    final previousAuthUser = usePrevious(authUser);

    final selectedNavIndex = useState<int>(0);

    final fetchAppUser = useCallback(() async {
      if (authUser != null) {
        loading.value = true;
        loadingError.value = false;
        try {
          final appUserRes = await ref.read(appUserProvider.notifier).fetch();
          if (appUserRes == null) {
            // go to setup as the app user is not created yet
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/setup-user',
              (route) => false,
            );
          }
        } catch (err) {
          loadingError.value = true;
        } finally {
          loading.value = false;
        }
      }
    }, [authUser]);

    useEffect(() {
      fetchAppUser();
      return;
    }, [fetchAppUser]);

    // Navigate to login if authUser becomes null (session expired)
    useEffect(() {
      if (previousAuthUser != null && authUser == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        });
      }
      return null;
    }, [authUser]);

    useEffect(() {
      ref.read(businessProvider.notifier).fetch();
      return;
    }, []);

    final onSelectNavigationIndex = useCallback((int index) {
      selectedNavIndex.value = index;
    }, []);

    if ((appUser == null) && (loading.value || loadingError.value)) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (loading.value) ...[
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    "Cargando usuario ...",
                    style: HospiredTextStyle.title3.copyWith(
                      color: HospiredColors.primary,
                    ),
                  ),
                ),
              ],
              if (loadingError.value) ...[
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    "Error al cargar usuario",
                    style: HospiredTextStyle.body2.copyWith(
                      color: HospiredColors.danger,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => fetchAppUser(),
                  child: const Text("Volver a intentar"),
                ),
              ],
            ],
          ),
        ),
      );
    }

  // Mapeo dinámico de pantallas actualizado
    Widget _getScreen(int index) {
      switch (index) {
        case 0:
          return const BalancePage();
        case 1:
          return const DebtsPage();
        case 2:
          return const InventoryView();
        case 3:
          return const ChatPage(); // Asistente IA!
        case 4:
          return const ProfilePage();
        default:
          return const Scaffold(
            body: Center(
              child: Text(
                "Módulo en Construcción...",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          );
      }
    }

    return MediaQuery.of(context).size.width > Breakpoint.lg
        ? Scaffold(
      body: Row(
        children: [
          SideNavBar(
            selectedIndex: selectedNavIndex.value,
            onTap: (index) => onSelectNavigationIndex(index),
          ),
          Expanded(child: _getScreen(selectedNavIndex.value)),
        ],
      ),
    )
        : Scaffold(
      body: _getScreen(selectedNavIndex.value),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: selectedNavIndex.value,
        onTap: (index) => onSelectNavigationIndex(index),
      ),
    );
  }
}
