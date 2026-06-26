import 'package:flutter/material.dart';

enum EducationalCategory { finance, security }

class EducationalModule {
  final String id;
  final EducationalCategory category;
  final String title;
  final IconData icon;
  final String shortDescription;
  final List<EducationalPoint> content;

  EducationalModule({
    required this.id,
    required this.category,
    required this.title,
    required this.icon,
    required this.shortDescription,
    required this.content,
  });
}

class EducationalPoint {
  final String title;
  final String body;
  final bool isAlert;

  EducationalPoint({
    required this.title,
    required this.body,
    this.isAlert = false,
  });
}

final List<EducationalModule> educationalModules = [
  // --- FINANZAS ---
  EducationalModule(
    id: 'f1',
    category: EducationalCategory.finance,
    title: 'Cómo poner precios',
    icon: Icons.calculate_outlined,
    shortDescription: 'Aprende a calcular tu ganancia real sin perder dinero.',
    content: [
      EducationalPoint(
        title: 'La Fórmula Maestra',
        body: 'Para ganar dinero, tu precio debe cubrir: Costo del producto + Gastos (luz, transporte) + Tu Ganancia.',
      ),
      EducationalPoint(
        title: 'El error de competir solo por precio',
        body: 'Si bajas mucho tus precios para ganarle al vecino, podrías terminar trabajando gratis o perdiendo dinero. Diferénciate por tu servicio.',
        isAlert: true,
      ),
    ],
  ),
  EducationalModule(
    id: 'f2',
    category: EducationalCategory.finance,
    title: 'Separar dinero personal',
    icon: Icons.account_balance_wallet_outlined,
    shortDescription: 'El secreto de los negocios que crecen: No mezclar bolsillos.',
    content: [
      EducationalPoint(
        title: 'Ponte un Salario',
        body: 'Asígnate un pago fijo semanal o mensual. Ese es tu dinero para gastos de casa. El resto pertenece al negocio.',
      ),
      EducationalPoint(
        title: 'La Caja es Sagrada',
        body: 'Nunca saques dinero de la caja para comprar comida del hogar o pagar deudas personales. Si lo haces, tu negocio nunca tendrá capital para resurtir.',
        isAlert: true,
      ),
    ],
  ),
  EducationalModule(
    id: 'f3',
    category: EducationalCategory.finance,
    title: 'Cómo ahorrar',
    icon: Icons.savings_outlined,
    shortDescription: 'Pequeños montos diarios hacen grandes cambios.',
    content: [
      EducationalPoint(
        title: 'Regla del 5% o 10%',
        body: 'Guarda un pequeño porcentaje de tus ventas diarias en un lugar separado. Úsalo solo para emergencias o para invertir en más mercancía.',
      ),
    ],
  ),
  EducationalModule(
    id: 'f4',
    category: EducationalCategory.finance,
    title: 'Evitar pérdidas',
    icon: Icons.inventory_2_outlined,
    shortDescription: 'Cuida tu inventario y evita que el dinero se evapore.',
    content: [
      EducationalPoint(
        title: 'Control de Mermas',
        body: 'Revisa fechas de vencimiento semanalmente. Lo que está por vencer, ponlo en oferta para recuperar al menos el costo.',
      ),
      EducationalPoint(
        title: 'Usa esta App',
        body: 'Llevar el inventario al día aquí te permite saber exactamente qué tienes y qué te falta, evitando compras innecesarias.',
      ),
    ],
  ),

  // --- SEGURIDAD ---
  EducationalModule(
    id: 's1',
    category: EducationalCategory.security,
    title: 'Evitar estafas',
    icon: Icons.gpp_maybe_outlined,
    shortDescription: 'Identifica clientes sospechosos antes de que sea tarde.',
    content: [
      EducationalPoint(
        title: 'Presión por rapidez',
        body: 'Si un cliente te apura demasiado para que le entregues mercancía sin verificar el pago, ¡Cuidado! Es la técnica favorita de los estafadores.',
        isAlert: true,
      ),
    ],
  ),
  EducationalModule(
    id: 's2',
    category: EducationalCategory.security,
    title: 'Contraseñas seguras',
    icon: Icons.password_outlined,
    shortDescription: 'Protege tu acceso y el de tu negocio.',
    content: [
      EducationalPoint(
        title: 'No uses fechas obvias',
        body: 'Evita usar tu fecha de nacimiento o nombres de tus hijos. Son fáciles de adivinar.',
      ),
      EducationalPoint(
        title: 'Usa frases cortas',
        body: 'Es más fácil recordar "MiCafeEsRico1" que una palabra suelta. Mezcla mayúsculas y números.',
      ),
    ],
  ),
  EducationalModule(
    id: 's3',
    category: EducationalCategory.security,
    title: 'Fraudes por WhatsApp',
    icon: Icons.message_outlined,
    shortDescription: 'No confíes en todo lo que recibes en tu celular.',
    content: [
      EducationalPoint(
        title: 'Capturas de pantalla falsas',
        body: 'Muchos estafadores mandan fotos editadas de transferencias de bancos (BAC, LAFISE, Banpro).',
        isAlert: true,
      ),
      EducationalPoint(
        title: 'Regla de Oro del Pago',
        body: 'NUNCA entregues mercancía hasta que tú mismo entres a tu aplicación bancaria y confirmes que el dinero YA está en tu cuenta. No confíes en el comprobante que te manden.',
        isAlert: true,
      ),
    ],
  ),
  EducationalModule(
    id: 's4',
    category: EducationalCategory.security,
    title: 'Cuentas falsas',
    icon: Icons.no_accounts_outlined,
    shortDescription: 'Proveedores y clientes que no son quienes dicen ser.',
    content: [
      EducationalPoint(
        title: 'Verifica el perfil',
        body: 'Si un proveedor te contacta de la nada con precios "demasiado buenos para ser verdad", revisa sus fotos y comentarios. Si el perfil es nuevo, probablemente sea falso.',
      ),
    ],
  ),
];
