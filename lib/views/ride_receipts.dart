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
  });

  final DateTime completedAt;
  final String pickup;
  final String destination;
  final String driver;
  final int fare;
  final String payment;

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
  };

  factory RideReceipt.fromJson(Map<String, dynamic> json) => RideReceipt(
    completedAt: DateTime.parse(json['completedAt'] as String),
    pickup: json['pickup'] as String,
    destination: json['destination'] as String,
    driver: json['driver'] as String,
    fare: json['fare'] as int,
    payment: json['payment'] as String,
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

class RideReceiptScreen extends StatelessWidget {
  const RideReceiptScreen({super.key, required this.receipt});

  final RideReceipt receipt;

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}
