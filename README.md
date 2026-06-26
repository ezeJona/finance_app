<div align="center">
  <img src="assets/finora f.png" alt="Finora Logo" width="180">
  <h1>Finora · Tu Aliado Financiero</h1>
  <p>Asistente virtual inteligente para la gestión integral de finanzas, inventarios y crecimiento empresarial.</p>

  [![Estado](https://img.shields.io/badge/estado-en%20desarrollo-yellow)](#)
  [![Versión](https://img.shields.io/badge/version-1.2.1-blue)](#)
  [![Licencia](https://img.shields.io/badge/licencia-MIT-green)](#)
</div>

---

## Índice
1. [Sobre el Proyecto](#sobre-el-proyecto)
2. [Características Principales](#características-principales)
3. [Tecnologías Utilizadas](#tecnologías-utilizadas)
4. [Estructura del Proyecto](#estructura-del-proyecto)
5. [Convenciones de Nomenclatura](#convenciones-de-nomenclatura)
6. [Instalación y Ejecución](#instalación-y-ejecución)
7. [Módulos del Sistema](#módulos-del-sistema)

---

## Sobre el Proyecto
**Finora** es una aplicación móvil desarrollada en Flutter diseñada para microempresarios y emprendedores. Su objetivo es simplificar la administración del negocio mediante herramientas de control financiero, gestión de stock y educación estratégica, todo potenciado por inteligencia artificial.

---

## Características Principales
- **Control de Flujo de Caja:** Registro detallado de ingresos y egresos.
- **Gestión de Inventario:** Catálogo visual con carga de imágenes a la nube.
- **Seguimiento de Deudas:** Control de cuentas por cobrar y por pagar.
- **Asistente Virtual IA:** Integración con OpenAI para consultas y consejos.
- **Academia del Negocio:** Módulos de micro-aprendizaje sobre finanzas y seguridad.
- **Reportes Profesionales:** Exportación de balances a Excel.
- **Modo Offline:** Sincronización automática al recuperar conexión.

---

## Tecnologías Utilizadas
- **Lenguaje:** Dart
- **Framework:** Flutter
- **Base de Datos & Auth:** Supabase (PostgreSQL, Auth, Storage)
- **Gestión de Estado:** Riverpod (Hooks & Providers)
- **Persistencia Local:** Hive & SharedPreferences
- **IA:** OpenAI API (GPT-4o)
- **Otros:** Excel (Reportes), CachedNetworkImage, fl_chart.

---

## Estructura del Proyecto
```plaintext
lib/
├── backend-api/        # DTOs, Servicios de API y lógica de sincronización.
├── models/             # Modelos de datos locales.
├── pages/              # Pantallas de la aplicación organizadas por módulo.
│   ├── academy/        # Modo educativo y Academia.
│   ├── chat/           # Asistente virtual (IA).
│   ├── dashboard/      # Balance general y flujo de caja.
│   ├── debts/          # Gestión de cuentas por cobrar/pagar.
│   ├── inventory/      # Control de stock y catálogo.
│   ├── profile/        # Gestión de perfil y resumen multinegocio.
│   ├── statistics/     # Reportes gráficos de rendimiento.
│   └── user/           # Flujos de Autenticación (Login, Sign-up, Setup).
├── providers/          # Lógica de negocio y gestión de estado (Riverpod).
├── widgets/            # Componentes de UI reutilizables.
└── utilities/          # Configuraciones globales y helpers.
```

---

## Convenciones de Nomenclatura
- **Clases y Tipos:** `PascalCase` (ej: `ProductRepository`).
- **Variables y Funciones:** `camelCase` (ej: `calculateProfit()`).
- **Archivos:** `snake_case` (ej: `inventory_view.dart`).
- **Constantes:** `camelCase` o `UPPER_SNAKE_CASE` según contexto (ej: `primaryYellow`).

---

## Instalación y Ejecución

### Requisitos Previos
- **Flutter SDK:** ^3.9.2
- **Android Studio / VS Code**
- **Supabase Project:** Configurar buckets de `profiles` y `products`.

### Pasos
1. **Clonar el repositorio:**
   <br>
   ```bash
   git clone https://github.com/ezeJona/finance_app.git
   
   cd finance_app
   ```
2. **Instalar dependencias:**
   <br>
   ```bash
   flutter pub get
   ```
3. **Configurar variables de entorno:**
   <br><br>
   Asegúrate de tener las claves de Supabase y OpenAI en los archivos de configuración correspondientes en `lib`.
   <br><br>
    Crea un archivo `supabase_configuration.dart` en la raíz del proyecto con la siguiente configuración mínima:
   <br>
    ```env
    const String supabaseUrl = 'https://xxxx.supabase.co'
    const String supabaseAnonKey = 'eyJhbGciOi...'
    ```
   <br><br>
   Crea un archivo `openai_configuration.dart` en la raíz del proyecto con la siguiente configuración mínima:
   <br>
    ```env
    const openAiApiKeyDev = "sk-x"
    ```
4. **Ejecutar:**
   <br>
   ```bash
   flutter run
   ```

---

## Módulos del Sistema

### Balance y Finanzas
Controla tus ingresos y gastos diarios. Visualiza tu saldo real y filtra por periodos para entender hacia dónde va tu dinero.

### Inventario Inteligente
Catálogo visual donde puedes subir fotos de tus productos. Incluye alertas de stock mínimo para que nunca te quedes sin mercancía.

### Gestión de Deudas
Registra abonos y saldos pendientes. Ideal para negocios que ofrecen crédito a sus clientes o manejan cuentas con proveedores.

### Academia Finora
Sección estática educativa con consejos sobre cómo poner precios, separar gastos personales y evitar estafas digitales (especialmente fraudes de WhatsApp).

### Asistente Virtual
Chatbot inteligente que entiende el contexto de tu negocio y te ayuda a tomar mejores decisiones financieras.

---

## Próximas Mejoras
- Escaneo de códigos de barras para productos.
- Notificaciones push para recordatorios de pago de deudas.
- Venta en linea
---
<div align="center">
  <p>Desarrollado con ❤️ para empoderar a los comerciantes.</p>
</div>
