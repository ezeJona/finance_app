import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../backend-api/api_service.dart';
import '../backend-api/dtos.dart';
import 'auth_user.dart';

final businessesProvider = FutureProvider.autoDispose<List<BusinessRes>>((ref) async {
  final authUser = ref.watch(authUserProvider);
  if (authUser == null) return [];
  return await ApiService.getBusinesses(authUser.id);
});
