import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'firebase_options.dart';
import 'theme/theme.dart';
import 'views/lists.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _rutas = FirebaseFirestore.instance.collection('rutas');
  final _mapKey = GlobalKey<_MapaRutasState>();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _rutasStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _ultimasRutasStream;
  int _selectedIndex = 0;
  LatLng? _posicionSeleccionada;
  BitmapDescriptor? _iconoLandscape;

  @override
  void initState() {
    super.initState();
    _crearIconoLandscape();
    _rutasStream = _rutas.snapshots();
    _ultimasRutasStream =
        _rutas.orderBy('creadoEn', descending: true).limit(10).snapshots();
  }

  // Crear un marcador con el icono landscape de Material.
  Future<void> _crearIconoLandscape() async {
    const double lado = 112;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final centro = const Offset(lado / 2, lado / 2);

    canvas.drawCircle(
      centro,
      48,
      Paint()..color = const Color(0xFF6750A4),
    );

    final texto = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.landscape.codePoint),
        style: TextStyle(
          fontSize: 62,
          fontFamily: Icons.landscape.fontFamily,
          package: Icons.landscape.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    texto.paint(
      canvas,
      Offset((lado - texto.width) / 2, (lado - texto.height) / 2),
    );

    final imagen = await recorder.endRecording().toImage(112, 112);
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
    imagen.dispose();
    if (datos == null || !mounted) return;

    setState(() {
      _iconoLandscape = BitmapDescriptor.bytes(
        datos.buffer.asUint8List(),
        imagePixelRatio: 2,
      );
    });
  }

  Future<void> _agregarRuta() async {
    final posicion = _posicionSeleccionada;
    if (posicion == null) return;
    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool guardando = false;
    bool guardadoCorrectamente = false;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              Future<void> guardar() async {
                if (guardando || !formKey.currentState!.validate()) return;
                setSheetState(() => guardando = true);

                try {
                  await _rutas.add({
                    'titulo': tituloController.text.trim(),
                    'descripcion': descripcionController.text.trim(),
                    'latitud': posicion.latitude,
                    'longitud': posicion.longitude,
                    'creadoEn': FieldValue.serverTimestamp(),
                  });
                  guardadoCorrectamente = true;
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                } catch (e) {
                  if (!sheetContext.mounted) return;
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo guardar la ruta. Inténtalo otra vez.'),
                      behavior: SnackBarBehavior.fixed,
                    ),
                  );
                  setSheetState(() => guardando = false);
                }
              }

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.spacing400,
                  AppSpacing.spacing200,
                  AppSpacing.spacing400,
                  MediaQuery.viewInsetsOf(sheetContext).bottom +
                      AppSpacing.spacing600,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nueva ruta',
                          style: Theme.of(sheetContext).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.spacing400),
                        TextFormField(
                          controller: tituloController,
                          autofocus: true,
                          enabled: !guardando,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Título',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Ingresa un título'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.spacing400),
                        TextFormField(
                          controller: descripcionController,
                          enabled: !guardando,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.spacing600),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: guardando ? null : guardar,
                            child: guardando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Guardar ruta'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      if (guardadoCorrectamente && mounted) {
        setState(() => _posicionSeleccionada = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ruta guardada correctamente'),
            behavior: SnackBarBehavior.fixed,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      tituloController.dispose();
      descripcionController.dispose();
    }
  }

  void _irARuta(Map<String, dynamic> ruta) {
    final latitud = (ruta['latitud'] as num?)?.toDouble();
    final longitud = (ruta['longitud'] as num?)?.toDouble();
    if (latitud == null || longitud == null) return;
    _mapKey.currentState?.irA(LatLng(latitud, longitud));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Trekking')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.spacing400),
        children: [
          Text('Explorar senderos', style: text.headlineLarge),
          const SizedBox(height: AppSpacing.spacing400),
          Card(
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 340,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _rutasStream,
                builder: (context, snapshot) {
                  final marcadores = <Marker>{};
                  if (snapshot.hasData) {
                    for (final doc in snapshot.data!.docs) {
                      final ruta = doc.data();
                      final lat = (ruta['latitud'] as num?)?.toDouble();
                      final lng = (ruta['longitud'] as num?)?.toDouble();
                      if (lat == null || lng == null) continue;
                      marcadores.add(
                        Marker(
                          markerId: MarkerId(doc.id),
                          icon: _iconoLandscape ?? BitmapDescriptor.defaultMarker,
                          position: LatLng(lat, lng),
                          infoWindow: InfoWindow(
                            title: ruta['titulo'] as String? ?? '',
                            snippet: ruta['descripcion'] as String? ?? '',
                          ),
                        ),
                      );
                    }
                  }
                  return _MapaRutas(
                    key: _mapKey,
                    marcadores: marcadores,
                    iconoLandscape: _iconoLandscape,
                    posicionSeleccionada: _posicionSeleccionada,
                    onSeleccionar: (posicion) {
                      setState(() => _posicionSeleccionada = posicion);
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing200),
          Text(
            _posicionSeleccionada == null
                ? 'Toca dos veces o mantén presionado el mapa para elegir un punto.'
                : 'Punto seleccionado. Presiona + para guardar la ruta.',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.spacing700),
          Text('Últimas rutas', style: text.headlineLarge),
          const SizedBox(height: AppSpacing.spacing400),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _ultimasRutasStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('No se pudieron cargar las rutas.');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final documentos = snapshot.data!.docs;
              if (documentos.isEmpty) {
                return const Text('Todavía no hay rutas guardadas.');
              }
              return Column(
                children: documentos.map((doc) {
                  final ruta = doc.data();
                  final titulo = ruta['titulo'] as String? ?? 'Sin título';
                  final descripcion = ruta['descripcion'] as String? ?? '';
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.primaryContainer,
                        child: Icon(
                          Icons.hiking,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      title: Text(titulo),
                      subtitle: descripcion.isEmpty
                          ? null
                          : Text(
                              descripcion,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _irARuta(ruta),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.spacing700),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _posicionSeleccionada == null ? null : _agregarRuta,
        tooltip: 'Agregar ruta',
        child: const Icon(Icons.add_location_alt_outlined),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ListsView()),
            );
            return;
          }
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Comunidad',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Icons.format_list_bulleted_outlined),
            selectedIcon: Icon(Icons.format_list_bulleted),
            label: 'Listas',
          ),
        ],
      ),
    );
  }
}

class _MapaRutas extends StatefulWidget {
  const _MapaRutas({
    super.key,
    required this.marcadores,
    required this.iconoLandscape,
    required this.posicionSeleccionada,
    required this.onSeleccionar,
  });

  final Set<Marker> marcadores;
  final BitmapDescriptor? iconoLandscape;
  final LatLng? posicionSeleccionada;
  final ValueChanged<LatLng> onSeleccionar;

  @override
  State<_MapaRutas> createState() => _MapaRutasState();
}

class _MapaRutasState extends State<_MapaRutas> {
  static const String _estiloMapaOscuro = r'''
[
  {"elementType":"geometry","stylers":[{"color":"#171721"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#a5a4b8"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#171721"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#393647"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#32303f"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#242330"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#57516b"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#101522"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#222531"}]},
  {"featureType":"landscape.natural.terrain","elementType":"geometry","stylers":[{"color":"#303342"}]}
]
''';
  GoogleMapController? _controller;
  DateTime? _ultimoToque;
  LatLng? _posicionPrimerToque;

  void _detectarDobleToque(LatLng posicion) {
    final ahora = DateTime.now();
    final dobleToque = _ultimoToque != null &&
        ahora.difference(_ultimoToque!).inMilliseconds < 400 &&
        _posicionPrimerToque != null &&
        (posicion.latitude - _posicionPrimerToque!.latitude).abs() < 0.003 &&
        (posicion.longitude - _posicionPrimerToque!.longitude).abs() < 0.003;
    if (dobleToque) {
      widget.onSeleccionar(posicion);
      _ultimoToque = null;
      _posicionPrimerToque = null;
    } else {
      _ultimoToque = ahora;
      _posicionPrimerToque = posicion;
    }
  }

  Future<void> irA(LatLng posicion) async {
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(posicion, 15),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(-33.4489, -70.6693),
        zoom: 11,
      ),
      mapType: MapType.normal,
      style: _estiloMapaOscuro,
      markers: {
        ...widget.marcadores,
        if (widget.posicionSeleccionada != null)
          Marker(
            markerId: const MarkerId('ubicacion_temporal'),
            position: widget.posicionSeleccionada!,
            icon: widget.iconoLandscape ?? BitmapDescriptor.defaultMarker,
            infoWindow: const InfoWindow(title: 'Ubicación seleccionada'),
          ),
      },
      onMapCreated: (controller) => _controller = controller,
      onTap: _detectarDobleToque,
      onLongPress: widget.onSeleccionar,
      zoomControlsEnabled: true,
      myLocationButtonEnabled: false,
      myLocationEnabled: false,
    );
  }
}
