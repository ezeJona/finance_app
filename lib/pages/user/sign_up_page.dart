import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../backend-api/api_service.dart';
import '../../text_styles.dart';

class SignUpPage extends HookConsumerWidget {
  const SignUpPage({super.key});

  // Constantes de estilo basadas en la línea gráfica de Balance y Onboarding
  static const Color darkNavy = Color(0xFF1E2530);
  static const Color emeraldGreen = Color(0xFF00A86B);
  static const Color textGray = Color(0xFF4A4A4A);
  static const Color lightGray = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎛️ LÓGICA DE NEGOCIO ORIGINAL (Totalmente Intacta)
    final signUpInProcess = useState<bool>(false);
    final signUpSuccessful = useState<bool>(false);
    final error = useState<String>("");

    final TextEditingController emailController = useTextEditingController();
    final TextEditingController password1Controller = useTextEditingController();
    final TextEditingController password2Controller = useTextEditingController();

    // Hook local para términos y condiciones (Estético/Funcional básico)
    final acceptTerms = useState<bool>(false);

    final signUp = useCallback(() async {
      final email = emailController.text.trim();
      final pw1 = password1Controller.text.trim();
      final pw2 = password2Controller.text.trim();

      if (email.isEmpty) {
        error.value = "Por favor, ingresa tu correo electrónico";
        return;
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        error.value = "Por favor, ingresa un correo electrónico válido";
        return;
      }

      if (pw1 != pw2) {
        error.value = "Las contraseñas no coinciden";
        return;
      }
      if (pw1.length < 8) {
        error.value = "La contraseña debe tener mínimo 8 caracteres";
        return;
      }
      try {
        signUpInProcess.value = true;
        error.value = ""; // Limpiar error previo
        await ApiService.signUpUser(email, pw2);
        signUpSuccessful.value = true;
      } catch (e) {
        // Capturamos el error real para mostrarlo
        String errorMessage = e.toString();
        if (errorMessage.startsWith("Exception: ")) {
          errorMessage = errorMessage.substring(11);
        }
        error.value = errorMessage;
      } finally {
        signUpInProcess.value = false;
      }
    }, [emailController, password1Controller, password2Controller]);

    return Scaffold(
      backgroundColor: Colors.white, // Fondo limpio de la referencia
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkNavy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // Cierra teclado al tocar fuera
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. LÍNEA DE PROCESO (Progress Indicator)
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: signUpSuccessful.value ? 1.0 : 0.35, // 100% si el registro fue exitoso
                              minHeight: 4,
                              backgroundColor: lightGray,
                              valueColor: const AlwaysStoppedAnimation<Color>(emeraldGreen),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // 2. TEXTOS ENCABEZADOS
                          const Text(
                            'Tu información siempre segura',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: darkNavy,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Accede con tus credenciales seguras para proteger tu dinero.',
                            style: TextStyle(
                              fontSize: 16,
                              color: textGray,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Mostrar errores de validación si existen
                          if (error.value.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                error.value,
                                style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 3. FLUJO DINÁMICO DE CAMPOS
                          if (!signUpSuccessful.value) ...[
                            // Campo Correo Electrónico
                            _buildCustomTextField(
                              controller: emailController,
                              labelText: 'Correo Electrónico',
                              hintText: 'ejemplo@correo.com',
                              keyboardType: TextInputType.emailAddress,
                              readOnly: signUpInProcess.value,
                              onChanged: (value) => error.value = "",
                            ),
                            const SizedBox(height: 20),

                            // Campo Contraseña 1
                            _buildCustomTextField(
                              controller: password1Controller,
                              labelText: 'Contraseña',
                              hintText: 'Mínimo 8 caracteres',
                              obscureText: true,
                              readOnly: signUpInProcess.value,
                              onChanged: (value) => error.value = "",
                            ),
                            const SizedBox(height: 20),

                            // Campo Contraseña 2
                            _buildCustomTextField(
                              controller: password2Controller,
                              labelText: 'Repetir Contraseña',
                              hintText: 'Confirma tu contraseña',
                              obscureText: true,
                              readOnly: signUpInProcess.value,
                              onChanged: (value) => error.value = "",
                              onSubmitted: (value) => acceptTerms.value ? signUp() : null,
                            ),
                            const SizedBox(height: 24),

                            // 4. CHECKBOX DE TÉRMINOS Y CONDICIONES
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: acceptTerms.value,
                                    activeColor: darkNavy,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) => acceptTerms.value = val ?? false,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'Aceptas los ',
                                      style: TextStyle(color: textGray, fontSize: 14, height: 1.3),
                                      children: [
                                        TextSpan(
                                          text: 'términos y condiciones',
                                          style: TextStyle(
                                            decoration: TextDecoration.underline,
                                            fontWeight: FontWeight.w600,
                                            color: darkNavy,
                                          ),
                                        ),
                                        TextSpan(text: ' y autorizas el '),
                                        TextSpan(
                                          text: 'tratamiento de datos personales.',
                                          style: TextStyle(
                                            decoration: TextDecoration.underline,
                                            fontWeight: FontWeight.w600,
                                            color: darkNavy,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(), // Empuja los botones hacia la parte inferior de manera responsiva
                            const SizedBox(height: 32),

                            // 5. BOTÓN PRINCIPAL RECTANGULAR OVALADO
                            SizedBox(
                              height: 56,
                              child: FilledButton(
                                onPressed: (signUpInProcess.value || !acceptTerms.value) ? null : () => signUp(),
                                style: FilledButton.styleFrom(
                                  backgroundColor: darkNavy,
                                  disabledBackgroundColor: darkNavy.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: signUpInProcess.value
                                    ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                                    : const Text(
                                  'Continuar',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ] else ...[
                            // Estado de Éxito en el Registro - UX Mejorada y Compacta
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: emeraldGreen.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.mark_email_read_rounded,
                                      size: 64,
                                      color: emeraldGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    "¡Verifica tu correo!",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: darkNavy,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: const TextStyle(fontSize: 15, color: textGray, height: 1.4),
                                      children: [
                                        const TextSpan(text: "Enviamos un enlace a:\n"),
                                        TextSpan(
                                          text: emailController.text,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: darkNavy,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: lightGray.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.info_outline, color: darkNavy, size: 18),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "Revisa tu bandeja de entrada o spam para activar tu cuenta.",
                                            style: TextStyle(fontSize: 13, color: textGray),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 56,
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: darkNavy,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text(
                                  "Ir a Iniciar Sesión",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // 6. TEXTO DE ALTERNATIVA INTERACTIVO (Solo se muestra si no ha tenido éxito)
                          if (!signUpSuccessful.value)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('¿Ya tienes una cuenta? ', style: TextStyle(color: textGray, fontSize: 14)),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'Inicia Sesión',
                                    style: TextStyle(color: darkNavy, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Helper modular para construir inputs idénticos a los de la captura de pantalla
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    bool obscureText = false,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: labelText,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkNavy),
            children: const [
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 16, color: darkNavy),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.black26),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: darkNavy, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: darkNavy, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: lightGray, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}