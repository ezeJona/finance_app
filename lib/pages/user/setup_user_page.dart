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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authUserProvider);
    final municipalities = ref.watch(municipalitiesProvider);

    final creatingUser = useState<bool>(false);
    final error = useState<String>("");
    final setupStep = useState<int>(0); // 0: setup app_user, 1: setup patient

    final TextEditingController firstNameController =
        useTextEditingController();
    final TextEditingController secondNameController =
        useTextEditingController();
    final TextEditingController firstLastNameController =
        useTextEditingController();
    final TextEditingController secondLastNameController =
        useTextEditingController();
    final TextEditingController nationalIdController =
        useTextEditingController();
    final TextEditingController inssIdController = useTextEditingController();
    final TextEditingController phoneNumberController =
        useTextEditingController();
    final TextEditingController districtController = useTextEditingController();
    final TextEditingController occupationController =
        useTextEditingController();
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
      appBar: AppBar(title: const Text('H O S P I R E D')),
      body: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              Row(
                children: [
                  if (setupStep.value == 1) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setupStep.value = 0,
                    ),
                  ],
                  Text(
                    setupStep.value == 0
                        ? "Configurar Usuario"
                        : "Datos del Paciente",
                    style: HospiredTextStyle.title4,
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Text(
                    authUser != null ? "Correo electrónico:" : "",
                    style: HospiredTextStyle.title2,
                  ),
                  const SizedBox(width: 12),
                  Text(authUser?.email ?? ""),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    if (setupStep.value == 0) ...[
                      Text("Nombres", style: HospiredTextStyle.title3),
                      const SizedBox(height: 8),
                      TextField(
                        controller: firstNameController,
                        readOnly: creatingUser.value,
                        onChanged: (value) => error.value = "",
                        decoration: const InputDecoration(
                          hintText: "Juan",
                          labelText: "Primer Nombre *",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: secondNameController,
                        readOnly: creatingUser.value,
                        onChanged: (value) => error.value = "",
                        decoration: const InputDecoration(
                          hintText: "Carlos",
                          labelText: "Segundo Nombre",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text("Apellidos", style: HospiredTextStyle.title3),
                      const SizedBox(height: 8),
                      TextField(
                        controller: firstLastNameController,
                        readOnly: creatingUser.value,
                        onChanged: (value) => error.value = "",
                        decoration: const InputDecoration(
                          hintText: "Rodriguez",
                          labelText: "Primer Apellido *",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: secondLastNameController,
                        readOnly: creatingUser.value,
                        onChanged: (value) => error.value = "",
                        decoration: const InputDecoration(
                          hintText: "Cuaresma",
                          labelText: "Segundo Apellido",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Fecha de nacimiento",
                        style: HospiredTextStyle.title3,
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => pickDateOfBirth(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: dateOfBirth.value != null
                                ? "Fecha de nacimiento"
                                : "",
                            border: const OutlineInputBorder(),
                          ),
                          child: Text(
                            dateOfBirth.value != null
                                ? "${dateOfBirth.value!.day}/${dateOfBirth.value!.month}/${dateOfBirth.value!.year}"
                                : "Seleccionar",
                            style: TextStyle(
                              color: dateOfBirth.value != null
                                  ? Colors.black
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        "Cédula y Seguro Social",
                        style: HospiredTextStyle.title3,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nationalIdController,
                        readOnly: creatingUser.value,
                        onChanged: (value) => error.value = "",
                        decoration: const InputDecoration(
                          labelText: "Cédula *",
                          border: OutlineInputBorder(),
                          hintText: "123-456789-0001A",
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: inssIdController,
                        readOnly: creatingUser.value,
                        onChanged: (value) => error.value = "",
                        decoration: const InputDecoration(
                          labelText: "Número INSS",
                          hintText: "12345678",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text("Dirección", style: HospiredTextStyle.title3),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<MunicipalityRes>(
                        decoration: const InputDecoration(
                          labelText: "Municipio",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        initialValue: selectedMunicipality.value,
                        onChanged: (MunicipalityRes? municipality) {
                          selectedMunicipality.value = municipality;
                        },
                        items:
                            municipalities
                                ?.map<DropdownMenuItem<MunicipalityRes>>((
                                  MunicipalityRes municipality,
                                ) {
                                  return DropdownMenuItem<MunicipalityRes>(
                                    value: municipality,
                                    child: Text(municipality.name),
                                  );
                                })
                                .toList() ??
                            [],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: districtController,
                        readOnly: creatingUser.value,
                        onChanged: (value) => error.value = "",
                        decoration: const InputDecoration(
                          labelText: "Residencial, Barrio, Comarca o Distrito",
                          hintText: "Bosques de Altamira",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Ocupación y contacto",
                        style: HospiredTextStyle.title3,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: occupationController,
                        readOnly: creatingUser.value,
                        onChanged: (value) => error.value = "",
                        decoration: const InputDecoration(
                          labelText: "Ocupación",
                          hintText: "Fisioterapeuta",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: phoneNumberController,
                        readOnly: creatingUser.value,
                        onChanged: (value) => error.value = "",
                        decoration: const InputDecoration(
                          labelText: "Número de teléfono",
                          hintText: "8512 3456",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => continueButtonPressed(context),
                      child: Text(setupStep.value == 0 ? "Continuar" : "Listo"),
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
            ],
          ),
        ),
      ),
    );
  }
}
