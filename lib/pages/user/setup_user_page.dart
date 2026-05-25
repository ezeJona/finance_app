import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../backend-api/api_service.dart';
import '../../backend-api/dtos.dart';
import '../../colors.dart';
import '../../providers/app_user.dart';
import '../../providers/auth_user.dart';
import '../../providers/municipalities.dart';
import '../../providers/patient.dart';
import '../../text_styles.dart';
import '../../ui/alert_dialogs.dart';

class SetupUserPage extends HookConsumerWidget {
  const SetupUserPage({super.key});

  // Constantes de estilo unificadas de la nueva línea gráfica
  static const Color darkNavy = Color(0xFF1E2530);
  static const Color emeraldGreen = Color(0xFF00A86B);
  static const Color textGray = Color(0xFF4A4A4A);
  static const Color lightGray = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎛️ LOGICA Y PROVIDERS ORIGINALES (Intactas)
    final authUser = ref.watch(authUserProvider);
    final municipalities = ref.watch(municipalitiesProvider);

    final creatingUser = useState<bool>(false);
    final error = useState<String>("");
    final setupStep = useState<int>(0); // 0: setup app_user, 1: setup patient

    final TextEditingController firstNameController = useTextEditingController();
    final TextEditingController secondNameController = useTextEditingController();
    final TextEditingController firstLastNameController = useTextEditingController();
    final TextEditingController secondLastNameController = useTextEditingController();
    final TextEditingController nationalIdController = useTextEditingController();
    final TextEditingController inssIdController = useTextEditingController();
    final TextEditingController phoneNumberController = useTextEditingController();
    final TextEditingController districtController = useTextEditingController();
    final TextEditingController occupationController = useTextEditingController();
    final selectedMunicipality = useState<MunicipalityRes?>(null);

    final dateOfBirth = useState<DateTime?>(null);

    Future<void> pickDateOfBirth(BuildContext context) async {
      final now = DateTime.now();
      final initialDate = dateOfBirth.value ?? DateTime(now.year - 18);
      final newDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(1900),
        lastDate: now,
        locale: const Locale('es'),
      );

      if (newDate != null) {
        dateOfBirth.value = newDate;
      }
    }

    final showIncompleteUserInputsDialog = useCallback((
        BuildContext context,
        String infoText,
        ) async {
      await warningDialog(
        context: context,
        title: "Datos incompletos",
        infoText: infoText,
      );
    }, []);

    final callCreateAppUser = useCallback((BuildContext context) async {
      String firstName = firstNameController.text;
      String secondName = secondNameController.text;
      String firstLastName = firstLastNameController.text;
      String secondLastName = secondLastNameController.text;

      if (authUser != null) {
        creatingUser.value = true;
        error.value = "";
        try {
          final AppUserRes createdUser = await ApiService.createAppUser(
            CreateAppUserReq(
              id: authUser.id,
              firstName: firstName,
              secondName: secondName,
              firstLastName: firstLastName,
              secondLastName: secondLastName,
              dateOfBirth: dateOfBirth.value,
            ),
          );
          final PatientRes patient = await ApiService.createPatient(
            CreatePatientReq(
              appUserId: createdUser.id,
              nationalId: nationalIdController.text,
              municipalityId: selectedMunicipality.value!.id,
              inssId: inssIdController.text.isNotEmpty
                  ? int.tryParse(inssIdController.text)
                  : null,
              phoneNumber: phoneNumberController.text,
              occupation: occupationController.text,
              neighborHood: districtController.text,
            ),
          );
          ref.read(appUserProvider.notifier).set(createdUser);
          ref.read(patientProvider.notifier).set(patient);
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } catch (err) {
          error.value = err.toString();
        } finally {
          creatingUser.value = false;
        }
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }, []);

    final continueButtonPressed = useCallback((BuildContext context) async {
      if (creatingUser.value) {
        return null;
      } else if (setupStep.value == 0) {
        if (firstNameController.text.isEmpty ||
            firstLastNameController.text.isEmpty) {
          await showIncompleteUserInputsDialog(
            context,
            "Debe ingresar mínimo un nombre y un apellido.",
          );
          return;
        }
        setupStep.value = 1;
      } else {
        if (nationalIdController.text.isEmpty) {
          await showIncompleteUserInputsDialog(
            context,
            "Debe ingresar su número de Cédula.",
          );
          return;
        }
        callCreateAppUser(context);
      }
    }, []);

    useEffect(() {
      ref.read(municipalitiesProvider.notifier).fetch();
      return;
    }, []);

    return Scaffold(
      backgroundColor: Colors.white, // Fondo limpio unificado
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: setupStep.value == 1
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: darkNavy),
          onPressed: () => setupStep.value = 0,
        )
            : null,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // Cierre de teclado optimizado
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
                          // 1. INDICADOR DE PROGRESO SUPERIOR
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: setupStep.value == 0 ? 0.75 : 1.0, // Progreso: 75% info personal, 100% negocio
                              minHeight: 4,
                              backgroundColor: lightGray,
                              valueColor: const AlwaysStoppedAnimation<Color>(emeraldGreen),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // 2. TEXTOS DE ENCABEZADO DINÁMICOS
                          Text(
                            setupStep.value == 0
                                ? "Cuéntanos sobre ti"
                                : "Configura tu negocio y contacto",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: darkNavy,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            setupStep.value == 0
                                ? "Completa tus nombres y fecha de nacimiento para tu perfil oficial."
                                : "Ingresa tus identificaciones y locación para habilitar los reportes.",
                            style: const TextStyle(
                              fontSize: 16,
                              color: textGray,
                              height: 1.4,
                            ),
                          ),

                          // Muestra de correo electrónico de cuenta activa de forma elegante
                          if (authUser?.email != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              "Cuenta activa: ${authUser!.email}",
                              style: TextStyle(
                                fontSize: 13,
                                color: textGray.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),

                          // 3. MANEJO DE ERRORES VISUALES
                          if (error.value.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                error.value,
                                style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // 4. FLUJO DINÁMICO DE ENTRADAS DE TEXTO Y SELECTORES
                          if (setupStep.value == 0) ...[
                            _buildCustomTextField(
                              controller: firstNameController,
                              labelText: "Primer Nombre",
                              hintText: "Juan",
                              isRequired: true,
                              readOnly: creatingUser.value,
                              onChanged: (value) => error.value = "",
                            ),
                            const SizedBox(height: 20),
                            _buildCustomTextField(
                              controller: secondNameController,
                              labelText: "Segundo Nombre",
                              hintText: "Carlos",
                              readOnly: creatingUser.value,
                              onChanged: (value) => error.value = "",
                            ),
                            const SizedBox(height: 20),
                            _buildCustomTextField(
                              controller: firstLastNameController,
                              labelText: "Primer Apellido",
                              hintText: "Rodríguez",
                              isRequired: true,
                              readOnly: creatingUser.value,
                              onChanged: (value) => error.value = "",
                            ),
                            const SizedBox(height: 20),
                            _buildCustomTextField(
                              controller: secondLastNameController,
                              labelText: "Segundo Apellido",
                              hintText: "Cuaresma",
                              readOnly: creatingUser.value,
                              onChanged: (value) => error.value = "",
                            ),
                            const SizedBox(height: 20),

                            // Selector de Fecha de Nacimiento Estilizado
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Fecha de nacimiento",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkNavy),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: creatingUser.value ? null : () => pickDateOfBirth(context),
                                  borderRadius: BorderRadius.circular(16),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(color: darkNavy, width: 1.5),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(color: darkNavy, width: 2),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          dateOfBirth.value != null
                                              ? "${dateOfBirth.value!.day}/${dateOfBirth.value!.month}/${dateOfBirth.value!.year}"
                                              : "Seleccionar fecha",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: dateOfBirth.value != null ? darkNavy : Colors.black26,
                                            fontWeight: dateOfBirth.value != null ? FontWeight.normal : FontWeight.w400,
                                          ),
                                        ),
                                        const Icon(Icons.calendar_today_outlined, size: 20, color: darkNavy),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            _buildCustomTextField(
                              controller: nationalIdController,
                              labelText: "Cédula",
                              hintText: "123-456789-0001A",
                              isRequired: true,
                              readOnly: creatingUser.value,
                              onChanged: (value) => error.value = "",
                            ),
                            const SizedBox(height: 20),
                            _buildCustomTextField(
                              controller: inssIdController,
                              labelText: "Número INSS",
                              hintText: "12345678",
                              readOnly: creatingUser.value,
                              onChanged: (value) => error.value = "",
                            ),
                            const SizedBox(height: 20),

                            // Selector Dropdown Municipalidad Estilizado a la Línea Gráfica
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Municipio",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkNavy),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<MunicipalityRes>(
                                  style: const TextStyle(fontSize: 16, color: darkNavy),
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: darkNavy),
                                  decoration: InputDecoration(
                                    hintText: "Selecciona tu municipio",
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
                                  ),
                                  initialValue: selectedMunicipality.value,
                                  onChanged: creatingUser.value
                                      ? null
                                      : (MunicipalityRes? municipality) {
                                    selectedMunicipality.value = municipality;
                                  },
                                  items: municipalities?.map<DropdownMenuItem<MunicipalityRes>>((
                                      MunicipalityRes municipality,
                                      ) {
                                    return DropdownMenuItem<MunicipalityRes>(
                                      value: municipality,
                                      child: Text(municipality.name),
                                    );
                                  }).toList() ?? [],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildCustomTextField(
                              controller: districtController,
                              labelText: "Residencial, Barrio, Comarca o Distrito",
                              hintText: "Bosques de Altamira",
                              readOnly: creatingUser.value,
                              onChanged: (value) => error.value = "",
                            ),
                            const SizedBox(height: 20),
                            _buildCustomTextField(
                              controller: occupationController,
                              labelText: "Ocupación",
                              hintText: "Fisioterapeuta",
                              readOnly: creatingUser.value,
                              onChanged: (value) => error.value = "",
                            ),
                            const SizedBox(height: 20),
                            _buildCustomTextField(
                              controller: phoneNumberController,
                              labelText: "Número de teléfono",
                              hintText: "8512 3456",
                              readOnly: creatingUser.value,
                              onChanged: (value) => error.value = "",
                            ),
                          ],

                          const Spacer(), // Empuja el botón al fondo de forma fluida
                          const SizedBox(height: 32),

                          // 5. BOTÓN PRINCIPAL DE ACCIÓN OVALADO
                          SizedBox(
                            height: 56,
                            child: FilledButton(
                              onPressed: creatingUser.value ? null : () => continueButtonPressed(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: darkNavy,
                                disabledBackgroundColor: darkNavy.withOpacity(0.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: creatingUser.value
                                  ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                                  : Text(
                                setupStep.value == 0 ? "Continuar" : "Listo",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
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

  // Helper modular e inyectable de inputs alineado con Sign Up e imágenes de referencia
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    bool isRequired = false,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: labelText,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkNavy),
            children: [
              if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          onChanged: onChanged,
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