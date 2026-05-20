import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../breakpoints.dart';
import '../../colors.dart';
import '../../providers/auth_user.dart';
import '../../providers/app_user.dart';
import '../../providers/patient.dart';
import '../../text_styles.dart';
import '../appointments/appointments_page.dart';
import '../dashboard/dashboard_page.dart';
import '../treatments/treatment_page.dart';
import '../profile/profile_page.dart';
import '../map/map_page.dart';
import '../chat/chat_page.dart';
import 'bottom_nav_bar.dart';
import 'side_nav_bar.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      ref.read(patientProvider.notifier).fetch();
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

    return MediaQuery.of(context).size.width > Breakpoint.lg
        ? Scaffold(
            body: Row(
              children: [
                SideNavBar(
                  selectedIndex: selectedNavIndex.value,
                  onTap: (index) => onSelectNavigationIndex(index),
                ),
                Expanded(
                  child: selectedNavIndex.value == 0
                      ? DashboardPage(onSelectNavIndex: onSelectNavigationIndex)
                      : (selectedNavIndex.value == 1
                            ? AppointmentsPage()
                            : (selectedNavIndex.value == 2
                                  ? MapPage()
                                  : (selectedNavIndex.value == 3
                                        ? ChatPage()
                                        : selectedNavIndex.value == 4
                                        ? ProfilePage()
                                        : Column(
                                            children: [
                                              Text(
                                                appUser?.toString() ??
                                                    "No app user",
                                              ),
                                              Text(
                                                authUser?.toString() ??
                                                    "No auth user",
                                              ),
                                            ],
                                          )))),
                ),
              ],
            ),
          )
        : Scaffold(
            body: selectedNavIndex.value == 0
                ? DashboardPage(onSelectNavIndex: onSelectNavigationIndex)
                : (selectedNavIndex.value == 1
                      ? AppointmentsPage()
                      : (selectedNavIndex.value == 2
                            ? MapPage()
                            : (selectedNavIndex.value == 3
                                  ? ChatPage()
                                  : selectedNavIndex.value == 4
                                  ? ProfilePage()
                                  : Column(
                                      children: [
                                        Text(
                                          appUser?.toString() ?? "No app user",
                                        ),
                                        Text(
                                          authUser?.toString() ??
                                              "No auth user",
                                        ),
                                      ],
                                    )))),
            bottomNavigationBar: BottomNavBar(
              selectedIndex: selectedNavIndex.value,
              onTap: (index) => onSelectNavigationIndex(index),
            ),
          );
  }
}
