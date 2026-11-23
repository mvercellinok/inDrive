import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'local_profiles.dart';

class RideReceipt {
  const RideReceipt({
    required this.completedAt,
    required this.pickup,
    required this.destination,
    required this.driver,
    required this.fare,
    required this.payment,
    this.note = '',
  });

  final DateTime completedAt;
  final String pickup;
  final String destination;
  final String driver;
  final int fare;
  final String payment;
  final String note;

  String get id => completedAt.microsecondsSinceEpoch.toString();

  String get formattedFare {
    final amount = fare.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '\$$amount CLP';
  }

  String get formattedDate {
    final local = completedAt.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year}'
        ' · ${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  Map<String, Object> toJson() => {
    'completedAt': completedAt.toIso8601String(),
    'pickup': pickup,
    'destination': destination,
    'driver': driver,
    'fare': fare,
    'payment': payment,
    'note': note,
  };

  factory RideReceipt.fromJson(Map<String, dynamic> json) => RideReceipt(
    completedAt: DateTime.parse(json['completedAt'] as String),
    pickup: json['pickup'] as String,
    destination: json['destination'] as String,
    driver: json['driver'] as String,
    fare: json['fare'] as int,
    payment: json['payment'] as String,
    note: json['note'] as String? ?? '',
  );
}

class RideReceiptStore {
  static final _webReceipts = <String, RideReceipt>{};

  static Future<Directory> _directory(String profileId) async {
    final support = await getApplicationSupportDirectory();
    final base = '${support.path}/ride_receipts';
    return Directory(
      profileId == LocalProfiles.principal ? base : '$base/$profileId',
    );
  }

  static Future<void> save(RideReceipt receipt) async {
    final profileId = await LocalProfiles.activeId();
    if (kIsWeb) {
      _webReceipts['$profileId:${receipt.id}'] = receipt;
      return;
    }
    final directory = await (await _directory(profileId))
        .create(recursive: true);
    final path = '${directory.path}/${receipt.id}.json';
    final temporary = File('$path.tmp');
    await temporary.writeAsString(jsonEncode(receipt.toJson()), flush: true);
    await temporary.rename(path);
  }

  static Future<void> delete(RideReceipt receipt) async {
    final profileId = await LocalProfiles.activeId();
    if (kIsWeb) {
      _webReceipts.remove('$profileId:${receipt.id}');
      return;
    }
    final directory = await _directory(profileId);
    final file = File('${directory.path}/${receipt.id}.json');
    if (await file.exists()) await file.delete();
  }

  static Future<List<RideReceipt>> load() async {
    final profileId = await LocalProfiles.activeId();
    final receipts = <RideReceipt>[];
    if (kIsWeb) {
      receipts.addAll(
        _webReceipts.entries
            .where((entry) => entry.key.startsWith('$profileId:'))
            .map((entry) => entry.value),
      );
    } else {
      final directory = await _directory(profileId);
      if (await directory.exists()) {
        await for (final entry in directory.list(followLinks: false)) {
          if (entry is File && entry.path.endsWith('.json')) {
            final data = jsonDecode(await entry.readAsString());
            receipts.add(RideReceipt.fromJson(data as Map<String, dynamic>));
          }
        }
      }
    }
    receipts.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return receipts;
  }
}

class RideReceiptScreen extends StatefulWidget {
  const RideReceiptScreen({
    super.key,
    required this.receipt,
    this.editable = false,
  });

  final RideReceipt receipt;
  final bool editable;

  @override
  State<RideReceiptScreen> createState() => _RideReceiptScreenState();
}

class _RideReceiptScreenState extends State<RideReceiptScreen> {
  late final _note = TextEditingController(text: widget.receipt.note);
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final receipt = widget.receipt;
    await _change(
      () => RideReceiptStore.save(
        RideReceipt(
          completedAt: receipt.completedAt,
          pickup: receipt.pickup,
          destination: receipt.destination,
          driver: receipt.driver,
          fare: receipt.fare,
          payment: receipt.payment,
          note: _note.text.trim(),
        ),
      ),
      'Nota guardada',
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar este recibo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _change(
      () => RideReceiptStore.delete(widget.receipt),
      'Recibo eliminado',
    );
  }

  Future<void> _change(Future<void> Function() action, String message) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el recibo.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receipt = widget.receipt;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Recibo del viaje')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.receipt_long_outlined, size: 40),
          const SizedBox(height: 12),
          Text(
            receipt.formattedFare,
            textAlign: TextAlign.center,
            style: text.headlineMedium,
          ),
          Text(receipt.formattedDate, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.trip_origin),
                  title: const Text('Recogida'),
                  subtitle: Text(receipt.pickup),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Destino'),
                  subtitle: Text(receipt.destination),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Conductora'),
                  subtitle: Text(receipt.driver),
                ),
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Método de pago'),
                  subtitle: Text(receipt.payment),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Recibo de demostración · Sin cobro real'),
          if (widget.editable) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              enabled: !_busy,
              maxLength: 160,
              decoration: const InputDecoration(labelText: 'Nota personal'),
            ),
            FilledButton(
              onPressed: _busy ? null : _saveNote,
              child: const Text('Guardar nota'),
            ),
            TextButton.icon(
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar recibo'),
            ),
          ] else if (receipt.note.isNotEmpty)
            Text(receipt.note),
        ],
      ),
    );
  }
}
