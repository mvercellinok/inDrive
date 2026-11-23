import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalProfiles {
  static const principal = 'principal';
  static const alternate = 'alternativo';
  static Map<String, dynamic> _state = {};

  static Future<File> _file() async {
    final root = await getApplicationSupportDirectory();
    await root.create(recursive: true);
    return File('${root.path}/demo_profiles.json');
  }

  static Future<Map<String, dynamic>> _read() async {
    if (kIsWeb) return _state;
    final file = await _file();
    if (!await file.exists()) return {};
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  static Future<void> _write(Map<String, dynamic> data) async {
    if (kIsWeb) {
      _state = data;
      return;
    }
    final file = await _file();
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(data), flush: true);
    await temporary.rename(file.path);
  }

  static Future<String> activeId() async {
    final data = await _read();
    return data['active'] == alternate ? alternate : principal;
  }

  static Future<String?> alternateName() async {
    final data = await _read();
    return (data['profile'] as Map<String, dynamic>?)?['nombre'] as String?;
  }

  static Future<void> switchTo(String id, {String? newName}) async {
    final data = await _read();
    if (newName != null) data['profile'] = {'nombre': newName};
    data['active'] = id;
    await _write(data);
  }

  static Future<Map<String, dynamic>> readAlternate() async {
    final data = await _read();
    return (data['profile'] as Map<String, dynamic>?) ?? {};
  }

  static Future<void> saveAlternate(Map<String, dynamic> profile) async {
    final data = await _read();
    data['profile'] = profile;
    await _write(data);
  }
}
