import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum ConnectivityStatus { isConnected, isDisconnected, notDetermined }

final connectivityStatusProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  ConnectivityNotifier() : super(ConnectivityStatus.notDetermined) {
    _init();
  }

  Future<void> _init() async {
    try {
      // Pequeña espera para asegurar que el DOM de la web esté listo antes de añadir listeners
      await Future.delayed(const Duration(milliseconds: 500));
      
      Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
        _updateStatus(results);
      });
      _checkInitialConnectivity();
    } catch (e) {
      // En la web, si falla el listener, asumimos conectado por defecto para no bloquear la app
      state = ConnectivityStatus.isConnected;
    }
  }

  Future<void> _checkInitialConnectivity() async {
    final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
    _updateStatus(results);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      state = ConnectivityStatus.isDisconnected;
    } else {
      state = ConnectivityStatus.isConnected;
    }
  }
}
