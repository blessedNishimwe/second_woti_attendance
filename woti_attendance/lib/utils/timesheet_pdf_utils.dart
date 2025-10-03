// TODO Implement this library.
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class TimesheetPdfUtils {
  /// Generates a PDF document from the timesheet data and returns it as a pw.Document.
  static Future<pw.Document> generateTimesheetPdf({
    required String employeeName,
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, String>> rows,
    required double totalHours,
    String projectName = "USAID Afya Yangu (My Health) Southern Project",
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Timesheet $projectName",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.SizedBox(height: 8),
              pw.Text(
                "Timesheet period: ${DateFormat('dd-MMM-yyyy').format(startDate)} – ${DateFormat('dd-MMM-yyyy').format(endDate)}",
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 4),
              pw.Text("Employee's Name: $employeeName",
                  style: pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: [
                  'Day',
                  'Date',
                  'Hours worked',
                  'Description of activities'
                ],
                data: rows
                    .map((row) => [
                          row['day'] ?? '',
                          row['date'] ?? '',
                          row['hoursWorked'] ?? '',
                          row['activities'] ?? '',
                        ])
                    .toList(),
                cellStyle: pw.TextStyle(fontSize: 10),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                border: pw.TableBorder.all(),
              ),
              pw.SizedBox(height: 8),
              pw.Text("Total Hours Worked: ${totalHours.toStringAsFixed(2)}",
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 24),
              pw.Row(
                children: [
                  pw.Text("Employee's Signature: ________________________",
                      style: pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Text("Supervisor's Signature: ______________________",
                      style: pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
