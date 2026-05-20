import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../DatabaseHelper.dart';
import '../notifications_service.dart';

// Función para programar una notificación diaria para un medicamento.
// Usa el id (por ejemplo el id de la fila en SQLite) para evitar duplicados.
Future<void> scheduleMedicationNotification({
  required int id,
  required String title,
  required String body,
  required String timeString, // espera "08:00 AM" o "20:00"
}) async {
  final now = DateTime.now();

  // Intentar varios formatos comunes
  DateTime? parsed;
  try {
    parsed = DateFormat('hh:mm a').parse(timeString); // e.g. 08:00 AM
  } catch (_) {
    try {
      parsed = DateFormat('HH:mm').parse(timeString); // e.g. 20:00
    } catch (_) {
      parsed = null;
    }
  }

  if (parsed == null) {
    debugPrint(
      'scheduleMedicationNotification: formato hora no válido: $timeString',
    );
    return;
  }

  DateTime scheduled = DateTime(
    now.year,
    now.month,
    now.day,
    parsed.hour,
    parsed.minute,
  );

  if (scheduled.isBefore(now))
    scheduled = scheduled.add(const Duration(days: 1));

  // Evitar duplicados: cancelar notificación previa con mismo id
  await flutterLocalNotificationsPlugin.cancel(id);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    tz.TZDateTime.from(scheduled, tz.local),
    NotificationDetails(
      android: AndroidNotificationDetails(
        'med_channel_id',
        'Recordatorios de Medicamentos',
        channelDescription: 'Recordatorios diarios de medicamentos',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    // repetir todos los días a la misma hora
    matchDateTimeComponents: DateTimeComponents.time,
  );

  debugPrint(
    'Notificación programada: id=$id at ${scheduled.toIso8601String()}',
  );
}

class TreatmentPage extends StatefulWidget {
  const TreatmentPage({super.key});

  @override
  State<TreatmentPage> createState() => _TreatmentPageState();
}

class _TreatmentPageState extends State<TreatmentPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> medicamentos = [];

  @override
  void initState() {
    super.initState();
    _loadMedicamentos();
  }

  Future<void> _loadMedicamentos() async {
    final data = await dbHelper.getMedicamentos();
    setState(() {
      medicamentos = data;
    });

    for (var med in data) {
      final int id = med['id'] as int; // asegúrate que 'id' existe
      final String nombre = med['nombre'] as String;
      final String hora = med['hora'] as String;
      await scheduleMedicationNotification(
        id: id,
        title: 'Recordatorio de medicamento',
        body: 'Es hora de tomar $nombre',
        timeString: hora,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tratamiento')),
      body: medicamentos.isEmpty
          ? const Center(child: Text("No hay medicamentos registrados"))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Medicamentos y Horarios",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: medicamentos.length,
                      itemBuilder: (context, index) {
                        final med = medicamentos[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.medical_services,
                              color: Colors.teal,
                            ),
                            title: Text(med['nombre']),
                            subtitle: Text("Tomar a las ${med['hora']}"),
                            trailing: const Icon(
                              Icons.notifications_active,
                              color: Colors.red,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
