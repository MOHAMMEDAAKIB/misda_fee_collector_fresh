// lib/services/whatsapp_service.dart
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/student.dart';
import '../models/payment.dart';
import '../services/analytics.dart';

class WhatsAppService {
  static String message(Student s) =>
      'Hello ${s.name}, you are now registered.\n'
      'Registration number: ${s.regNo}\n'
      'Please show the attached QR code when you pay your class fee.';

  /// Opens the student's chat with the text prefilled (admin taps Send).
  static Future<bool> openChat(Student s) {
    final uri = Uri.parse(
        'https://wa.me/${s.phone}?text=${Uri.encodeComponent(message(s))}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Opens a WhatsApp chat with arbitrary phone + text.
  static Future<bool> openText(String phone, String text) => launchUrl(
      Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(text)}'),
      mode: LaunchMode.externalApplication);

  /// Payment receipt text to send after marking paid.
  static String receipt(Student s, Payment p,
      {required num fee, required num totalPaid}) {
    final balance = fee - totalPaid;
    return 'Payment received ✅\n'
        'Name: ${s.name}\n'
        'Reg No: ${s.regNo}\n'
        'Month: ${monthLabel(p.month)}\n'
        'Fee: Rs. ${money(fee)}\n'
        'Paid now: Rs. ${money(p.amount)}\n'
        'Total paid: Rs. ${money(totalPaid)}\n'
        'Balance: Rs. ${money(balance < 0 ? 0 : balance)}\n'
        'Date: ${p.paidDate}\n'
        'Thank you!';
  }

  /// Shares QR image + caption through the system share sheet.
  static Future<ShareResult> shareQr(Student s, File png) {
    return SharePlus.instance.share(ShareParams(
      files: [XFile(png.path, mimeType: 'image/png')],
      text: message(s),
    ));
  }
}
