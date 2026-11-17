// lib/services/sheets_service.dart
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'auth_service.dart';

const spreadsheetId = '1p4BqaUNCPlMCu7jBNge1tV6umvnKq-ScwZgk4D0YSlU';

class SheetsService {
  SheetsService(this.auth);
  final AuthService auth;

  Future<sheets.SheetsApi> _api() async =>
      sheets.SheetsApi(await auth.client());

  Future<List<List<Object?>>> read(String range) async {
    final res = await (await _api()).spreadsheets.values.get(spreadsheetId, range);
    return res.values ?? [];
  }

  Future<void> append(String range, List<Object?> row, {bool raw = false}) async {
    await (await _api()).spreadsheets.values.append(
      sheets.ValueRange(values: [row]),
      spreadsheetId,
      range,
      valueInputOption: raw ? 'RAW' : 'USER_ENTERED',
      insertDataOption: 'INSERT_ROWS',
    );
  }

  Future<void> update(String range, List<Object?> row) async {
    await (await _api()).spreadsheets.values.update(
      sheets.ValueRange(values: [row]),
      spreadsheetId,
      range,
      valueInputOption: 'USER_ENTERED',
    );
  }

  Future<void> batchUpdate(Map<String, Object?> cells) async {
    if (cells.isEmpty) return;
    final req = sheets.BatchUpdateValuesRequest(
      valueInputOption: 'RAW',
      data: [
        for (final e in cells.entries)
          sheets.ValueRange(range: e.key, values: [[e.value]]),
      ],
    );
    await (await _api()).spreadsheets.values.batchUpdate(req, spreadsheetId);
  }
}