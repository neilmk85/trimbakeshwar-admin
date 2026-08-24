import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/admin_models.dart';

/// Builds an .xlsx workbook from [users] and hands it to the OS share sheet
/// so the admin can save/email/WhatsApp it — no storage permissions needed
/// since the file is written to the app's private temp directory.
Future<void> exportCustomersToExcel(List<AdminUser> users) async {
  final workbook = Excel.createExcel();
  final sheetName = workbook.getDefaultSheet()!;
  final sheet = workbook[sheetName];

  const headers = [
    'Name', 'Phone', 'Email', 'City', 'Pin Code', 'Country', 'Registered On'
  ];
  sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

  for (final u in users) {
    sheet.appendRow([
      TextCellValue(u.fullName),
      TextCellValue(u.phone),
      TextCellValue(u.email),
      TextCellValue(u.city),
      TextCellValue(u.pinCode),
      TextCellValue(u.country),
      TextCellValue(u.createdAt != null ? _formatDate(u.createdAt!) : ''),
    ]);
  }

  final bytes = workbook.save();
  if (bytes == null) return;

  final dir = await getTemporaryDirectory();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final file = File('${dir.path}/trimbakeshwar_customers_$timestamp.xlsx');
  await file.writeAsBytes(bytes);

  await Share.shareXFiles(
    [XFile(file.path)],
    subject: 'Trimbakeshwar Customers',
  );
}

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
}
