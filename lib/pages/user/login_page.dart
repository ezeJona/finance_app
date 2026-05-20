import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../backend-api/api_service.dart';
import '../../backend-api/dtos.dart';
import '../../colors.dart';
import '../../providers/auth_user.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUserNotifier = ref.read(authUserProvider.notifier);

    final loading = useState<bool>(false);
    final error = useState<String>("");

    final TextEditingController emailController = useTextEditingController();
    final TextEditingController passwordController = useTextEditingController();

    final login = useCallback((BuildContext context) async {
      FocusScope.of(context).unfocus();
      loading.value = true;

      try {
        final res = await ApiService.signInUser(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
        final authUserRes = AuthUserRes(
          id: res.id,
          email: res.email ?? "${res.id}@hospired.com.ni",
        );
        authUserNotifier.set(authUserRes);
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        error.value = "Correo electrónico o contraseña incorrecta";
      } finally {
        loading.value = false;
      }
    }, []);

    final onRequestAccountTap = useCallback((BuildContext context) {
      Navigator.of(context).pushNamed('/login/sign-up');
    }, []);

    return Scaffold(
      appBar: AppBar(title: const Text('H O S P I R E D')),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black, fontSize: 16),
                      children: [
                        TextSpan(text: "¿No tienes cuenta? "),
                        TextSpan(
                          text: "Regístrate",
                          style: TextStyle(
                            color: HospiredColors.confirmedForegroundColor,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => onRequestAccountTap(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              TextField(
                controller: emailController,
                onChanged: (value) => error.value = "",
                readOnly: loading.value,
                decoration: const InputDecoration(
                  labelText: "Correo Electrónico",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                readOnly: loading.value,
                onChanged: (value) => error.value = "",
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) => login(context),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: loading.value ? null : () => login(context),
                child: const Text("Ingresar"),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  error.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: HospiredColors.danger),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
