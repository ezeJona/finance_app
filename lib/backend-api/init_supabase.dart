import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_configuration.dart';

Future<void> initSupabase() async {
  // run this in main after WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
}