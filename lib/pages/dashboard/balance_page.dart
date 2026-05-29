import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/business.dart';
import '../../providers/transactions.dart';
import '../../providers/transaction_filter.dart';
import '../../backend-api/api_service.dart';
import '../../backend-api/dtos.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header.dart';

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
    final business = ref.watch(businessProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final historicAsync = ref.watch(historicTransactionsProvider);
    final filter = ref.watch(transactionFilterProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: const AppDrawer(),
      body: SafeArea(
        top: false, // Permitir que el header amarillo suba hasta la barra de estado
        child: Stack(
          children: [
            Column(
              children: [
                const AppHeader(),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                        child: historicAsync.when(
                          data: (transactions) => _buildMetricsCard(transactions, business?.currencyCode ?? 'NIO'),
                          loading: () => const Center(child: LinearProgressIndicator()),
                          error: (err, stack) => Text('Error en saldos: $err', style: const TextStyle(color: expenseRed)),
                        ),
                      ),
                      Expanded(
                        child: transactionsAsync.when(
                          data: (transactions) => ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            children: [
                              _buildFilterBar(context, ref, filter),
                              const SizedBox(height: 16),
                              _buildTransactionList(context, ref, transactions, business?.currencyCode ?? 'NIO'),
                              const SizedBox(height: 100), // Espacio para no tapar el contenido con los botones inferiores
                            ],
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Center(child: Text('Error al cargar transacciones: $err')),
                        ),
                      ),
                    ],
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

  // 4. NUEVA BARRA DE FILTROS
  Widget _buildFilterBar(BuildContext context, WidgetRef ref, TransactionFilterState filter) {
    String timeLabel = "Mes actual";
    if (filter.timeRange == 'current_month') {
      timeLabel = DateFormat("MMM yyyy", 'es').format(filter.selectedMonthYear);
    } else if (filter.timeRange == 'today') {
      timeLabel = "Hoy";
    } else if (filter.timeRange == 'yesterday') {
      timeLabel = "Ayer";
    } else if (filter.timeRange == 'last_5') {
      timeLabel = "Últimos 5";
    } else if (filter.timeRange == 'last_7') {
      timeLabel = "Últimos 7 días";
    } else if (filter.timeRange == 'last_30') {
      timeLabel = "Últimos 30 días";
    } else if (filter.timeRange == 'custom_range') {
      timeLabel = "Personalizado";
    }

    String flowLabel = "Todos los movimientos";
    if (filter.flowType == 'income') flowLabel = "Ingresos";
    if (filter.flowType == 'expense') flowLabel = "Pagos";

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildActionChip(
            context,
            timeLabel,
            Icons.calendar_month,
            onTap: () => _showTimeRangePicker(context, ref, filter),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: _buildActionChip(
            context,
            flowLabel,
            Icons.filter_list,
            onTap: () => _showFlowTypePicker(context, ref, filter),
          ),
        ),
      ],
    );
  }

  Widget _buildActionChip(BuildContext context, String label, IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: darkNavy),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkNavy),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: textGray),
          ],
        ),
      ),
    );
  }

  void _showTimeRangePicker(BuildContext context, WidgetRef ref, TransactionFilterState filter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => _TimeRangeModal(currentFilter: filter),
    );
  }

  void _showFlowTypePicker(BuildContext context, WidgetRef ref, TransactionFilterState filter) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text("Filtrar por flujo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.all_inclusive, color: darkNavy),
            title: const Text("Todos los movimientos"),
            selected: filter.flowType == 'all',
            onTap: () {
              ref.read(transactionFilterProvider.notifier).setFlowType('all');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.arrow_upward, color: incomeGreen),
            title: const Text("Ingresos"),
            selected: filter.flowType == 'income',
            onTap: () {
              ref.read(transactionFilterProvider.notifier).setFlowType('income');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.arrow_downward, color: expenseRed),
            title: const Text("Egresos / Pagos"),
            selected: filter.flowType == 'expense',
            onTap: () {
              ref.read(transactionFilterProvider.notifier).setFlowType('expense');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 5. LISTADO DE MOVIMIENTOS (Historial)
  Widget _buildTransactionList(BuildContext context, WidgetRef ref, List<TransactionRes> transactions, String currency) {
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
        ...transactions.map((tx) => _buildTransactionItem(context, ref, tx, currency)),
      ],
    );
  }

  Widget _buildTransactionItem(BuildContext context, WidgetRef ref, TransactionRes tx, String currency) {
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
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: textGray, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showTransactionModal(context, ref, null, tx.type, transaction: tx);
                    break;
                  case 'delete':
                    _confirmDeleteTransaction(context, ref, tx);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Editar movimiento'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: expenseRed, size: 20),
                      SizedBox(width: 8),
                      const Text('Eliminar', style: TextStyle(color: expenseRed)),
                    ],
                  ),
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

  void _showTransactionModal(BuildContext context, WidgetRef ref, BusinessRes? business, String type, {TransactionRes? transaction}) {
    final targetBusiness = business ?? ref.read(businessProvider);
    
    if (targetBusiness == null) {
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
      builder: (context) => _TransactionForm(business: targetBusiness, ref: ref, type: type, transaction: transaction),
    );
  }

  Future<void> _confirmDeleteTransaction(BuildContext context, WidgetRef ref, TransactionRes tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar movimiento?'),
        content: const Text('Esta acción modificará tu saldo actual y no se puede deshacer. ¿Estás seguro?'),
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
        await ApiService.deleteTransaction(tx.id);
        ref.invalidate(transactionsProvider);
        ref.invalidate(historicTransactionsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Movimiento eliminado'), backgroundColor: incomeGreen),
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

class _TimeRangeModal extends ConsumerWidget {
  final TransactionFilterState currentFilter;
  const _TimeRangeModal({required this.currentFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final months = [
      "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
      "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
    ];

    Widget buildMonthChip(DateTime date) {
      final isSelected = currentFilter.timeRange == 'current_month' && 
                        currentFilter.selectedMonthYear.year == date.year && 
                        currentFilter.selectedMonthYear.month == date.month;
      
      return GestureDetector(
        onTap: () {
          ref.read(transactionFilterProvider.notifier).setSelectedMonth(date);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isSelected ? BalancePage.darkNavy : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? BalancePage.darkNavy : Colors.grey.shade300),
          ),
          child: Text(
            "${months[date.month-1].substring(0, 3)} ${date.year}",
            style: TextStyle(
              color: isSelected ? Colors.white : BalancePage.darkNavy,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    // Lógica de generación: Mes actual primero, luego anteriores en orden inverso.
    final List<DateTime> currentYearMonths = List.generate(now.month, (i) => DateTime(now.year, now.month - i));
    final List<DateTime> lastYearMonths = List.generate(12, (i) => DateTime(now.year - 1, 12 - i));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Selecciona un periodo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Fila de meses Año Actual
              Text("${now.year}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BalancePage.textGray)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: currentYearMonths.map(buildMonthChip).toList(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Fila de meses Año Anterior
              Text("${now.year - 1}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BalancePage.textGray)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: lastYearMonths.map(buildMonthChip).toList(),
                ),
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              
              _rangeOption(ref, context, "Últimos 5 movimientos", Icons.notes, 'last_5'),
              _rangeOption(ref, context, "Hoy", Icons.calendar_today, 'today'),
              _rangeOption(ref, context, "Ayer", Icons.history, 'yesterday'),
              _rangeOption(ref, context, "Últimos 7 días", Icons.calendar_month, 'last_7'),
              _rangeOption(ref, context, "Últimos 30 días", Icons.date_range, 'last_30'),
              
              ListTile(
                leading: const Icon(Icons.date_range_outlined, color: BalancePage.darkNavy),
                title: const Text("Fecha desde - hasta"),
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: BalancePage.darkNavy,
                            onPrimary: Colors.white,
                            onSurface: BalancePage.darkNavy,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (range != null) {
                    ref.read(transactionFilterProvider.notifier).setCustomRange(range);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCELAR", style: TextStyle(color: BalancePage.textGray, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rangeOption(WidgetRef ref, BuildContext context, String label, IconData icon, String range) {
    final isSelected = currentFilter.timeRange == range;
    return ListTile(
      leading: Icon(icon, color: isSelected ? BalancePage.primaryYellow : BalancePage.darkNavy),
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onTap: () {
        ref.read(transactionFilterProvider.notifier).setTimeRange(range);
        Navigator.pop(context);
      },
    );
  }
}

class _TransactionForm extends StatefulWidget {
  final BusinessRes business;
  final WidgetRef ref;
  final String type; // 'income' or 'expense'
  final TransactionRes? transaction;

  const _TransactionForm({required this.business, required this.ref, required this.type, this.transaction});

  @override
  State<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<_TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late String _paymentMethod;
  late String _category;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    // Precargamos los datos si estamos editando
    _amountController = TextEditingController(
      text: tx != null ? tx.amount.toString().replaceAll('.0', '') : ''
    );
    _descriptionController = TextEditingController(text: tx?.description ?? '');
    _selectedDate = tx?.transactionDate ?? DateTime.now();
    _paymentMethod = tx?.paymentMethod ?? 'Efectivo';
    _category = tx?.category ?? (widget.type == 'income' ? 'Salario' : 'General');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
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
        transactionDate: _selectedDate,
      );

      if (widget.transaction == null) {
        await ApiService.createTransaction(req);
      } else {
        await ApiService.updateTransaction(widget.transaction!.id, req);
      }

      widget.ref.invalidate(transactionsProvider);
      widget.ref.invalidate(historicTransactionsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.transaction == null 
              ? (widget.type == 'income' ? 'Ingreso registrado' : 'Pago registrado')
              : 'Cambios guardados correctamente'),
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
    final String title = widget.transaction == null 
      ? (widget.type == 'income' ? 'NUEVO INGRESO' : 'NUEVO PAGO')
      : 'EDITAR MOVIMIENTO';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(15),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de la transacción',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    DateFormat("d 'de' MMMM, y", 'es').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
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
                      : Text(
                          widget.transaction == null ? 'GUARDAR' : 'GUARDAR CAMBIOS',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
