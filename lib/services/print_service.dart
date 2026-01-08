import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import '../models/sale.dart';

class PrintService {
  static Future<void> printReceipt(Sale sale) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: pdf.PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('KantoPOS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text('Receipt: ${sale.receiptNumber ?? sale.id}'),
              pw.Text('Date: ${sale.timestamp.toLocal()}'),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.Column(
                children: sale.items.map((item) {
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text('${item.productName} x${item.quantity}')),
                      pw.Text(item.subtotal.toStringAsFixed(2)),
                    ],
                  );
                }).toList(),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal'),
                  pw.Text(sale.subtotal.toStringAsFixed(2)),
                ],
              ),
              if (sale.tax > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [pw.Text('Tax'), pw.Text(sale.tax.toStringAsFixed(2))],
                ),
              if (sale.discount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [pw.Text('Discount'), pw.Text('-${sale.discount.toStringAsFixed(2)}')],
                ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(sale.total.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))],
              ),
              if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text('Notes:'),
                pw.Text(sale.notes!),
              ],
              pw.Spacer(),
              pw.Center(child: pw.Text('Thank you for your purchase!')),
            ],
          );
        },
      ),
    );

    final bytes = await doc.save();
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }
}
