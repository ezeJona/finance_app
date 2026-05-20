import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../colors.dart';
import '../text_styles.dart';
import '../providers/auth_user.dart';
import '../providers/municipalities.dart';

class StartPage extends HookConsumerWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkSessionState = useCallback(() async {
      await Future.delayed(const Duration(milliseconds: 1500));
      final authUserRes = ref.read(authUserProvider.notifier).checkSession();
      if (authUserRes != null) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    }, []);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkSessionState();
      });
      return;
    }, []);

    useEffect(() {
      // fetch all municipalities on startup
      ref.read(municipalitiesProvider.notifier).fetch();
      return;
    }, []);

    return Scaffold(
      backgroundColor: HospiredColors.confirmedForegroundColor,
      body: Center(child: Image.asset("assets/logotipo.png", height: 120)),
    );
  }
}
