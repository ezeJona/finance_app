import 'package:flutter/material.dart';

class BalancePage extends StatelessWidget {
  const BalancePage({super.key});

  // Paleta de Colores basada en la referencia
  static const Color primaryYellow = Color(0xFFF1C40F);
  static const Color backgroundColor = Color(0xFFF5F6F8);
  static const Color darkNavy = Color(0xFF2C3E50);
  static const Color incomeGreen = Color(0xFF00A86B);
  static const Color expenseRed = Color(0xFFFF2D55);
  static const Color textGray = Color(0xFF7F8C8D);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: SafeArea(
        top: false, // Permitir que el header amarillo suba hasta la barra de estado
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      const SizedBox(height: 16),
                      _buildDatePicker(),
                      const SizedBox(height: 12),
                      _buildMetricsCard(),
                      const SizedBox(height: 16),
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildTransactionList(),
                      const SizedBox(height: 100), // Espacio para no tapar el contenido con los botones inferiores
                    ],
                  ),
                ),
              ],
            ),
            _buildBottomActionButtons(),
          ],
        ),
      ),
    );
  }

  // 1. ENCABEZADO AMARILLO (Header Custom)
  Widget _buildHeader(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: statusBarHeight + 16, left: 16, right: 16, bottom: 20),
      decoration: const BoxDecoration(
        color: primaryYellow,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Fila superior: Perfil, Nombre y Ayuda
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.3),
                child: const Icon(Icons.attach_money, color: Colors.white),
              ),
              Column(
                children: [
                  const Text(
                    'Ivon Lorena León R...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Cuenta personal',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                  ),
                ],
              ),
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.3),
                child: const Text('?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Selector de Rango Temporal (Segmented Tabs)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                _buildSegmentTab('Diario', isSelected: false),
                _buildSegmentTab('Semanal', isSelected: true),
                _buildSegmentTab('Mensual', isSelected: false),
                _buildSegmentTab('Anual', isSelected: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(String title, {required bool isSelected}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? darkNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : darkNavy,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // 2. SELECTOR DE FECHAS (Date/Week Picker)
  Widget _buildDatePicker() {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: darkNavy.withOpacity(0.7)),
                const SizedBox(width: 12),
                const Text(
                  '26 jul | 01 ago',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.chevron_left, size: 28),
                const SizedBox(width: 4),
                Text('19 | 25', style: TextStyle(color: textGray.withOpacity(0.6), fontSize: 13)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: darkNavy, borderRadius: BorderRadius.circular(6)),
                  child: const Text('26 | 01', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text('02 | 08', style: TextStyle(color: textGray.withOpacity(0.6), fontSize: 13)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 28),
              ],
            )
          ],
        ),
      ),
    );
  }

  // 3. TARJETA DE MÉTRICAS (Resumen Financiero)
  Widget _buildMetricsCard() {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Lado Izquierdo: Saldo Neto
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('SALDO', style: TextStyle(color: textGray, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    const Text(
                      '\$ 608.000',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
              VerticalDivider(color: Colors.grey.withOpacity(0.3), thickness: 1),
              // Lado Derecho: Ingresos y Pagos
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMetricRow(Icons.money, 'Ingresos totales', '\$ 908.000', incomeGreen),
                      const SizedBox(height: 12),
                      _buildMetricRow(Icons.payment, 'Pagos totales', '\$ 300.000', expenseRed),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(IconData icon, String label, String amount, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text(
                amount,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        )
      ],
    );
  }

  // 4. BARRA DE BÚSQUEDA Y ACCIONES CENTRALES
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Buscar concepto ...',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildCircleActionButton(Icons.swap_vert), // Representación de !¡!
        const SizedBox(width: 10),
        _buildCircleActionButton(Icons.arrow_downward), // Descargar
      ],
    );
  }

  Widget _buildCircleActionButton(IconData icon) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: darkNavy, width: 1.5),
      ),
      child: Icon(icon, color: darkNavy, size: 22),
    );
  }

  // 5. LISTADO DE MOVIMIENTOS (Historial)
  Widget _buildTransactionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de la sección del listado
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('28 jul 2021', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black.withOpacity(0.8))),
              Text('\$ 608.000', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black.withOpacity(0.8))),
            ],
          ),
        ),
        // Items de transacciones
        _buildTransactionItem('Arriendo', 'Efectivo', '\$ 300.000', expenseRed, Icons.payment),
        const SizedBox(height: 8),
        _buildTransactionItem('Salario', 'Efectivo', '\$ 908.000', incomeGreen, Icons.money),
      ],
    );
  }

  Widget _buildTransactionItem(String title, String method, String amount, Color amountColor, IconData icon) {
    return Card(
      color: Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: amountColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(method, style: TextStyle(color: textGray, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: amountColor),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.more_vert, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // 6. BOTONES FLOTANTES INFERIORES
  Widget _buildBottomActionButtons() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
        child: Row(
          children: [
            Expanded(
              child: _buildActionButton('NUEVO INGRESO', incomeGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton('NUEVO PAGO', expenseRed),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color color) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: () {},
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }


}