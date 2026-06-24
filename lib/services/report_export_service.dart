import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../backend-api/dtos.dart';

class ReportExportService {
  static Future<void> exportToExcel({
    required List<TransactionRes> transactions,
    required List<DebtRes> debts,
    required String periodName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Reporte Financiero'];
    excel.delete('Sheet1');

    // Header Style
    final CellStyle headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#001F3F'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    // Headers
    sheet.appendRow([
      TextCellValue('Fecha'),
      TextCellValue('Tipo'),
      TextCellValue('Descripción'),
      TextCellValue('Categoría'),
      TextCellValue('Monto (C\$)'),
    ]);

    for (var i = 0; i < 5; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
    }

    final df = DateFormat('dd/MM/yyyy');

    // Add Transactions
    for (var tx in transactions) {
      sheet.appendRow([
        TextCellValue(df.format(tx.transactionDate)),
        TextCellValue(tx.type == 'income' ? 'Ingreso' : 'Egreso'),
        TextCellValue(tx.description ?? ''),
        TextCellValue(tx.category),
        DoubleCellValue(tx.amount),
      ]);
    }

    // Add Debts (as potential income/expense)
    for (var debt in debts) {
      sheet.appendRow([
        TextCellValue(df.format(debt.createdAt)),
        TextCellValue(debt.type == 'to_collect' ? 'Venta al Crédito' : 'Compra al Crédito'),
        TextCellValue('Deuda con: ${debt.contactName} - ${debt.description ?? ''}'),
        TextCellValue('Crédito'),
        DoubleCellValue(debt.totalAmount),
      ]);
    }

    // Save and Share
    final bytes = excel.save();
    if (bytes == null) return;

    final directory = await getTemporaryDirectory();
    final fileName = 'Reporte_Financiero_${periodName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Reporte Financiero - $periodName',
    );
  }
}
