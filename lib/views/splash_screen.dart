import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import '../theme/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.home});

  final Widget home;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late Future<void> _startup;

  @override
  void initState() {
    super.initState();
    _startup = _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait<void>([
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
          .then<void>((_) {}),
      Future<void>.delayed(const Duration(milliseconds: 1200)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return widget.home;
        }

        final failed =
            snapshot.connectionState == ConnectionState.done &&
            snapshot.hasError;

        return Scaffold(
          backgroundColor: AppColors.neutral0,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/splash_logo.png',
                      width: 144,
                      height: 144,
                      semanticLabel: 'Logo de inDrive',
                    ),
                    if (failed) ...[
                      const SizedBox(height: 24),
                      const Text('No se pudo iniciar la app.'),
                      TextButton(
                        onPressed: () => setState(() {
                          _startup = _initialize();
                        }),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
