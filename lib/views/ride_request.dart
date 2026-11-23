import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/theme.dart';
import 'ride_receipts.dart';

enum _RideStep {
  destination,
  pickup,
  offer,
  payment,
  waiting,
  rejected,
  accepted,
  active,
}

typedef PickupSearch = Future<({String label, LatLng? position})?> Function(
  BuildContext context,
);

class RideRequestScreen extends StatefulWidget {
  const RideRequestScreen({
    super.key,
    required this.destination,
    required this.onDestinationConfirmed,
    this.address,
    this.position,
    this.searchPickup,
  });

  final String destination;
  final String? address;
  final LatLng? position;
  final PickupSearch? searchPickup;
  final VoidCallback onDestinationConfirmed;

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  static const _defaultMapCenter = LatLng(-33.3950, -70.5060);
  static const _driverName = 'Camila Rojas';
  static const _minimumDemoFare = 2500;
  static const _reviewTime = Duration(seconds: 5);
  static const _transfers = [
    'Tenpo',
    'MACH',
    'Banco Santander',
    'Mercado Pago',
    'PagoRUT',
  ];

  final _fare = TextEditingController(text: '2000');
  final _offerForm = GlobalKey<FormState>();

  _RideStep _step = _RideStep.destination;
  LatLng? _manualPin;
  LatLng? _pickupPin;
  GoogleMapController? _mapController;
  String _pickupLabel = 'Punto marcado en el mapa';
  Timer? _reviewTimer;
  String? _paymentMethod;
  int _submittedFare = 0;
  bool _destinationConfirmed = false;
  bool _savingReceipt = false;
  RideReceipt? _receipt;

  @override
  void dispose() {
    _reviewTimer?.cancel();
    _fare.dispose();
    super.dispose();
  }

  void _confirmDestination() {
    setState(() => _step = _RideStep.pickup);
    if (!_destinationConfirmed) {
      _destinationConfirmed = true;
      widget.onDestinationConfirmed();
    }
  }

  Future<void> _searchPickup() async {
    final result = await widget.searchPickup?.call(context);
    if (!mounted || result == null) return;
    setState(() {
      _pickupLabel = result.label;
      _pickupPin = result.position;
    });
    final position = result.position;
    if (position != null) {
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(position, 16),
      );
    }
  }

  void _pickPoint(LatLng point) {
    setState(() {
      if (_step == _RideStep.pickup) {
        if (_pickupPin != null) _pickupLabel = 'Punto marcado en el mapa';
        _pickupPin = point;
      } else {
        _manualPin = point;
      }
    });
  }

  void _adjustFare(int change) {
    final current = int.tryParse(_fare.text) ?? 0;
    final adjusted = (current + change).clamp(250, 99999999).toString();
    _fare.value = TextEditingValue(
      text: adjusted,
      selection: TextSelection.collapsed(offset: adjusted.length),
    );
  }

  void _choosePayment() {
    if (!_offerForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submittedFare = int.parse(_fare.text);
      _mapController = null;
      _step = _RideStep.payment;
    });
  }

  void _requestCar() {
    if (_step != _RideStep.payment || _paymentMethod == null) return;
    setState(() => _step = _RideStep.waiting);
    _reviewTimer = Timer(_reviewTime, () {
      if (!mounted || _step != _RideStep.waiting) return;
      setState(() {
        _step = _submittedFare >= _minimumDemoFare
            ? _RideStep.accepted
            : _RideStep.rejected;
      });
    });
  }

  void _close() {
    _reviewTimer?.cancel();
    Navigator.of(context).pop();
  }

  void _goBack() {
    switch (_step) {
      case _RideStep.pickup:
        setState(() => _step = _RideStep.destination);
        return;
      case _RideStep.offer:
        setState(() => _step = _RideStep.pickup);
        return;
      case _RideStep.payment:
        setState(() => _step = _RideStep.offer);
        return;
      default:
        _close();
    }
  }

  String _formatFare(int fare) {
    final digits = fare.toString();
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '\$$grouped CLP';
  }

  Widget _locationCard(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: AppColors.neutral0,
      elevation: 2,
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: AppColors.primary800),
        title: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(label),
      ),
    );
  }

  Widget _map({required double bottomPadding}) {
    final position = widget.position ?? _manualPin;
    final address = widget.address;
    return Stack(
      fit: StackFit.expand,
      children: [
        GoogleMap(
          padding: EdgeInsets.only(bottom: bottomPadding),
          initialCameraPosition: CameraPosition(
            target:
                _pickupPin ??
                widget.position ??
                _manualPin ??
                _defaultMapCenter,
            zoom: widget.position == null ? 14 : 16,
          ),
          onMapCreated: (controller) => _mapController = controller,
          markers: {
            if (position != null)
              Marker(
                markerId: const MarkerId('destination'),
                position: position,
                infoWindow: InfoWindow(title: widget.destination),
              ),
            if (_pickupPin case final pickup?)
              Marker(
                markerId: const MarkerId('pickup'),
                position: pickup,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
                infoWindow: const InfoWindow(title: 'Recogida'),
              ),
          },
          onTap:
              _step == _RideStep.pickup ||
                  (_step == _RideStep.destination && widget.position == null)
              ? _pickPoint
              : null,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
        ),
        Positioned(
          top: 8,
          left: 12,
          right: 12,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: AppColors.neutral0,
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  tooltip: 'Volver',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _goBack,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    _locationCard(
                      Icons.location_on_outlined,
                      'Destino',
                      address == null || address.isEmpty
                          ? widget.destination
                          : address,
                    ),
                    if (_pickupPin != null && _step != _RideStep.pickup)
                      _locationCard(
                        Icons.trip_origin,
                        'Recogida',
                        _pickupLabel,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _destinationFields() => [
    if (widget.position == null)
      Text(
        _manualPin == null
            ? 'Puedes tocar el mapa para marcar tu destino.'
            : 'Destino marcado en el mapa.',
      ),
    _button(
      'Confirmar destino',
      widget.position != null || _manualPin != null
          ? _confirmDestination
          : null,
    ),
  ];

  List<Widget> _pickupFields() => [
    if (widget.searchPickup != null)
      OutlinedButton.icon(
        onPressed: _searchPickup,
        icon: const Icon(Icons.search),
        label: const Text('Buscar dirección de recogida'),
      ),
    Text(
      _pickupPin == null
          ? 'Toca el mapa para marcar el punto de recogida.'
          : _pickupLabel,
    ),
    _button(
      'Confirmar recogida',
      _pickupPin == null ? null : () => setState(() => _step = _RideStep.offer),
    ),
    if (_pickupPin != null)
      TextButton(
        onPressed: () => setState(() {
          _pickupPin = null;
          _pickupLabel = 'Punto marcado en el mapa';
        }),
        child: const Text('Quitar punto'),
      ),
  ];

  List<Widget> _offerFields() => [
    Card(
      color: AppColors.primary50,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Form(
          key: _offerForm,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: r'Bajar $250',
                onPressed: () => _adjustFare(-250),
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: TextFormField(
                    controller: _fare,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _choosePayment(),
                    decoration: const InputDecoration(
                      prefixText: 'CLP ',
                      labelText: 'Monto ofrecido',
                      errorMaxLines: 2,
                    ),
                    validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0
                        ? 'Ingresa un monto mayor a cero.'
                        : null,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: r'Subir $250',
                onPressed: () => _adjustFare(250),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    ),
    _button('Elegir método de pago', _choosePayment),
  ];

  Widget _paymentOption(String method, IconData icon) {
    final selected = _paymentMethod == method;
    return ListTile(
      dense: true,
      selected: selected,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(method),
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
      ),
      onTap: () => setState(() => _paymentMethod = method),
    );
  }

  List<Widget> _paymentFields() => [
    Text('Oferta de ${_formatFare(_submittedFare)}'),
    const SizedBox(height: 16),
    const Text('Transferencia'),
    for (final method in _transfers)
      _paymentOption(method, Icons.account_balance_wallet_outlined),
    const Divider(),
    _paymentOption('Efectivo', Icons.payments_outlined),
    _button('Enviar oferta', _paymentMethod == null ? null : _requestCar),
  ];

  Widget _button(String label, VoidCallback? onPressed) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: FilledButton(onPressed: onPressed, child: Text(label)),
  );

  Widget _cancelButton() =>
      TextButton(onPressed: _close, child: const Text('Cancelar solicitud'));

  List<Widget> _requestStatus() {
    final text = switch (_step) {
      _RideStep.waiting => 'El conductor está revisando tu oferta.',
      _RideStep.rejected =>
        'El conductor rechazó el monto. Puedes ofrecer '
            '${_formatFare(_minimumDemoFare)} o más.',
      _RideStep.accepted => 'El conductor aceptó tu oferta.',
      _ => 'El servicio está en curso.',
    };
    return [
      Text(text),
      if (_step == _RideStep.waiting)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: _reviewTime,
            builder: (context, progress, child) =>
                LinearProgressIndicator(value: progress),
          ),
        ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.payments_outlined),
        title: Text(_formatFare(_submittedFare)),
        subtitle: Text(_paymentMethod!),
      ),
      if (_step == _RideStep.rejected)
        _button('Cambiar monto', () => setState(() => _step = _RideStep.offer)),
      if (_step == _RideStep.accepted) ...[
        _driverTile(),
        _button('Iniciar viaje', () {
          setState(() => _step = _RideStep.active);
          final pickup = _pickupPin;
          if (pickup != null) {
            _mapController?.animateCamera(CameraUpdate.newLatLng(pickup));
          }
        }),
      ],
      _cancelButton(),
      const Text('Demostración · conductor simulado'),
    ];
  }

  Widget _driverTile() => const ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(child: Icon(Icons.person_outline)),
    title: Text('$_driverName · Conductora demo'),
    subtitle: Text('Kia Rio blanco · AB-CD-12 · ★ 4,9'),
  );

  Widget _rideAction(IconData icon, String label, String message) {
    return Expanded(
      child: Column(
        children: [
          IconButton.filled(
            tooltip: label,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary500,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 48),
            ),
            icon: Icon(icon),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (context) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (message.isNotEmpty) Text(message) else _driverTile(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  List<Widget> _activeFields() => [
    const Text('7 min estimados · Simulación'),
    const SizedBox(height: 14),
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rideAction(Icons.person_outline, 'Conductora', ''),
        _rideAction(
          Icons.airline_seat_recline_normal,
          'Viaje',
          'Recogida: $_pickupLabel\nDestino: ${widget.destination}',
        ),
        _rideAction(
          Icons.shield_outlined,
          'Seguridad',
          'Verifica la patente AB-CD-12 y el vehículo antes de subir.',
        ),
      ],
    ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.payments_outlined),
      title: Text(_formatFare(_submittedFare)),
      subtitle: Text(_paymentMethod!),
    ),
    FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF376DCC),
        foregroundColor: Colors.white,
      ),
      onPressed: _savingReceipt ? null : _finishRide,
      child: Text(_savingReceipt ? 'Guardando recibo…' : 'Finalizar viaje'),
    ),
  ];

  Future<void> _finishRide() async {
    if (_savingReceipt) return;
    setState(() => _savingReceipt = true);
    final receipt = RideReceipt(
      completedAt: DateTime.now().toUtc(),
      pickup: _pickupLabel,
      destination: widget.destination,
      driver: _driverName,
      fare: _submittedFare,
      payment: _paymentMethod!,
    );
    try {
      await RideReceiptStore.save(receipt);
      if (!mounted) return;
      setState(() => _receipt = receipt);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar el recibo. Reintenta.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingReceipt = false);
    }
  }

  Widget _thankYou(RideReceipt receipt) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppPadding.paddingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 56,
                color: AppColors.primary500,
              ),
              const SizedBox(height: 16),
              Text(
                '¡Gracias por viajar con nosotros!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu recibo quedó en Activity → Recibos.',
                textAlign: TextAlign.center,
              ),
              _button(
                'Ver recibo',
                () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => RideReceiptScreen(receipt: receipt),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Volver a Inicio'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;
    if (receipt != null) return _thankYou(receipt);
    final title = switch (_step) {
      _RideStep.destination => 'Confirma el destino',
      _RideStep.pickup => 'Confirma la recogida',
      _RideStep.offer => 'Propón un monto',
      _RideStep.payment => 'Elige cómo pagar',
      _RideStep.waiting => 'Esperando al conductor',
      _RideStep.rejected => 'Oferta rechazada',
      _RideStep.accepted => 'Viaje confirmado',
      _RideStep.active => 'Viaje en curso',
    };

    if (_step == _RideStep.payment) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: BackButton(onPressed: _goBack),
        ),
        body: SafeArea(
          child: ListView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(AppPadding.paddingLg),
            children: _paymentFields(),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const margin = 12.0;
            final panelHeight =
                constraints.maxHeight *
                (_step == _RideStep.active ? 0.64 : 0.58);
            return Stack(
              fit: StackFit.expand,
              children: [
                _map(bottomPadding: panelHeight + margin),
                Positioned(
                  left: margin,
                  right: margin,
                  bottom: margin,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 480,
                        maxHeight: panelHeight,
                      ),
                      child: Material(
                        color: AppColors.neutral0,
                        elevation: 2,
                        borderRadius: BorderRadius.circular(
                          AppRadius.radius2xl,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListView(
                          key: ValueKey(_step),
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.all(AppPadding.paddingLg),
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            ...(switch (_step) {
                              _RideStep.destination => _destinationFields(),
                              _RideStep.pickup => _pickupFields(),
                              _RideStep.offer => _offerFields(),
                              _RideStep.active => _activeFields(),
                              _ => _requestStatus(),
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
