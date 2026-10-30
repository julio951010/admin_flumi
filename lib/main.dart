import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'config/tema.dart';
import 'core/auth/admin_sesion.dart';
import 'core/conectividad/conectividad_servicio.dart';
import 'features/auth/login_pantalla.dart';
import 'features/comun/admin_shell.dart';
import 'features/comun/sin_conexion_pantalla.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  final sesion = AdminSesion(Supabase.instance.client);
  await sesion.iniciarDesdeSesion();
  final conectividad = ConectividadServicio();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sesion),
        ChangeNotifierProvider.value(value: conectividad),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Flumi',
      debugShowCheckedModeBanner: false,
      theme: Tema.claro(),
      home: Consumer2<AdminSesion, ConectividadServicio>(
        builder: (context, sesion, conectividad, child) {
          // feedback inmediato sin conexión
          if (!conectividad.enLinea) {
            // si ya hay sesión, mostramos offline pero con banner en shell
            // si no hay sesión y no hay red, pantalla completa offline
            if (!sesion.autenticado) {
              return const SinConexionPantalla();
            }
          }
          return sesion.autenticado
              ? const AdminShell()
              : const LoginPantalla();
        },
      ),
    );
  }
}
