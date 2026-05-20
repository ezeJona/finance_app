import 'package:flutter/material.dart';
import '../DatabaseHelper.dart';
import 'package:intl/intl.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> citas = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final data = await dbHelper.getCitas();

    for (var cita in data) {
      debugPrint("📅 Fecha en BD: ${cita['fecha']}");
    }

    setState(() {
      citas = data;
    });
  }

  void _agendarCita(BuildContext context) async {
    final proxima = await dbHelper.getProximaCitaDisponible();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Confirmar Cita"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Doctor asignado: ${proxima['doctor']}"),
                const SizedBox(height: 8),
                Text(
                  "Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(proxima['fecha']!))}",
                ),
                Text("Hora: ${proxima['hora']}"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await dbHelper.addCita(
                    proxima['doctor']!,
                    proxima['fecha']!,
                    proxima['hora']!,
                  );
                  Navigator.pop(context);
                  _loadAppointments();
                },
                child: const Text("Confirmar"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Citas')),
      body: citas.isEmpty
          ? const Center(child: Text("No hay citas registradas"))
          : ListView.builder(
              itemCount: citas.length,
              itemBuilder: (context, index) {
                final cita = citas[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.calendar_today,
                      color: Colors.teal,
                    ),
                    title: Text("Cita con ${cita['doctor']}"),
                    subtitle: Text(
                      "${DateFormat('dd/MM/yyyy').format(DateTime.parse(cita['fecha'] as String))} - ${cita['hora']}",
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _agendarCita(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
