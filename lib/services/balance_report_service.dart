import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../backend-api/dtos.dart';
import '../providers/transaction_items.dart';

class BalanceReportService {
  static Future<void> exportToExcel({
    required List<TransactionRes> transactions,
    required List<DebtRes> debts,
    required List<TransactionItemModel> allItems,
    required String businessName,
    required String currency,
    required String dateRangeLabel,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Reporte de Balance'];
    excel.delete('Sheet1');

    // Estilo de Cabecera
    final CellStyle headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#F1C40F'),
      fontColorHex: ExcelColor.fromHexString('#2C3E50'),
    );

    // Encabezados
    final headers = [
      'Fecha',
      'Hora',
      'Tipo de Movimiento',
      'Descripción / Cliente',
      'Producto Vendido',
      'Cantidad',
      'Precio Unit.',
      'Monto / Subtotal',
      'Total Transacción'
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
    }

    final df = DateFormat('dd/MM/yyyy');
    final tf = DateFormat('HH:mm');

    // 1. Procesar Transacciones
    for (var tx in transactions) {
      final txItems = allItems.where((item) => item.item.transactionId == tx.id).toList();
      
      String typeLabel;
      if (tx.debtPaymentId != null) {
        typeLabel = 'Abono';
      } else if (txItems.isNotEmpty) {
        typeLabel = 'Venta (Contado)';
      } else {
        typeLabel = tx.type == 'income' ? 'Ingreso Directo' : 'Gasto';
      }

      if (txItems.isEmpty) {
        _appendRow(sheet, df, tf, tx.transactionDate, typeLabel, tx.contactName ?? tx.description ?? tx.category, 'N/A', 0, 0, tx.amount, tx.amount);
      } else {
        for (var i = 0; i < txItems.length; i++) {
          final item = txItems[i];
          // Solo colocamos el "Total Transacción" en la primera fila del desglose
          final double? totalVal = (i == 0) ? tx.amount : null;
          _appendRow(sheet, df, tf, tx.transactionDate, typeLabel, tx.contactName ?? 'Cliente General', item.productName, item.item.quantity, item.item.unitPrice, item.item.subtotal, totalVal);
        }
      }
    }

    // 2. Procesar Deudas (Ventas al Crédito o Compras al Crédito)
    for (var debt in debts) {
      final debtItems = allItems.where((item) => item.item.debtId == debt.id).toList();
      
      String typeLabel = debt.type == 'to_collect' ? 'Venta (Crédito)' : 'Compra (Crédito)';

      if (debtItems.isEmpty) {
        _appendRow(sheet, df, tf, debt.createdAt, typeLabel, debt.contactName, 'N/A', 0, 0, debt.totalAmount, debt.totalAmount);
      } else {
        for (var i = 0; i < debtItems.length; i++) {
          final item = debtItems[i];
          final double? totalVal = (i == 0) ? debt.totalAmount : null;
          _appendRow(sheet, df, tf, debt.createdAt, typeLabel, debt.contactName, item.productName, item.item.quantity, item.item.unitPrice, item.item.subtotal, totalVal);
        }
      }
    }

    // Guardar y compartir
    final bytes = excel.save();
    if (bytes == null) return;

    final directory = await getTemporaryDirectory();
    final fileName = 'Reporte_Balance_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '📊 Reporte de Balance - $businessName\nPeriodo: $dateRangeLabel',
    );
  }

  static void _appendRow(
    Sheet sheet, 
    DateFormat df, 
    DateFormat tf, 
    DateTime date, 
    String type, 
    String contact, 
    String product, 
    double qty, 
    double price, 
    double subtotal, 
    double? total
  ) {
    sheet.appendRow([
      TextCellValue(df.format(date)),
      TextCellValue(tf.format(date)),
      TextCellValue(type),
      TextCellValue(contact),
      TextCellValue(product),
      qty > 0 ? DoubleCellValue(qty) : TextCellValue(''),
      price > 0 ? DoubleCellValue(price) : TextCellValue(''),
      DoubleCellValue(subtotal),
      total != null ? DoubleCellValue(total) : TextCellValue(''),
    ]);
  }
}
