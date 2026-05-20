import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabase() async {
  // run this in main after WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: 'https://ettjyqzimhpvljdmtpiq.supabase.co', anonKey: 'sb_publishable_ajZ1iDfwIYqU8Sq1QLCvgA_aUAmtufh');
}
