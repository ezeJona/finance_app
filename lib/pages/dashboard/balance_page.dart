import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_user.dart';
import '../../providers/business.dart';
import '../../providers/auth_user.dart';
import '../../providers/businesses.dart';
import '../../providers/transactions.dart';
import '../../backend-api/api_service.dart';
import '../../backend-api/dtos.dart';

class BalancePage extends HookConsumerWidget {
  const BalancePage({super.key});

  // Paleta de Colores
  static const Color primaryYellow = Color(0xFFF1C40F);
  static const Color backgroundColor = Color(0xFFF5F6F8);
  static const Color darkNavy = Color(0xFF2C3E50);
  static const Color incomeGreen = Color(0xFF00A86B);
  static const Color emeraldGreen = Color(0xFF2ECC71);
  static const Color expenseRed = Color(0xFFFF2D55);
  static const Color textGray = Color(0xFF7F8C8D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(appUserProvider);
    final authUser = ref.watch(authUserProvider);
    final business = ref.watch(businessProvider);
    final businessesAsync = ref.watch(businessesProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: primaryYellow),
              currentAccountPicture: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 40,
                    child: Text(
                      appUser?.firstName.isNotEmpty == true
                          ? appUser!.firstName.substring(0, 1).toUpperCase()
                          : "U",
                      style: const TextStyle(
                          color: primaryYellow,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Navegar a la página de edición de perfil
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: darkNavy,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_outlined,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
              accountName: Text(
                '${appUser?.firstName ?? "Usuario"} ${appUser?.firstLastName ?? ""}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(authUser?.email ?? "sin-email@hospired.com"),
                  const SizedBox(height: 2),
                ],
              ),
            ),
            Expanded(
              child: businessesAsync.when(
                data: (businesses) => ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                      child: Text(
                        "MIS NEGOCIOS",
                        style: TextStyle(
                            color: textGray,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2),
                      ),
                    ),
                    ...businesses.map((b) => ListTile(
                          leading: const Icon(Icons.storefront, color: darkNavy),
                          title: Text(b.name,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${b.businessType} | ${b.currencyCode}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (b.isDefault)
                                const Icon(Icons.check_circle,
                                    color: incomeGreen, size: 20),
                              const SizedBox(width: 4),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: textGray),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'default':
                                      // TODO: Poner como predeterminado
                                      break;
                                    case 'edit':
                                      _showAddBusinessModal(context, ref, authUser!.id, business: b);
                                      break;
                                    case 'delete':
                                      _confirmDeleteBusiness(context, ref, b);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'default',
                                    enabled: !b.isDefault,
                                    child: const Row(
                                      children: [
                                        Icon(Icons.star_border, size: 20),
                                        SizedBox(width: 8),
                                        Text('Poner como predeterminado'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Editar negocio'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline,
                                            color: expenseRed.withOpacity(0.8),
                                            size: 20),
                                        const SizedBox(width: 8),
                                        const Text('Borrar negocio',
                                            style:
                                                TextStyle(color: expenseRed)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            ref.read(businessProvider.notifier).set(b);
                            Navigator.pop(context);
                          },
                        )),
                    const Divider(),
                    ListTile(
                      leading:
                          const Icon(Icons.add_circle_outline, color: emeraldGreen),
                      title: const Text('Añadir nuevo negocio',
                          style: TextStyle(
                              color: emeraldGreen, fontWeight: FontWeight.bold)),
                      onTap: () {
                        // TODO: Implementar navegación al formulario de creación
                        if (authUser != null) {
                          _showAddBusinessModal(context, ref, authUser.id);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false, // Permitir que el header amarillo suba hasta la barra de estado
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context, appUser, business),
                Expanded(
                  child: transactionsAsync.when(
                    data: (transactions) => ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      children: [
                        const SizedBox(height: 16),
                        _buildDatePicker(),
                        const SizedBox(height: 12),
                        _buildMetricsCard(transactions, business?.currencyCode ?? 'NIO'),
                        const SizedBox(height: 16),
                        _buildSearchBar(),
                        const SizedBox(height: 16),
                        _buildTransactionList(transactions, business?.currencyCode ?? 'NIO'),
                        const SizedBox(height: 100), // Espacio para no tapar el contenido con los botones inferiores
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error al cargar transacciones: $err')),
                  ),
                ),
              ],
            ),
            _buildBottomActionButtons(context, ref, business),
          ],
        ),
      ),
    );
  }

  // Header Custom
  Widget _buildHeader(BuildContext context, dynamic appUser, dynamic business) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    String displayName = "Cargando...";
    if (appUser != null) {
      displayName = "${appUser.firstName} ${appUser.firstLastName}";
      if (displayName.length > 20) {
        displayName = "${displayName.substring(0, 17)}...";
      }
    }

    String displayAccount = business?.businessType ?? "Personal";

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
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Cuenta $displayAccount',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
                  'Hoy',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.chevron_left, size: 28),
                const SizedBox(width: 4),
                Text('Anterior', style: TextStyle(color: textGray.withOpacity(0.6), fontSize: 13)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: darkNavy, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Actual', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text('Siguiente', style: TextStyle(color: textGray.withOpacity(0.6), fontSize: 13)),
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
  Widget _buildMetricsCard(List<TransactionRes> transactions, String currency) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var tx in transactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }

    final double balance = totalIncome - totalExpense;
    final currencyFormatter = NumberFormat.currency(symbol: currency == 'USD' ? '\$ ' : 'C\$ ', decimalDigits: 2);

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
                    Text(
                      currencyFormatter.format(balance),
                      style: TextStyle(
                        fontSize: balance < 1000000 ? 20 : 16, 
                        fontWeight: FontWeight.bold, 
                        color: balance >= 0 ? Colors.black : expenseRed
                      ),
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
                      _buildMetricRow(Icons.arrow_upward, 'Ingresos', currencyFormatter.format(totalIncome), incomeGreen),
                      const SizedBox(height: 12),
                      _buildMetricRow(Icons.arrow_downward, 'Pagos', currencyFormatter.format(totalExpense), expenseRed),
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
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              Text(
                amount,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
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
        _buildCircleActionButton(Icons.file_download_outlined), // Descargar
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
  Widget _buildTransactionList(List<TransactionRes> transactions, String currency) {
    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.black12),
              SizedBox(height: 16),
              Text('No hay movimientos registrados', style: TextStyle(color: textGray)),
            ],
          ),
        ),
      );
    }

    // Agrupar por fecha (simplificado para el ejemplo, asumiendo orden descendente de Supabase)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Text(
            'Últimos movimientos', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black.withOpacity(0.8))
          ),
        ),
        ...transactions.map((tx) => _buildTransactionItem(tx, currency)),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionRes tx, String currency) {
    final bool isIncome = tx.type == 'income';
    final Color color = isIncome ? incomeGreen : expenseRed;
    final String prefix = isIncome ? '+' : '-';
    final currencyFormatter = NumberFormat.currency(symbol: currency == 'USD' ? '\$ ' : 'C\$ ', decimalDigits: 2);

    return Card(
      color: Colors.white,
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncome ? Icons.arrow_upward : Icons.arrow_downward, 
                color: color, 
                size: 20
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.description ?? tx.category, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tx.paymentMethod} • ${DateFormat('dd MMM').format(tx.transactionDate)}', 
                    style: TextStyle(color: textGray, fontSize: 12)
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$prefix ${currencyFormatter.format(tx.amount)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 6. BOTONES FLOTANTES INFERIORES
  Widget _buildBottomActionButtons(BuildContext context, WidgetRef ref, BusinessRes? business) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
        child: Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'NUEVO INGRESO', 
                incomeGreen, 
                () => _showTransactionModal(context, ref, business, 'income')
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'NUEVO PAGO', 
                expenseRed, 
                () => _showTransactionModal(context, ref, business, 'expense')
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          elevation: 4,
          shadowColor: color.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  void _showTransactionModal(BuildContext context, WidgetRef ref, BusinessRes? business, String type) {
    if (business == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona o crea un negocio primero'))
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => _TransactionForm(business: business, ref: ref, type: type),
    );
  }

  void _showAddBusinessModal(BuildContext context, WidgetRef ref, String userId, {BusinessRes? business}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => _AddBusinessForm(userId: userId, ref: ref, business: business),
    );
  }

  Future<void> _confirmDeleteBusiness(BuildContext context, WidgetRef ref, BusinessRes business) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar ${business.name}?'),
        content: const Text('Esta acción no se puede deshacer. ¿Estás seguro de que deseas eliminar este negocio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: textGray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ELIMINAR', style: TextStyle(color: expenseRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteBusiness(business.id);
        ref.invalidate(businessesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Negocio eliminado correctamente'), backgroundColor: incomeGreen),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: expenseRed),
          );
        }
      }
    }
  }
}

class _TransactionForm extends StatefulWidget {
  final BusinessRes business;
  final WidgetRef ref;
  final String type; // 'income' or 'expense'

  const _TransactionForm({required this.business, required this.ref, required this.type});

  @override
  State<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<_TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _paymentMethod = 'Efectivo';
  late String _category;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _category = widget.type == 'income' ? 'Salario' : 'General';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
      final req = CreateTransactionReq(
        businessId: widget.business.id,
        type: widget.type,
        amount: amount,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        paymentMethod: _paymentMethod,
        category: _category,
      );

      await ApiService.createTransaction(req);
      widget.ref.invalidate(transactionsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.type == 'income' ? 'Ingreso registrado' : 'Pago registrado'),
            backgroundColor: widget.type == 'income' ? BalancePage.incomeGreen : BalancePage.expenseRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: BalancePage.expenseRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = widget.type == 'income' ? BalancePage.incomeGreen : BalancePage.expenseRed;
    final String title = widget.type == 'income' ? 'NUEVO INGRESO' : 'NUEVO PAGO';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: widget.business.currencyCode == 'USD' ? '\$ ' : 'C\$ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Concepto / Descripción',
                hintText: 'Ej. Pago de alquiler',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    decoration: InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    items: (widget.type == 'income' 
                      ? ['Salario', 'Venta', 'Inversión', 'Otros'] 
                      : ['Comida', 'Arriendo', 'Servicios', 'Transporte', 'General'])
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                    onChanged: (val) => setState(() => _category = val!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: InputDecoration(
                      labelText: 'Método',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    items: ['Efectivo', 'Tarjeta', 'Transferencia']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setState(() => _paymentMethod = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AddBusinessForm extends StatefulWidget {
  final String userId;
  final WidgetRef ref;
  final BusinessRes? business;

  const _AddBusinessForm({required this.userId, required this.ref, this.business});

  @override
  State<_AddBusinessForm> createState() => _AddBusinessFormState();
}

class _AddBusinessFormState extends State<_AddBusinessForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _businessType;
  late String _currencyCode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.business?.name);
    _businessType = widget.business?.businessType ?? 'Personal';
    _currencyCode = widget.business?.currencyCode ?? 'NIO';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final req = CreateBusinessReq(
        userId: widget.userId,
        name: _nameController.text,
        businessType: _businessType,
        currencyCode: _currencyCode,
      );

      if (widget.business == null) {
        await ApiService.createBusiness(req);
      } else {
        await ApiService.updateBusiness(widget.business!.id, req);
      }

      widget.ref.invalidate(businessesProvider);

      if (mounted) {
        Navigator.pop(context); // Cerrar Modal
        Navigator.pop(context); // Cerrar Drawer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.business == null ? 'Negocio creado exitosamente' : 'Cambios guardados exitosamente'),
            backgroundColor: BalancePage.incomeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar: $e'),
            backgroundColor: BalancePage.expenseRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.business == null ? 'Añadir nuevo negocio' : 'Editar negocio',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: BalancePage.darkNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre del Negocio',
                hintText: 'Ej. Mi Empresa S.A.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Por favor ingrese un nombre' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _businessType,
              decoration: InputDecoration(
                labelText: 'Tipo de Negocio',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              items: ['Personal', 'Comercial', 'Servicios', 'Otro']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => _businessType = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _currencyCode,
              decoration: InputDecoration(
                labelText: 'Moneda Principal',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              items: [
                {'code': 'NIO', 'name': 'Córdoba (NIO)'},
                {'code': 'USD', 'name': 'Dólar (USD)'},
              ].map((c) => DropdownMenuItem(value: c['code']!, child: Text(c['name']!)))
                  .toList(),
              onChanged: (val) => setState(() => _currencyCode = val!),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: BalancePage.emeraldGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.business == null ? 'GUARDAR' : 'GUARDAR CAMBIOS',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
