import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

class DatabaseHelper {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'hospired.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabla de usuarios
        await db.execute('''
          CREATE TABLE usuarios(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cedula TEXT UNIQUE,
            password TEXT
          )
        ''');

        await db.insert('usuarios', {
          'cedula': '1234567890',
          'password': '1234',
        });

        // Tabla de citas
        await db.execute('''
          CREATE TABLE citas(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            doctor TEXT,
            fecha TEXT,
            hora TEXT
          )
        ''');

        // Insertar citas iniciales
        await db.insert('citas', {
          'doctor': 'Dr. Pérez',
          'fecha': '2025-10-12',
          'hora': '10:00 AM',
        });

        await db.insert('citas', {
          'doctor': 'Dra. Martínez',
          'fecha': '2025-10-15',
          'hora': '4:00 PM',
        });

        // Tabla de tratamientos
        await db.execute('''
          CREATE TABLE tratamientos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT,
            hora TEXT
          )
        ''');

        // Inserta medicamentos iniciales
        await db.insert('tratamientos', {
          'nombre': 'Paracetamol',
          'hora': '08:00 AM',
        });
        await db.insert('tratamientos', {
          'nombre': 'Amoxicilina',
          'hora': '12:00 PM',
        });
        await db.insert('tratamientos', {
          'nombre': 'Ibuprofeno',
          'hora': '06:00 PM',
        });
        await db.insert('tratamientos', {
          'nombre': 'Vitamina C',
          'hora': '09:00 PM',
        });
      },
    );
  }

  // ===================== LOGIN =====================
  Future<Map<String, dynamic>?> login(String cedula, String password) async {
    final db = await database;
    final res = await db.query(
      'usuarios',
      where: 'cedula = ? AND password = ?',
      whereArgs: [cedula, password],
    );
    return res.isNotEmpty ? res.first : null;
  }

  // ===================== CITAS =====================

  Future<List<Map<String, dynamic>>> getCitas() async {
    final db = await database;
    return await db.query('citas', orderBy: 'fecha ASC');
  }

  Future<int> addCita(String doctor, String fecha, String hora) async {
    final db = await database;
    return await db.insert('citas', {
      'doctor': doctor,
      'fecha': fecha,
      'hora': hora,
    });
  }

  /// Obtiene la próxima fecha disponible (simulada).
  /// Busca la última cita registrada y le suma 1 día.
  Future<Map<String, String>> getProximaCitaDisponible() async {
    final db = await database;
    final res = await db.query('citas', orderBy: 'fecha DESC', limit: 1);

    DateTime proximaFecha;
    String doctor = "Nuevo Doctor";

    if (res.isNotEmpty) {
      final ultimaFecha = DateTime.parse(res.first['fecha'] as String);
      proximaFecha = ultimaFecha.add(const Duration(days: 1));
    } else {
      proximaFecha = DateTime.now().add(const Duration(days: 1));
    }

    // Formatear fecha y hora
    String fecha = DateFormat('yyyy-MM-dd').format(proximaFecha);
    String hora = "10:00 AM"; // podrías hacerlo dinámico si quieres

    return {"doctor": doctor, "fecha": fecha, "hora": hora};
  }

  // ===================== TRATAMIENTOS =====================

  // Obtener lista de medicamentos
  Future<List<Map<String, dynamic>>> getMedicamentos() async {
    final db = await database;
    return await db.query('tratamientos', orderBy: 'hora ASC');
  }

  // Insertar nuevo medicamento
  Future<int> addMedicamento(String nombre, String hora) async {
    final db = await database;
    return await db.insert('tratamientos', {'nombre': nombre, 'hora': hora});
  }

  // Eliminar medicamento
  Future<int> deleteMedicamento(int id) async {
    final db = await database;
    return await db.delete('tratamientos', where: 'id = ?', whereArgs: [id]);
  }

  // Actualizar medicamento
  Future<int> updateMedicamento(int id, String nombre, String hora) async {
    final db = await database;
    return await db.update(
      'tratamientos',
      {'nombre': nombre, 'hora': hora},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
