import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../theme/theme.dart';
import 'places_web_stub.dart' if (dart.library.js_interop) 'places_web.dart';
import 'profile.dart';
import 'ride_request.dart';
import 'ride_activity.dart';

const _placesKey = String.fromEnvironment('PLACES_API_KEY');

// MODELO DE UN RESULTADO
class _Lugar {
  const _Lugar({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.posicion,
  });

  final String id;
  final String nombre;
  final String direccion;
  final LatLng posicion;

  factory _Lugar.fromJson(Map<String, dynamic> json) {
    final ubicacion = json['location'] as Map<String, dynamic>;
    final nombre = json['displayName'] as Map<String, dynamic>?;

    return _Lugar(
      id: json['id'] as String,
      nombre: nombre?['text'] as String? ?? 'Destino',
      direccion: json['formattedAddress'] as String? ?? '',
      posicion: LatLng(
        (ubicacion['latitude'] as num).toDouble(),
        (ubicacion['longitude'] as num).toDouble(),
      ),
    );
  }
}

// CONSULTAS A GOOGLE PLACES
class _Places {
  static const _campos = 'id,displayName,formattedAddress,location';

  static void _revisarClave() {
    if (_placesKey.isEmpty) {
      throw Exception('Falta PLACES_API_KEY al ejecutar Flutter.');
    }
  }

  static Future<List<_Lugar>> buscar(String texto) async {
    if (kIsWeb) {
      final json = await searchPlacesWeb(texto)
          .timeout(const Duration(seconds: 20));
      return (jsonDecode(json) as List<dynamic>)
          .map((item) => _Lugar.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    _revisarClave();

    final respuesta = await http
        .post(
          Uri.parse('https://places.googleapis.com/v1/places:searchText'),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _placesKey,
            'X-Goog-FieldMask':
                'places.id,places.displayName,'
                'places.formattedAddress,places.location',
          },
          body: jsonEncode({
            'textQuery': texto,
            'languageCode': 'es',
            'regionCode': 'CL',
            'pageSize': 10,
            'locationBias': {
              'circle': {
                'center': {'latitude': -33.4489, 'longitude': -70.6693},
                'radius': 30000.0,
              },
            },
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (respuesta.statusCode != 200) {
      throw Exception(
        'Google Places respondió ${respuesta.statusCode}. '
        'Revisa la clave, Places API (New) y la facturación.',
      );
    }

    final datos =
        jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;

    final lista = datos['places'] as List<dynamic>? ?? [];

    return lista
        .map((item) => _Lugar.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<_Lugar> obtener(String placeId) async {
    if (kIsWeb) {
      final json = await getPlaceWeb(placeId)
          .timeout(const Duration(seconds: 20));
      return _Lugar.fromJson(jsonDecode(json) as Map<String, dynamic>);
    }

    _revisarClave();

    final respuesta = await http
        .get(
          Uri.https('places.googleapis.com', '/v1/places/$placeId', {
            'languageCode': 'es',
          }),
          headers: {'X-Goog-Api-Key': _placesKey, 'X-Goog-FieldMask': _campos},
        )
        .timeout(const Duration(seconds: 20));

    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudo recuperar el lugar '
        '(${respuesta.statusCode}).',
      );
    }

    return _Lugar.fromJson(
      jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>,
    );
  }
}

// PANTALLA DE INICIO
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenRoutes});

  final void Function(BuildContext) onOpenRoutes;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _inicio = LatLng(-33.3950, -70.5060);

  GoogleMapController? _mapController;
  _Lugar? _seleccionado;

  Stream<QuerySnapshot<Map<String, dynamic>>>? _recientes;

  String? _errorSesion;
  bool _conectando = false;
  bool _cargandoLugar = false;

  @override
  void initState() {
    super.initState();
    _conectarFirebase();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _conectarFirebase() async {
    if (_conectando) return;

    setState(() {
      _conectando = true;
      _errorSesion = null;
    });

    try {
      var usuario = FirebaseAuth.instance.currentUser;

      usuario ??= (await FirebaseAuth.instance.signInAnonymously()).user;

      if (usuario == null) {
        throw Exception('No se pudo iniciar sesión.');
      }

      final stream = FirebaseFirestore.instance
          .collection('destinos')
          .where('usuarioId', isEqualTo: usuario.uid)
          .orderBy('actualizadoEn', descending: true)
          .limit(5)
          .snapshots();

      if (!mounted) return;

      setState(() {
        _recientes = stream;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorSesion =
            'No se pudo conectar el historial. '
            'Revisa internet y Authentication.';
      });
    } finally {
      if (mounted) {
        setState(() => _conectando = false);
      }
    }
  }

  Future<void> _buscar() async {
    final resultado = await Navigator.of(context)
        .push<({_Lugar? lugar, String consulta})>(
          MaterialPageRoute(builder: (_) => const _BuscarLugar()),
        );

    if (!mounted || resultado == null) return;

    await _confirmarDestino(resultado.lugar, resultado.consulta);
  }

  Future<void> _confirmarDestino(_Lugar? lugar, String consulta) async {
    final confirmado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RideRequestScreen(
          destination: lugar?.nombre ?? consulta,
          address: lugar?.direccion,
          position: lugar?.posicion,
          searchPickup: (rideContext) async {
            final result = await Navigator.of(rideContext)
                .push<({_Lugar? lugar, String consulta})>(
                  MaterialPageRoute(
                    builder: (_) =>
                        const _BuscarLugar(title: 'Buscar recogida'),
                  ),
                );
            if (result == null) return null;
            final place = result.lugar;
            return (
              label: place == null
                  ? result.consulta
                  : (place.direccion.isEmpty ? place.nombre : place.direccion),
              position: place?.posicion,
            );
          },
          onDestinationConfirmed: () {
            _mostrarYGuardar(lugar, consulta);
          },
        ),
      ),
    );
    if (confirmado == true && mounted) {
      setState(() => _seleccionado = null);
    }
  }

  Future<void> _mostrarYGuardar(_Lugar? lugar, String consulta) async {
    if (!mounted) return;
    setState(() => _seleccionado = lugar);
    if (lugar == null) return;

    try {
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(lugar.posicion, 16),
      );
    } catch (_) {
      // El marcador queda visible aunque falle la animación.
    }

    try {
      final usuario = FirebaseAuth.instance.currentUser;

      if (usuario == null) {
        throw Exception('No hay una sesión activa.');
      }

      // Guarda el ID de Google y el texto escrito por el usuario.
      // Al abrir un reciente, consulta las coordenadas actuales.

      await FirebaseFirestore.instance
          .collection('destinos')
          .doc('${usuario.uid}_${lugar.id}')
          .set({
            'usuarioId': usuario.uid,
            'placeId': lugar.id,
            'consulta': consulta,
            'actualizadoEn': FieldValue.serverTimestamp(),
          });
    } catch (_) {
      _mensaje(
        'El lugar está en el mapa, pero no se pudo '
        'guardar en recientes. Revisa Firebase.',
      );
    }
  }

  Future<void> _abrirReciente(String placeId, String consulta) async {
    if (_cargandoLugar) return;

    setState(() => _cargandoLugar = true);

    try {
      final lugar = await _Places.obtener(placeId);

      if (!mounted) return;

      await _confirmarDestino(lugar, consulta);
    } catch (error) {
      _mensaje(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _cargandoLugar = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const ListTile(
                title: Text('inDrive', style: AppTypography.headline5),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.route_outlined),
                title: const Text('Rutas guardadas'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onOpenRoutes(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: _inicio,
                    zoom: 16,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;

                    final lugar = _seleccionado;

                    if (lugar != null) {
                      controller.moveCamera(
                        CameraUpdate.newLatLngZoom(lugar.posicion, 16),
                      );
                    }
                  },
                  markers: {
                    if (_seleccionado != null)
                      Marker(
                        markerId: MarkerId(_seleccionado!.id),
                        position: _seleccionado!.posicion,
                        infoWindow: InfoWindow(
                          title: _seleccionado!.nombre,
                          snippet: _seleccionado!.direccion,
                        ),
                      ),
                  },
                  padding: EdgeInsets.only(
                    bottom: constraints.maxHeight * 0.55,
                  ),
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                );
              },
            ),
          ),

          // MENÚ SOBRE EL MAPA
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppPadding.paddingLg),
              child: Builder(
                builder: (context) => Material(
                  color: AppColors.neutral0,
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: IconButton(
                    tooltip: 'Abrir menú',
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
              ),
            ),
          ),

          // PANEL INFERIOR
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.55,
              widthFactor: 1,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.neutral0,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.radius2xl),
                  ),
                  boxShadow: AppElevation.elevation5,
                ),
                child: ListView(
                  padding: const EdgeInsets.all(AppPadding.paddingLg),
                  children: [
                    // BUSCADOR
                    Material(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(AppRadius.radiusLg),
                      child: InkWell(
                        onTap: _buscar,
                        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
                        child: Padding(
                          padding: const EdgeInsets.all(AppPadding.paddingLg),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search,
                                color: AppColors.neutral500,
                              ),
                              const SizedBox(width: AppGap.gapComponent),
                              Expanded(
                                child: Text(
                                  _seleccionado?.nombre ?? 'Buscar destinos',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.subtitle1.copyWith(
                                    color: AppColors.primary800,
                                  ),
                                ), // Text
                              ), // Expanded

                              if (_seleccionado != null)
                                IconButton(
                                  tooltip: 'Quitar destino',
                                  icon: const Icon(
                                    Icons.close,
                                    color: AppColors.neutral500,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _seleccionado = null;
                                    });
                                  },
                                ),
                            ],
                          ), // Row
                        ),
                      ),
                    ),

                    if (_cargandoLugar)
                      const Padding(
                        padding: EdgeInsets.all(AppPadding.paddingLg),
                        child: LinearProgressIndicator(),
                      ),

                    const SizedBox(height: AppGap.gapComponent),

                    _listaRecientes(),

                    const SizedBox(height: AppGap.gapGroup),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final ancho =
                            (constraints.maxWidth - AppGap.gapComponent) / 2;

                        return Wrap(
                          spacing: AppGap.gapComponent,
                          runSpacing: AppGap.gapComponent,
                          children: [
                            _servicio(
                              ancho,
                              'Pedir un auto',
                              'Ofrece tu precio',
                              Icons.directions_car_outlined,
                              principal: true,
                            ),
                            _servicio(
                              ancho,
                              'Courrier',
                              'Send a package',
                              Icons.inventory_2_outlined,
                            ),
                            _servicio(
                              ancho,
                              'Intercity',
                              'Ciudad a ciudad',
                              Icons.route_outlined,
                            ),
                            _servicio(
                              ancho,
                              'Freight',
                              'Transportes',
                              Icons.local_shipping_outlined,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        backgroundColor: AppColors.neutral0,
        indicatorColor: AppColors.primary50,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => RideActivityScreen(onCreate: _buscar),
              ),
            );
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            );
          } else if (index != 0) {
            _mensaje('Esta sección todavía está pendiente.');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(
              Icons.home_outlined,
              color: AppColors.primary500,
            ),
            label: 'Home',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Activity'),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _listaRecientes() {
    if (_errorSesion != null) {
      return ListTile(
        title: Text(_errorSesion!, style: AppTypography.body2),
        trailing: IconButton(
          tooltip: 'Reintentar',
          icon: const Icon(Icons.refresh),
          onPressed: _conectarFirebase,
        ),
      );
    }

    if (_recientes == null) {
      return const Padding(
        padding: EdgeInsets.all(AppPadding.paddingLg),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _recientes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('ERROR HISTORIAL: ${snapshot.error}');

          return Padding(
            padding: const EdgeInsets.all(AppPadding.paddingLg),
            child: Text(
              'Error del historial: ${snapshot.error}',
              style: AppTypography.body2,
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(AppPadding.paddingLg),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final documentos = snapshot.data!.docs;

        if (documentos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppPadding.paddingLg),
            child: Text(
              'Busca un lugar para agregarlo a tus recientes.',
              style: AppTypography.body2,
            ),
          );
        }

        return Column(
          children: documentos.map((documento) {
            final datos = documento.data();
            final placeId = datos['placeId'];
            final consulta = datos['consulta'];

            if (placeId is! String || consulta is! String) {
              return const SizedBox.shrink();
            }

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary50,
                child: Icon(Icons.history, color: AppColors.primary800),
              ),
              title: Text(consulta, style: AppTypography.body2),
              trailing: const Icon(
                Icons.north_west,
                color: AppColors.primary500,
              ),
              onTap: _cargandoLugar
                  ? null
                  : () => _abrirReciente(placeId, consulta),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _servicio(
    double ancho,
    String titulo,
    String subtitulo,
    IconData icono, {
    bool principal = false,
  }) {
    final texto = principal ? AppColors.neutral0 : AppColors.primary800;

    return SizedBox(
      width: ancho,
      child: Material(
        color: principal ? AppColors.primary500 : AppColors.primary50,
        borderRadius: BorderRadius.circular(AppRadius.radius2xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: principal
              ? _buscar
              : () => _mensaje('$titulo: servicio pendiente'),
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.paddingXl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppTypography.headline6.copyWith(color: texto),
                ),
                const SizedBox(height: AppGap.gapTight),
                Text(
                  subtitulo,
                  style: AppTypography.body2.copyWith(color: texto),
                ),
                const SizedBox(height: AppGap.gapSection),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(icono, color: texto, size: 36),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// PANTALLA PARA BUSCAR Y ELEGIR UN LUGAR
class _BuscarLugar extends StatefulWidget {
  const _BuscarLugar({this.title = 'Buscar destino'});

  final String title;

  @override
  State<_BuscarLugar> createState() => _BuscarLugarState();
}

class _BuscarLugarState extends State<_BuscarLugar> {
  final _texto = TextEditingController();

  List<_Lugar> _resultados = [];
  String _consultaRealizada = '';
  String? _error;

  bool _cargando = false;
  bool _busquedaRealizada = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final consulta = _texto.text.trim();

    if (consulta.isEmpty || _cargando) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _cargando = true;
      _error = null;
      _resultados = [];
      _busquedaRealizada = true;
    });

    try {
      final lugares = await _Places.buscar(consulta);

      if (!mounted) return;

      setState(() {
        _resultados = lugares;
        _consultaRealizada = consulta;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppPadding.paddingLg),
            child: TextField(
              controller: _texto,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _buscar(),
              decoration: InputDecoration(
                hintText: 'Lugar, dirección o comuna',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  onPressed: _cargando ? null : _buscar,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _texto,
            builder: (context, value, child) {
              final direccion = value.text.trim();
              return TextButton.icon(
                onPressed: direccion.isEmpty
                    ? null
                    : () => Navigator.of(context)
                          .pop((lugar: null as _Lugar?, consulta: direccion)),
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: const Text('Usar dirección escrita'),
              );
            },
          ),
          if (_cargando) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(AppPadding.paddingLg),
              child: Text(_error!, style: AppTypography.body2),
            ),
          Expanded(
            child: !_busquedaRealizada
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppPadding.paddingXl),
                      child: Text(
                        'Escribe un lugar y presiona la lupa '
                        'del teclado o la flecha para buscar.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _resultados.isEmpty && !_cargando && _error == null
                ? const Center(child: Text('No encontramos resultados.'))
                : ListView.separated(
                    itemCount: _resultados.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final lugar = _resultados[index];

                      return ListTile(
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary500,
                        ),
                        title: Text(lugar.nombre),
                        subtitle: Text(lugar.direccion),
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pop((lugar: lugar, consulta: _consultaRealizada));
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
