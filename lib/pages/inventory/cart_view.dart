import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/cart_item.dart';
import '../../providers/inventory.dart';
import '../../providers/transaction_items.dart';
import '../../providers/business.dart';
import '../../providers/transactions.dart';
import '../../providers/debts.dart';
import '../../services/inventory_service.dart';
import '../../backend-api/sync_service.dart';
import '../../providers/analytics.dart';

class CartView extends HookConsumerWidget {
  const CartView({super.key});

  static const Color primaryYellow = Color(0xFFF1C40F);
  static const Color darkNavy = Color(0xFF2C3E50);
  static const Color incomeGreen = Color(0xFF00A86B);
  static const Color expenseRed = Color(0xFFFF2D55);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final business = ref.watch(businessProvider);
    final total = cart.fold(0.0, (sum, item) => sum + item.subtotal);
    final currencyFormatter = NumberFormat.currency(symbol: business?.currencyCode == 'USD' ? '\$ ' : 'C\$ ', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Confirmar Venta', style: TextStyle(fontWeight: FontWeight.bold, color: darkNavy)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkNavy),
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Tu carrito está vacío', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: primaryYellow.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.inventory_2, color: primaryYellow),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text('${currencyFormatter.format(item.product.salePrice)} c/u', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 20, color: expenseRed),
                                    onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity - 1),
                                  ),
                                  Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  IconButton(
                                    icon: Icon(
                                      Icons.add_circle_outline, 
                                      size: 20, 
                                      color: item.quantity < item.product.stock ? incomeGreen : Colors.grey
                                    ),
                                    onPressed: item.quantity < item.product.stock 
                                      ? () => ref.read(cartProvider.notifier).updateQuantity(
                                          item.product.id, 
                                          item.quantity + 1,
                                          onStockError: (msg) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(msg), backgroundColor: expenseRed)
                                            );
                                          }
                                        )
                                      : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total a pagar', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          Text(currencyFormatter.format(total), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkNavy)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showSaleProcessModal(context, ref, total, isDebt: true),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: darkNavy),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                              child: const Text('FIADO / CRÉDITO', style: TextStyle(color: darkNavy, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showSaleProcessModal(context, ref, total, isDebt: false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: incomeGreen,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                elevation: 0,
                              ),
                              child: const Text('COBRAR AHORA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showSaleProcessModal(BuildContext context, WidgetRef ref, double total, {required bool isDebt}) {
    final business = ref.read(businessProvider);
    final currencySymbol = business?.currencyCode == 'USD' ? '\$ ' : 'C\$ ';
    final controller = TextEditingController();
    final nameController = TextEditingController();
    String paymentMethod = 'Efectivo';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isDebt ? 'Detalle del Crédito' : 'Procesar Pago',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkNavy),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: isDebt ? 'Nombre del Cliente (Obligatorio)' : 'Nombre del Cliente (Opcional)',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 16),
              if (!isDebt) ...[
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: InputDecoration(
                    labelText: 'Método de Pago',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  items: ['Efectivo', 'Tarjeta', 'Transferencia']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) => setState(() => paymentMethod = val!),
                ),
                const SizedBox(height: 16),
                if (paymentMethod == 'Efectivo')
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Monto Recibido',
                      prefixText: currencySymbol,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (isDebt && nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Por favor, ingresa el nombre del cliente para el crédito'), backgroundColor: expenseRed)
                    );
                    return;
                  }

                  final contactName = nameController.text.isEmpty ? 'Cliente General' : nameController.text;
                  final montoRecibido = double.tryParse(controller.text) ?? total;
                  final soldItems = ref.read(cartProvider);

                  try {
                    await InventoryService.processInventorySale(
                      businessId: business!.id,
                      items: soldItems,
                      paymentMethod: paymentMethod,
                      isDebt: isDebt,
                      debtContactName: contactName,
                    );

                    ref.read(cartProvider.notifier).clear();
                    ref.invalidate(productsProvider);
                    ref.invalidate(transactionsProvider);
                    ref.invalidate(historicTransactionsProvider);
                    ref.invalidate(debtsProvider);
                    ref.invalidate(transactionItemsProvider);
                    ref.invalidate(executiveFinancialsProvider);

                    if (context.mounted) {
                      Navigator.pop(context); // Close modal
                      Navigator.pop(context); // Back to inventory
                      _showSuccessDialog(
                        context, 
                        total, 
                        isDebt ? null : montoRecibido, 
                        currencySymbol,
                        items: soldItems,
                        contactName: contactName,
                        businessName: business.name,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: expenseRed));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDebt ? darkNavy : incomeGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('CONFIRMAR VENTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(
    BuildContext context, 
    double total, 
    double? recibido, 
    String symbol, {
    required List<CartItem> items,
    required String contactName,
    String? businessName,
  }) {
    final double vuelto = (recibido ?? 0) - total;
    final currencyFormatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: incomeGreen, size: 80),
            const SizedBox(height: 16),
            const Text('¡Venta Exitosa!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Se ha registrado la transacción correctamente.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            if (recibido != null && vuelto > 0) ...[
              const Divider(height: 32),
              const Text('CAMBIO A ENTREGAR:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              Text('$symbol${vuelto.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: incomeGreen)),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      String detail = items.map((i) => "- ${i.product.name} x${i.quantity} (${currencyFormatter.format(i.subtotal)})").join("\n");
                      String message = "🧾 *${businessName ?? 'Mi Negocio'}* \n"
                          "¡Gracias por tu compra! \n\n"
                          "*Cliente:* $contactName\n"
                          "*Detalle:* \n"
                          "$detail\n\n"
                          "*Total:* ${currencyFormatter.format(total)}";
                      Share.share(message);
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Enviar Factura', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: darkNavy,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('ENTENDIDO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
