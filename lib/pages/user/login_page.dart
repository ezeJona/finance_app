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
    }, [emailController, passwordController, authUserNotifier]);

    final onRequestAccountTap = useCallback((BuildContext context) {
      Navigator.of(context).pushNamed('/login/sign-up');
    }, []);

    // Colores basados en la imagen y consistencia del diseño
    const Color darkNavy = Color(0xFF1E2530);
    const Color whatsappGreen = Color(0xFF25D366);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¡Hola de nuevo!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: darkNavy,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Ilustración central (Placeholder estilizado)
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Sombra/Fondo de la ilustración
                          Container(
                            height: 140,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          // "Teléfono" e "Icono de usuario"
                          Container(
                            height: 120,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey.shade300, width: 2),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_circle, size: 40, color: Colors.orange.shade300),
                                const SizedBox(height: 8),
                                Container(height: 4, width: 40, color: Colors.grey.shade200),
                                const SizedBox(height: 4),
                                Container(height: 4, width: 40, color: Colors.grey.shade200),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),

                  // Campos de entrada
                  TextField(
                    controller: emailController,
                    onChanged: (value) => error.value = "",
                    readOnly: loading.value,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Correo Electrónico",
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.black54),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: darkNavy, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    readOnly: loading.value,
                    onChanged: (value) => error.value = "",
                    decoration: InputDecoration(
                      hintText: "Contraseña",
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: darkNavy, width: 1.5),
                      ),
                    ),
                    onSubmitted: (value) => login(context),
                  ),
                  
                  const SizedBox(height: 32),

                  // Botón de Ingreso
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: FilledButton(
                      onPressed: loading.value ? null : () => login(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: darkNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: loading.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Ingresar",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Enlace de registro
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black54, fontSize: 15),
                      children: [
                        const TextSpan(text: "¿No tienes una cuenta creada? "),
                        TextSpan(
                          text: "Regístrate",
                          style: const TextStyle(
                            color: darkNavy,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => onRequestAccountTap(context),
                        ),
                      ],
                    ),
                  ),

                  // Manejo de Error
                  if (error.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        error.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: HospiredColors.danger, fontWeight: FontWeight.w500),
                      ),
                    ),
                  
                  const SizedBox(height: 100), // Espacio para no chocar con el FAB
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Acción de ayuda
        },
        backgroundColor: whatsappGreen,
        elevation: 4,
        icon: const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
        label: const Text(
          "Necesito ayuda",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
