import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'api_service.dart';
import 'dtos.dart';

class SyncService {
  static final _syncBox = Hive.box('sync_queue');
  static final _txBox = Hive.box('transactions_cache');
  static final _debtsBox = Hive.box('debts_cache');

  static Future<bool> isOnline() async {
    final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.isNotEmpty && !connectivityResult.contains(ConnectivityResult.none);
  }

  // --- GENERIC QUEUE ACTION ---

  static Future<void> queueAction(String type, Map<String, dynamic> payload) async {
    final id = const Uuid().v4();
    await _syncBox.put(id, {
      'id': id,
      'endpoint_type': type,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // --- SYNC ENGINE ---

  static Future<void> processQueue() async {
    if (!await isOnline()) return;

    final keys = _syncBox.keys.toList();
    if (keys.isEmpty) return;

    for (var key in keys) {
      final item = _syncBox.get(key);
      final type = item['endpoint_type'];
      final payload = jsonDecode(item['payload']);

      try {
        switch (type) {
          case 'create_transaction':
            await ApiService.createTransaction(CreateTransactionReq.fromJson(payload));
            break;
          case 'create_debt':
            await ApiService.createDebt(CreateDebtReq.fromJson(payload));
            break;
          case 'create_debt_payment':
            await ApiService.createDebtPayment(CreateDebtPaymentReq.fromJson(payload));
            break;
          case 'delete_transaction':
            await ApiService.deleteTransaction(payload['id']);
            break;
        }
        await _syncBox.delete(key);
      } catch (e) {
        // En caso de error, lo dejamos en la cola para el próximo intento
      }
    }
  }

  // --- CACHE HELPERS ---

  static Future<void> cacheTransactions(int businessId, List<TransactionRes> transactions) async {
    final data = transactions.map((t) => t.toJson()).toList();
    await _txBox.put(businessId, data);
  }

  static List<TransactionRes> getCachedTransactions(int businessId) {
    final data = _txBox.get(businessId);
    if (data == null) return [];
    return (data as List).map((json) => TransactionRes.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  static Future<void> cacheDebts(int businessId, List<DebtRes> debts) async {
    final data = debts.map((d) => d.toJson()).toList();
    await _debtsBox.put(businessId, data);
  }

  static List<DebtRes> getCachedDebts(int businessId) {
    final data = _debtsBox.get(businessId);
    if (data == null) return [];
    return (data as List).map((json) => DebtRes.fromJson(Map<String, dynamic>.from(json))).toList();
  }
}
