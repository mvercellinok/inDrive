import 'package:flutter/material.dart';

import 'ride_receipts.dart';

class RideActivityScreen extends StatefulWidget {
  const RideActivityScreen({super.key, this.onCreate});

  final Future<void> Function()? onCreate;

  @override
  State<RideActivityScreen> createState() => _RideActivityScreenState();
}

class _RideActivityScreenState extends State<RideActivityScreen> {
  late Future<List<RideReceipt>> _receipts = RideReceiptStore.load();

  Future<void> _refreshAfter(Future<void> Function() action) async {
    await action();
    if (mounted) setState(() => _receipts = RideReceiptStore.load());
  }

  Widget _history(List<RideReceipt> receipts, {required bool showReceipts}) {
    if (receipts.isEmpty) {
      return Center(
        child: Text(
          showReceipts
              ? 'Todavía no tienes recibos.'
              : 'Todavía no has finalizado viajes.',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        final receipt = receipts[index];
        return Card(
          child: ListTile(
            leading: Icon(
              showReceipts
                  ? Icons.receipt_long_outlined
                  : Icons.directions_car_outlined,
            ),
            title: Text(receipt.destination),
            subtitle: Text(receipt.formattedDate),
            trailing: Text(receipt.formattedFare),
            onTap: () => _refreshAfter(() async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      RideReceiptScreen(receipt: receipt, editable: true),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Viajes'),
            Tab(text: 'Recibos'),
          ],
        ),
      ),
      floatingActionButton: widget.onCreate == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _refreshAfter(widget.onCreate!),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo viaje'),
            ),
      body: FutureBuilder<List<RideReceipt>>(
        future: _receipts,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudo abrir el historial.'),
                  TextButton(
                    onPressed: () => setState(() {
                      _receipts = RideReceiptStore.load();
                    }),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final receipts = snapshot.data;
          if (receipts == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            children: [
              _history(receipts, showReceipts: false),
              _history(receipts, showReceipts: true),
            ],
          );
        },
      ),
    ),
  );
}
