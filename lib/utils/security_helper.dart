// lib/security_helper.dart
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SecurityHelper {
  static const String _pinKey = 'app_pin';
  static const String _securityQuestionKey = 'security_question';
  static const String _securityAnswerKey = 'security_answer';
  static const String _pinEnabledKey = 'pin_enabled';

  // Helper method to get value from database
  static Future<String?> _getValue(String key) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      DatabaseHelper.securityTable,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isNotEmpty) {
      return result.first['value'] as String?;
    }
    return null;
  }

  // Helper method to set value in database
  static Future<void> _setValue(String key, String value) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(DatabaseHelper.securityTable, {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Helper method to delete value from database
  static Future<void> _deleteValue(String key) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      DatabaseHelper.securityTable,
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  // Check if PIN is enabled
  static Future<bool> isPinEnabled() async {
    final value = await _getValue(_pinEnabledKey);
    return value == 'true';
  }

  // Enable PIN
  static Future<void> enablePin() async {
    await _setValue(_pinEnabledKey, 'true');
  }

  // Disable PIN
  static Future<void> disablePin() async {
    await _setValue(_pinEnabledKey, 'false');
  }

  // Check if PIN is set
  static Future<bool> isPinSet() async {
    final value = await _getValue(_pinKey);
    return value != null;
  }

  // Save PIN
  static Future<void> savePin(String pin) async {
    await _setValue(_pinKey, pin);
    await enablePin();
  }

  // Verify PIN
  static Future<bool> verifyPin(String pin) async {
    final savedPin = await _getValue(_pinKey);
    return savedPin == pin;
  }

  // Delete PIN
  static Future<void> deletePin() async {
    await _deleteValue(_pinKey);
    await _deleteValue(_pinEnabledKey);
  }

  // Save security question and answer
  static Future<void> saveSecurityQA(String question, String answer) async {
    await _setValue(_securityQuestionKey, question);
    await _setValue(_securityAnswerKey, answer.toLowerCase().trim());
  }

  // Get security question
  static Future<String?> getSecurityQuestion() async {
    return await _getValue(_securityQuestionKey);
  }

  // Verify security answer
  static Future<bool> verifySecurityAnswer(String answer) async {
    final savedAnswer = await _getValue(_securityAnswerKey);
    return savedAnswer == answer.toLowerCase().trim();
  }

  // Check if security question is set
  static Future<bool> isSecurityQuestionSet() async {
    final value = await _getValue(_securityQuestionKey);
    return value != null;
  }
}
