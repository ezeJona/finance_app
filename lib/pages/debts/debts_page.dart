import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/business.dart';
import '../../providers/debts.dart';
import '../../providers/transactions.dart';
import '../../providers/sales_profit.dart';
import '../../providers/transaction_items.dart';
import '../../backend-api/dtos.dart';
import '../../backend-api/sync_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header.dart';

class DebtsPage extends HookConsumerWidget {
  const DebtsPage({super.key});

  // paleta de colores de BalancePage
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
    final debtsAsync = ref.watch(debtsProvider);
    final summary = ref.watch(debtsSummaryProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Column(
            children: [
              const AppHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: _buildDebtsSummaryCard(business?.currencyCode ?? 'NIO', summary),
              ),
              Expanded(
                child: debtsAsync.maybeWhen(
                  data: (debts) => _buildDebtsContent(context, ref, debts, business),
                  loading: () => debtsAsync.hasValue
                      ? _buildDebtsContent(context, ref, debtsAsync.value!, business)
                      : const Center(child: CircularProgressIndicator()),
                  error: (e, st) => debtsAsync.hasValue
                      ? _buildDebtsContent(context, ref, debtsAsync.value!, business)
                      : _buildErrorPlaceholder(e, () => ref.read(debtsProvider.notifier).fetchDebts()),
                  orElse: () => const Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          ),
          _buildBottomActionButtons(context, ref, business),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder(Object error, VoidCallback onRetry) {
    final errorStr = error.toString().toLowerCase();
    final bool isNetworkError = errorStr.contains('socketexception') || 
                                errorStr.contains('host lookup') || 
                                errorStr.contains('clientexception') ||
                                errorStr.contains('connection');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 70,
              color: textGray.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              isNetworkError ? 'Sin conexión a Internet' : 'Algo salió mal',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkNavy),
            ),
            const SizedBox(height: 10),
            Text(
              isNetworkError
                ? 'No se pudieron cargar tus deudas. Por favor, conéctate a internet para sincronizar los datos.'
                : 'Hubo un problema al cargar la información. Inténtalo de nuevo.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: textGray, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('REINTENTAR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryYellow,
                foregroundColor: darkNavy,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtsContent(BuildContext context, WidgetRef ref, List<DebtRes> debts, BusinessRes? business) {
    return RefreshIndicator(
      onRefresh: () => ref.read(debtsProvider.notifier).fetchDebts(),
      color: primaryYellow,
      child: debts.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: _buildEmptyState(),
              ),
            )
          : _buildDebtsList(context, ref, debts, business),
    );
  }

  // 2. Tarjeta de Resumen de Deudas (Métricas)
  Widget _buildDebtsSummaryCard(String currency, ({double toCollect, double toPay, int debtors, int creditors}) summary) {
    final String symbol = currency == 'USD' ? '\$' : 'C\$';
    final formatter = NumberFormat.compactCurrency(symbol: symbol, decimalDigits: 0);

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Lado Izquierdo: Por cobrar
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: incomeGreen.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet, color: incomeGreen, size: 14),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Por cobrar',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: darkNavy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      formatter.format(summary.toCollect),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    Text(
                      '${summary.debtors} deudores',
                      style: const TextStyle(fontSize: 12, color: textGray),
                    ),
                  ],
                ),
              ),
              VerticalDivider(color: Colors.grey.withOpacity(0.3), thickness: 1),
              // Lado Derecho: Por pagar
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: expenseRed.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.payment, color: expenseRed, size: 14),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Por pagar',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: darkNavy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      formatter.format(summary.toPay),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    Text(
                      '${summary.creditors} acreedores',
                      style: const TextStyle(fontSize: 12, color: textGray),
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

  // 3. Cuerpo de la Página (Estado Vacío)
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Aún no tienes deudas creadas empieza añadiendo una AQUÍ",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textGray,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            const Icon(
              Icons.south,
              size: 80,
              color: darkNavy,
            ),
          ],
        ),
      ),
    );
  }

  // 4. Botones de Acción Inferiores
  Widget _buildBottomActionButtons(BuildContext context, WidgetRef ref, BusinessRes? business) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
          child: Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'POR COBRAR', 
                  incomeGreen, 
                  () => _showDebtModal(context, ref, business, 'to_collect')
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'POR PAGAR', 
                  expenseRed, 
                  () => _showDebtModal(context, ref, business, 'to_pay')
                ),
              ),
            ],
          ),
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

  Widget _buildDebtsList(BuildContext context, WidgetRef ref, List<DebtRes> debts, BusinessRes? business) {
    final String currency = business?.currencyCode ?? 'NIO';
    final String symbol = currency == 'USD' ? '\$' : 'C\$';
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
      itemCount: debts.length,
      itemBuilder: (context, index) {
        final debt = debts[index];
        final bool isToCollect = debt.type == 'to_collect';
        final Color statusColor = debt.status == 'paid' ? incomeGreen : (isToCollect ? incomeGreen : expenseRed);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.1),
              child: Icon(
                isToCollect ? Icons.arrow_downward : Icons.arrow_upward,
                color: statusColor,
              ),
            ),
            title: Text(
              debt.contactName,
              style: const TextStyle(fontWeight: FontWeight.bold, color: darkNavy),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (debt.description != null && debt.description!.isNotEmpty)
                  Text(debt.description!, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (debt.description != null && debt.description!.startsWith('Venta'))
                  Consumer(
                    builder: (context, ref, child) {
                      final profitAsync = ref.watch(saleProfitProvider(debt.id));
                      return profitAsync.maybeWhen(
                        data: (profit) => profit > 0 
                          ? Text('Ganancia real: +${formatter.format(profit)}', 
                              style: const TextStyle(color: incomeGreen, fontSize: 11, fontWeight: FontWeight.bold))
                          : const SizedBox.shrink(),
                        orElse: () => const SizedBox.shrink(),
                      );
                    },
                  ),
                if (debt.dueDate != null)
                  Text(
                    'Vence: ${DateFormat('dd/MM/yyyy').format(debt.dueDate!)}',
                    style: TextStyle(
                      color: debt.status == 'pending' && debt.dueDate!.isBefore(DateTime.now()) 
                        ? expenseRed 
                        : textGray,
                      fontSize: 11,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                Text(
                  debt.status == 'paid' ? 'Pagado' : 'Pendiente',
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatter.format(debt.remainingAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: debt.status == 'paid' ? textGray : Colors.black,
                        decoration: debt.status == 'paid' ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (debt.status == 'pending')
                      const Text('Toca para pagar', style: TextStyle(fontSize: 10, color: textGray)),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: textGray),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showDebtModal(context, ref, business, debt.type, debt: debt);
                    } else if (val == 'delete') {
                      _confirmDeleteDebt(context, ref, debt);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar deuda')),
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar deuda', style: TextStyle(color: expenseRed))),
                  ],
                ),
              ],
            ),
            onTap: () => _showDebtDetailsModal(context, ref, debt, currency),
          ),
        );
      },
    );
  }

  void _showDebtDetailsModal(BuildContext context, WidgetRef ref, DebtRes debt, String currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DebtDetailsModal(debt: debt, currency: currency),
    );
  }

  void _showDebtModal(BuildContext context, WidgetRef ref, BusinessRes? business, String type, {DebtRes? debt}) {
    if (business == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => _DebtForm(business: business, type: type, debt: debt),
    );
  }

  Future<void> _confirmDeleteDebt(BuildContext context, WidgetRef ref, DebtRes debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar deuda?'),
        content: const Text('Esta acción eliminará la deuda y todos sus abonos registrados. ¿Deseas continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR', style: TextStyle(color: textGray))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('ELIMINAR', style: TextStyle(color: expenseRed, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(debtsProvider.notifier).deleteDebt(debt.id);
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deuda eliminada correctamente')));
        }
      } catch (e) {
        if (context.mounted) {
          final errorStr = e.toString().toLowerCase();
          final isNetwork = errorStr.contains('socket') || errorStr.contains('host') || errorStr.contains('connection');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isNetwork 
                ? 'Error de red: No se pudo eliminar la deuda' 
                : 'No se pudo eliminar la deuda. Inténtalo de nuevo.'), 
              backgroundColor: expenseRed
            ),
          );
        }
      }
    }
  }
}

class _DebtForm extends ConsumerStatefulWidget {
  final BusinessRes business;
  final String type; // 'to_collect' or 'to_pay'
  final DebtRes? debt;

  const _DebtForm({required this.business, required this.type, this.debt});

  @override
  ConsumerState<_DebtForm> createState() => _DebtFormState();
}

class _DebtFormState extends ConsumerState<_DebtForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    _amountController = TextEditingController(text: d?.totalAmount.toString().replaceAll('.0', '') ?? '');
    _nameController = TextEditingController(text: d?.contactName ?? '');
    _descriptionController = TextEditingController(text: d?.description ?? '');
    _selectedDate = d?.dueDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
      final req = CreateDebtReq(
        businessId: widget.business.id,
        type: widget.type,
        contactName: _nameController.text,
        totalAmount: amount,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        dueDate: _selectedDate,
      );

      final online = await SyncService.isOnline();
      
      if (widget.debt == null) {
        await ref.read(debtsProvider.notifier).addDebt(req);
      } else {
        await ref.read(debtsProvider.notifier).updateDebt(widget.debt!.id, req);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(online 
              ? (widget.debt == null 
                  ? (widget.type == 'to_collect' ? 'Cuenta por cobrar registrada' : 'Cuenta por pagar registrada')
                  : 'Cambios guardados')
              : 'Guardado localmente. Se sincronizará al recuperar internet'),
            backgroundColor: online 
              ? (widget.type == 'to_collect' ? DebtsPage.incomeGreen : DebtsPage.expenseRed)
              : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        final isNetwork = errorStr.contains('socket') || errorStr.contains('host') || errorStr.contains('connection');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNetwork 
              ? 'Error de red: Verifica tu conexión a internet' 
              : 'Hubo un problema al guardar la deuda. Inténtalo de nuevo.'), 
            backgroundColor: DebtsPage.expenseRed
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = widget.type == 'to_collect' ? DebtsPage.incomeGreen : DebtsPage.expenseRed;
    final String title = widget.debt == null 
        ? (widget.type == 'to_collect' ? 'NUEVA CUENTA POR COBRAR' : 'NUEVA CUENTA POR PAGAR')
        : 'EDITAR DEUDA';
    
    final bool isAmountReadOnly = widget.debt != null && widget.debt!.remainingAmount < widget.debt!.totalAmount;

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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: themeColor),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: widget.debt == null,
                readOnly: isAmountReadOnly,
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold,
                  color: isAmountReadOnly ? Colors.grey : Colors.black
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Monto Total',
                  prefixText: widget.business.currencyCode == 'USD' ? '\$ ' : 'C\$ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              if (isAmountReadOnly)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'El monto inicial no se puede alterar si ya existen abonos.',
                    style: TextStyle(color: DebtsPage.expenseRed, fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del contacto',
                  hintText: '¿Quién debe pagar?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción (Opcional)',
                  hintText: 'Ej. Préstamo para mercadería',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    locale: const Locale('es'),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                borderRadius: BorderRadius.circular(15),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha límite (Opcional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    suffixIcon: _selectedDate != null 
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _selectedDate = null))
                      : null,
                  ),
                  child: Text(
                    _selectedDate == null 
                      ? 'Sin fecha límite' 
                      : DateFormat("d 'de' MMMM, y", 'es').format(_selectedDate!),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
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
                          widget.debt == null ? 'GUARDAR' : 'GUARDAR CAMBIOS',
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

class _DebtPaymentForm extends ConsumerStatefulWidget {
  final DebtRes debt;
  final String currency;
  final VoidCallback? onPaymentAdded;

  const _DebtPaymentForm({required this.debt, required this.currency, this.onPaymentAdded});

  @override
  ConsumerState<_DebtPaymentForm> createState() => _DebtPaymentFormState();
}

class _DebtPaymentFormState extends ConsumerState<_DebtPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.debt.remainingAmount.toString().replaceAll('.0', '')
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
      
      final req = CreateDebtPaymentReq(
        debtId: widget.debt.id,
        amount: amount,
      );

      final online = await SyncService.isOnline();
      
      await ref.read(debtsProvider.notifier).addPayment(req);

      if (widget.onPaymentAdded != null) widget.onPaymentAdded!();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(online ? 'Operación exitosa' : 'Guardado localmente. Se sincronizará luego'),
            backgroundColor: online ? DebtsPage.incomeGreen : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        final isNetwork = errorStr.contains('socket') || errorStr.contains('host') || errorStr.contains('connection');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNetwork 
              ? 'Error de red: No se pudo registrar el abono' 
              : 'Ocurrió un error al procesar el pago. Inténtalo de nuevo.'), 
            backgroundColor: DebtsPage.expenseRed
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveDebt = ref.watch(debtsProvider).maybeWhen(
          data: (list) => list.firstWhere((d) => d.id == widget.debt.id, orElse: () => widget.debt),
          orElse: () => widget.debt,
        );
    final String symbol = widget.currency == 'USD' ? '\$ ' : 'C\$ ';

    final double maxAllowed = liveDebt.remainingAmount;

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
            const Text(
              'REGISTRAR ABONO',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DebtsPage.darkNavy),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Deuda con: ${liveDebt.contactName}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: DebtsPage.textGray),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: symbol,
                helperText: 'Saldo disponible: $symbol${maxAllowed.toStringAsFixed(2)}',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Requerido';
                final amount = double.tryParse(val.replaceAll(',', '.'));
                if (amount == null || amount <= 0) return 'Monto inválido';
                if (amount > maxAllowed) return 'Excede el saldo total';
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: DebtsPage.incomeGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'REALIZAR PAGO',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

class _DebtDetailsModal extends ConsumerWidget {
  final DebtRes debt;
  final String currency;

  const _DebtDetailsModal({required this.debt, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveDebt = ref.watch(debtsProvider).maybeWhen(
          data: (list) => list.firstWhere((d) => d.id == debt.id, orElse: () => debt),
          orElse: () => debt,
        );
    final paymentsAsync = ref.watch(debtPaymentsProvider(liveDebt.id));
    final String symbol = currency == 'USD' ? '\$ ' : 'C\$ ';
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      liveDebt.contactName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: DebtsPage.darkNavy),
                    ),
                    Text(
                      liveDebt.type == 'to_collect' ? 'Cuenta por cobrar' : 'Cuenta por pagar',
                      style: const TextStyle(color: DebtsPage.textGray),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (liveDebt.status == 'paid' ? DebtsPage.incomeGreen : DebtsPage.expenseRed).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  liveDebt.status == 'paid' ? 'PAGADO' : 'PENDIENTE',
                  style: TextStyle(
                    color: liveDebt.status == 'paid' ? DebtsPage.incomeGreen : DebtsPage.expenseRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Monto Total', formatter.format(liveDebt.totalAmount)),
          _buildInfoRow('Saldo Restante', formatter.format(liveDebt.remainingAmount), isBold: true),
          if (liveDebt.dueDate != null)
            _buildInfoRow('Fecha de Vencimiento', DateFormat('dd/MM/yyyy').format(liveDebt.dueDate!)),
          
          // Inyectar productos si es una venta
          if (liveDebt.description != null && liveDebt.description!.startsWith('Venta')) ...[
            const Divider(height: 32),
            const Text(
              'PRODUCTOS DE LA VENTA',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DebtsPage.textGray, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, child) {
                final itemsAsync = ref.watch(transactionDetailsProvider(liveDebt.id));
                return itemsAsync.when(
                  data: (items) {
                    if (items.isEmpty) return const Text("No hay detalle de productos.", style: TextStyle(fontSize: 12, color: DebtsPage.textGray));
                    return Column(
                      children: items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item.productName, style: const TextStyle(fontSize: 14))),
                            Text(
                              "${item.item.quantity.toInt()} x ${formatter.format(item.item.unitPrice)}",
                              style: const TextStyle(color: DebtsPage.textGray, fontSize: 12),
                            ),
                          ],
                        ),
                      )).toList(),
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (e, st) => const Text(
                    "No se pudieron cargar los productos (sin conexión).", 
                    style: TextStyle(fontSize: 12, color: DebtsPage.textGray)
                  ),
                );
              },
            ),
          ],

          const Divider(height: 32),
          const Text(
            'HISTORIAL DE ABONOS',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DebtsPage.textGray),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
            child: paymentsAsync.when(
              data: (payments) {
                if (payments.isEmpty) return const Center(child: Text('No hay abonos registrados'));
                
                // Asegurar orden descendente por fecha (el más reciente primero)
                final sortedPayments = List<DebtPaymentRes>.from(payments)
                  ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: sortedPayments.length,
                  itemBuilder: (context, index) {
                    final payment = sortedPayments[index];
                    final bool isLatest = index == 0;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _showPaymentInfo(context, payment, formatter),
                      leading: Icon(
                        isLatest ? Icons.check_circle_outline : Icons.history, 
                        color: isLatest ? DebtsPage.incomeGreen : DebtsPage.textGray.withOpacity(0.5)
                      ),
                      title: Text(
                        formatter.format(payment.amount), 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isLatest ? Colors.black : DebtsPage.textGray
                        )
                      ),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(payment.paymentDate),
                        style: TextStyle(fontSize: 12, color: DebtsPage.textGray.withOpacity(0.7)),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const Center(
                child: Text(
                  'No se pudo cargar el historial. Verifica tu conexión.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: DebtsPage.textGray),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (liveDebt.status == 'pending')
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
                    builder: (context) => _DebtPaymentForm(
                      debt: liveDebt, 
                      currency: currency,
                      onPaymentAdded: () {
                        ref.invalidate(debtPaymentsProvider(liveDebt.id));
                        ref.invalidate(debtsProvider);
                        ref.invalidate(transactionsProvider);
                        ref.invalidate(historicTransactionsProvider);
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.add_card),
                label: const Text('REGISTRAR NUEVO ABONO', style: TextStyle(fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: DebtsPage.incomeGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showPaymentInfo(BuildContext context, DebtPaymentRes payment, NumberFormat formatter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Detalle del Abono', style: TextStyle(fontWeight: FontWeight.bold, color: DebtsPage.darkNavy)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Monto', formatter.format(payment.amount), isBold: true),
            const SizedBox(height: 8),
            _buildInfoRow('Método', payment.paymentMethod),
            const SizedBox(height: 8),
            _buildInfoRow('Fecha', DateFormat('dd/MM/yyyy HH:mm').format(payment.paymentDate)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CERRAR', style: TextStyle(color: DebtsPage.darkNavy, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: DebtsPage.textGray)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
