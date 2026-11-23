import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/theme.dart';
import 'local_profiles.dart';
import 'ride_activity.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();

  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _ciudad = TextEditingController();

  String? _fotoUrl;
  String? _errorFoto;

  bool _cargando = true;
  bool _guardando = false;
  bool _subiendoFoto = false;
  bool _errorCarga = false;
  bool _cambiandoPerfil = false;
  String _perfilActivo = LocalProfiles.principal;

  DocumentReference<Map<String, dynamic>> get _perfil {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      throw StateError('No hay una sesión activa');
    }

    return FirebaseFirestore.instance.collection('users').doc(usuario.uid);
  }

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _correo.dispose();
    _telefono.dispose();
    _ciudad.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargando = true;
      _errorCarga = false;
    });

    try {
      final activo = await LocalProfiles.activeId();
      final alternativo = activo == LocalProfiles.alternate;
      final datos = alternativo
          ? await LocalProfiles.readAlternate()
          : (await _perfil.get()).data() ?? {};

      if (!mounted) return;

      final usuario = FirebaseAuth.instance.currentUser;

      _nombre.text = datos['nombre'] as String? ?? '';
      _apellido.text = datos['apellido'] as String? ?? '';
      _correo.text =
          datos['correo'] as String? ??
          (alternativo ? '' : usuario?.email ?? '');
      _telefono.text = datos['telefono'] as String? ?? '';
      _ciudad.text = datos['ciudad'] as String? ?? '';

      setState(() {
        _perfilActivo = activo;
        _errorFoto = null;
        _fotoUrl = datos['fotoUrl'] as String?;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorCarga = true;
      });

      _mensaje('No se pudo cargar el perfil.');
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _cambiarFoto() async {
    if (_subiendoFoto || _guardando || _cambiandoPerfil) return;
    final activo = _perfilActivo;
    if (activo == LocalProfiles.alternate) {
      _mensaje('El perfil de demostración usa el avatar predeterminado.');
      return;
    }

    try {
      final imagen = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (imagen == null || !mounted || _perfilActivo != activo) return;

      setState(() {
        _subiendoFoto = true;
        _errorFoto = null;
      });

      final usuario = FirebaseAuth.instance.currentUser;

      if (usuario == null) {
        throw StateError('No hay sesión');
      }

      final bytes = await imagen.readAsBytes();
      final extension = imagen.name.contains('.')
          ? imagen.name.split('.').last.toLowerCase()
          : 'jpg';

      final referencia = FirebaseStorage.instance.ref(
        'perfiles/${usuario.uid}/'
        '${DateTime.now().millisecondsSinceEpoch}.$extension',
      );

      await referencia.putData(
        bytes,
        SettableMetadata(
          contentType:
              imagen.mimeType ??
              (extension == 'png' ? 'image/png' : 'image/jpeg'),
        ),
      );

      final url = await referencia.getDownloadURL();

      await _perfil.set({'fotoUrl': url}, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        _fotoUrl = url;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorFoto = 'Tu foto de perfil no se cargó; intenta de nuevo.';
      });
    } finally {
      if (mounted) {
        setState(() => _subiendoFoto = false);
      }
    }
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final datos = {
        'nombre': _nombre.text.trim(),
        'apellido': _apellido.text.trim(),
        'correo': _correo.text.trim(),
        'telefono': _telefono.text.trim(),
        'codigoPais': '+56',
        'ciudad': _ciudad.text.trim(),
      };
      if (_perfilActivo == LocalProfiles.alternate) {
        await LocalProfiles.saveAlternate(datos);
      } else {
        await _perfil.set({
          ...datos,
          'actualizadoEn': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      _mensaje('Perfil guardado');
    } catch (_) {
      _mensaje(
        'No se pudo guardar. Revisa la conexión '
        'y los permisos de Firebase.',
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  Future<void> _cambiarPerfil() async {
    setState(() => _cambiandoPerfil = true);
    try {
      final alternateName = await LocalProfiles.alternateName();
      if (!mounted) return;
      final selection = await showDialog<String>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: const Text('Cambiar perfil'),
          children: [
            SimpleDialogOption(
              onPressed: _perfilActivo == LocalProfiles.principal
                  ? null
                  : () => Navigator.pop(dialogContext, LocalProfiles.principal),
              child: const Text('Perfil principal'),
            ),
            SimpleDialogOption(
              onPressed: _perfilActivo == LocalProfiles.alternate
                  ? null
                  : () => Navigator.pop(dialogContext, LocalProfiles.alternate),
              child: Text(alternateName ?? 'Crear otro perfil'),
            ),
          ],
        ),
      );
      if (!mounted || selection == null) return;
      String? newName;
      if (selection == LocalProfiles.alternate && alternateName == null) {
        var enteredName = '';
        newName = await showDialog<String>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Crear otro perfil'),
            content: TextField(
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre'),
              onChanged: (value) => enteredName = value.trim(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (enteredName.isNotEmpty) {
                    Navigator.pop(dialogContext, enteredName);
                  }
                },
                child: const Text('Crear perfil'),
              ),
            ],
          ),
        );
        if (!mounted || newName == null) return;
      }
      await LocalProfiles.switchTo(selection, newName: newName);
      if (!mounted) return;
      await _cargarPerfil();
    } catch (_) {
      _mensaje('No se pudo cambiar de perfil. Inténtalo otra vez.');
    } finally {
      if (mounted) setState(() => _cambiandoPerfil = false);
    }
  }

  InputDecoration _decoracion(String? hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.primary50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.all(AppPadding.paddingLg),
    );
  }

  Widget _campo({
    required String etiqueta,
    required TextEditingController controller,
    TextInputType teclado = TextInputType.text,
    String? Function(String?)? validar,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppPadding.paddingMd,
            bottom: AppGap.gapRelated,
          ),
          child: Text(
            etiqueta,
            style: AppTypography.caption.copyWith(color: AppColors.neutral500),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: teclado,
          enabled: !_guardando,
          validator: validar,
          decoration: _decoracion(hint),
          style: AppTypography.body2,
        ),
        const SizedBox(height: AppGap.gapComponent),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral0,
      appBar: AppBar(
        backgroundColor: AppColors.neutral0,
        title: const Text(
          'Configuración del perfil',
          style: AppTypography.body1,
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _errorCarga
          ? Center(
              child: ElevatedButton(
                onPressed: _cargarPerfil,
                child: const Text('Reintentar cargar perfil'),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppPadding.paddingXl),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // FOTO
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width:
                                    AppSpacing.spacing1100 +
                                    AppSpacing.spacing700,
                                height:
                                    AppSpacing.spacing1100 +
                                    AppSpacing.spacing700,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.neutral100,
                                  border: Border.all(
                                    color: _errorFoto == null
                                        ? AppColors.neutral200
                                        : AppColors.error500,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _fotoUrl == null
                                    ? const Icon(
                                        Icons.person_outline,
                                        color: AppColors.neutral400,
                                      )
                                    : Image.network(
                                        _fotoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, error, stack) {
                                          return const Icon(
                                            Icons.broken_image_outlined,
                                            color: AppColors.error500,
                                          );
                                        },
                                      ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Material(
                                  color: AppColors.neutral0,
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    tooltip: 'Cambiar foto',
                                    onPressed: _subiendoFoto || _guardando
                                        ? null
                                        : _cambiarFoto,
                                    icon: const Icon(Icons.refresh),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_subiendoFoto)
                          const Padding(
                            padding: EdgeInsets.all(AppPadding.paddingLg),
                            child: LinearProgressIndicator(),
                          ),

                        if (_errorFoto != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppGap.gapComponent,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(
                                AppPadding.paddingMd,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error50,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.radiusLg,
                                ),
                                border: Border.all(color: AppColors.error500),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _errorFoto!,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.error600,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.error500,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: AppGap.gapSection),

                        _campo(
                          etiqueta: 'Nombre de usuario',
                          controller: _nombre,
                          validar: (valor) {
                            return valor == null || valor.trim().isEmpty
                                ? 'Ingresa tu nombre'
                                : null;
                          },
                        ),

                        _campo(etiqueta: 'Apellido', controller: _apellido),

                        _campo(
                          etiqueta: 'Correo electrónico',
                          controller: _correo,
                          teclado: TextInputType.emailAddress,
                          validar: (valor) {
                            final correo = valor?.trim() ?? '';

                            if (correo.isEmpty) return null;

                            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(correo)
                                ? null
                                : 'Ingresa un correo válido';
                          },
                        ),

                        Text(
                          'Número telefónico',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.neutral500,
                          ),
                        ),

                        const SizedBox(height: AppGap.gapRelated),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(
                                AppPadding.paddingLg,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary50,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.radiusLg,
                                ),
                              ),
                              child: const Text('+56'),
                            ),
                            const SizedBox(width: AppGap.gapRelated),
                            Expanded(
                              child: TextFormField(
                                controller: _telefono,
                                enabled: !_guardando,
                                keyboardType: TextInputType.phone,
                                decoration: _decoracion('9 1234 5678'),
                                validator: (valor) {
                                  final numero = (valor ?? '').replaceAll(
                                    RegExp(r'[\s()-]'),
                                    '',
                                  );

                                  if (numero.isEmpty) {
                                    return null;
                                  }

                                  return RegExp(r'^\d{9}$').hasMatch(numero)
                                      ? null
                                      : 'Ingresa 9 dígitos';
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppGap.gapComponent),

                        _campo(
                          etiqueta: 'Ciudad',
                          controller: _ciudad,
                          hint: 'Ingresa tu ciudad',
                        ),

                        const SizedBox(height: AppGap.gapGroup),

                        ElevatedButton(
                          onPressed:
                              _guardando || _subiendoFoto || _cambiandoPerfil
                              ? null
                              : _guardar,
                          child: Text(_guardando ? 'GUARDANDO…' : 'GUARDAR'),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              _guardando || _subiendoFoto || _cambiandoPerfil
                              ? null
                              : _cambiarPerfil,
                          icon: const Icon(Icons.switch_account_outlined),
                          label: const Text('Cambiar perfil'),
                        ),

                        const SizedBox(height: AppGap.gapComponent),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        backgroundColor: AppColors.neutral0,
        indicatorColor: AppColors.primary50,
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 1 && !_cambiandoPerfil) {
            Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const RideActivityScreen()),
            );
          } else if (index == 2) {
            _mensaje('Esta sección todavía está pendiente.');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Activity'),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(
              Icons.person_outline,
              color: AppColors.primary500,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
