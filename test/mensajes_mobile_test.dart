import 'package:admin_flumi/config/app_config.dart';
import 'package:admin_flumi/config/tema.dart';
import 'package:admin_flumi/core/modelo/usuario_admin.dart';
import 'package:admin_flumi/features/mensajes/mensajes_pantalla.dart';
import 'package:admin_flumi/features/mensajes/mensajes_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente sin red ni temporizadores de auth (solo para tests de layout).
SupabaseClient _clienteFalso() => SupabaseClient(
      'http://localhost',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

class _FakeMensajes extends MensajesServicio {
  _FakeMensajes() : super(_clienteFalso());

  @override
  Future<MensajesPagina> listar({
    String busqueda = '',
    String remitente = 'todos',
    int limite = 30,
    int offset = 0,
  }) async {
    var lista = _mensajes();
    if (remitente != 'todos') {
      lista = lista.where((m) => m.remitenteClave == remitente).toList();
    }
    if (busqueda.trim().isNotEmpty) {
      final q = busqueda.trim().toLowerCase();
      lista = lista
          .where((m) =>
              m.receptorNombre.toLowerCase().contains(q) ||
              m.contenido.toLowerCase().contains(q))
          .toList();
    }
    return MensajesPagina(total: lista.length, mensajes: lista);
  }

  @override
  Future<MensajesStats> stats() async => MensajesStats(
        total: 128,
        admin: 60,
        flumi: 68,
        hoy: 7,
        ultimos7d: 31,
        ultimos30d: 92,
        usuariosAlcanzados: 95,
        usuariosTotales: 240,
        serie14d: [
          for (var i = 0; i < 14; i++)
            MensajeDia(
              fecha: DateTime.now().subtract(Duration(days: 13 - i)),
              total: (i * 3) % 11,
            ),
        ],
      );

  @override
  Future<List<PlantillaMensaje>> plantillas() async => const [
        PlantillaMensaje(
          id: 'p1',
          titulo: 'Bienvenida',
          contenido: '¡Hola {nombre}! Bienvenido/a a Flumi.',
        ),
        PlantillaMensaje(
          id: 'p2',
          titulo: 'Completa tu perfil',
          contenido: 'Hola {nombre}, añade una foto para tener más matches.',
        ),
        PlantillaMensaje(
          id: 'p3',
          titulo: 'Aviso importante',
          contenido: 'Hola {nombre}, tenemos un aviso para ti.',
        ),
      ];

  @override
  Future<List<UsuarioAdmin>> buscarUsuarios(String texto,
          {int limite = 8}) async =>
      [
        UsuarioAdmin(
          id: '11111111-1111-1111-1111-111111111111',
          nombre: 'Ana María Rodríguez',
        ),
      ];

  @override
  Future<int> contarMasivo({
    required String remitente,
    required String segmento,
    required bool soloSinMensaje,
    required int limite,
  }) async =>
      42;

  @override
  Future<ResultadoMasivo> enviarMasivo({
    required String remitente,
    required String segmento,
    required String contenido,
    required bool soloSinMensaje,
    required int limite,
  }) async =>
      const ResultadoMasivo(enviados: 41, omitidos: 1, destinatarios: 42);

  @override
  Future<void> enviar({
    required String remitente,
    required String receptorId,
    required String contenido,
  }) async {}

  @override
  Future<void> reenviar(MensajeSistema mensaje) async {}

  @override
  Future<void> eliminar(String id) async {}

  @override
  Future<void> guardarPlantilla({
    String? id,
    required String titulo,
    required String contenido,
  }) async {}

  @override
  Future<void> eliminarPlantilla(String id) async {}
}

MensajesServicio fakeParaDebug() => _FakeMensajes();

List<MensajeSistema> _mensajes() {
  const nombres = [
    'María Fernanda López de la Torre',
    'Juan Pablo Pérez',
    'Ana',
    'Carlos Andrés Ramírez',
    'Lucía',
    'Usuario con un nombre larguísimo para probar elipsis',
  ];
  const contenidos = [
    '¡Hola {nombre}! Bienvenido/a a Flumi. Completa tu perfil y añade una '
        'foto para tener más oportunidades de match.',
    'Hola, hemos visto que tu perfil aún está incompleto. Añadir una foto y '
        'una descripción breve ayuda a que otras personas te conozcan mejor.',
    'Te escribimos para informarte de un aviso importante sobre tu cuenta. '
        'Revisa la aplicación cuando puedas.',
    'Mensaje corto.',
    'Hola {nombre}, ¿necesitas ayuda con el acceso a tu cuenta? Responda '
        'desde Soporte y te ayudaremos.',
    'Este es un mensaje de prueba con un contenido bastante largo para '
        'comprobar que la vista previa no desborda la tarjeta en móvil.',
  ];

  return [
    for (var i = 0; i < nombres.length; i++)
      MensajeSistema(
        id: 'msg-$i',
        emisorId:
            i.isEven ? remitenteAdministradorId : remitenteFlumiId,
        receptorId: '00000000-0000-0000-0000-00000000010$i',
        contenido: contenidos[i],
        receptorNombre: nombres[i],
        fecha: DateTime.now().subtract(Duration(hours: i * 7)),
      ),
  ];
}

Future<void> _configurarMovil(WidgetTester tester, double ancho) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(ancho, 780) * 3;
  addTearDown(tester.view.reset);
}

Widget _app({required int tab, MensajesServicio? servicio}) {
  return MaterialApp(
    theme: Tema.claro(),
    home: Scaffold(
      body: SafeArea(
        // Simula el padding del AdminShell en móvil.
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: MensajesPantalla(
            servicio: servicio ?? _FakeMensajes(),
            tabInicial: tab,
          ),
        ),
      ),
    ),
  );
}

Future<void> _asegurarVisible(WidgetTester tester, Finder finder) async {
  // La lista construye sus hijos de forma perezosa: desplazamos hasta que
  // el widget exista y luego lo dejamos dentro del viewport.
  for (var i = 0; i < 12 && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await tester.pumpAndSettle();
  }
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
  }
}

void main() {
  const anchos = <double>[320, 360, 411];

  for (final ancho in anchos) {
    final etiqueta = ancho.toInt();

    testWidgets('Historial sin overflow a $etiqueta px', (tester) async {
      await _configurarMovil(tester, ancho);
      await tester.pumpWidget(_app(tab: 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Detalle del mensaje (primera tarjeta).
      await _asegurarVisible(
        tester,
        find.text('María Fernanda López de la Torre'),
      );
      await tester.tap(find.text('María Fernanda López de la Torre').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SelectableText), findsWidgets);

      // Cerrar el bottom sheet tocando la barrera.
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      for (var i = 0; i < 3; i++) {
        await tester.drag(
          find.byType(ListView).first,
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Enviar sin overflow a $etiqueta px', (tester) async {
      await _configurarMovil(tester, ancho);
      await tester.pumpWidget(_app(tab: 1));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.enterText(
        find.byKey(const ValueKey('mensajes-destinatario')),
        'Ana',
      );
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await _asegurarVisible(
        tester,
        find.byKey(const ValueKey('mensajes-contenido')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('mensajes-contenido')),
        'Hola {nombre}, bienvenida a Flumi.',
      );
      await tester.pumpAndSettle();
      await _asegurarVisible(tester, find.textContaining('Vista previa'));
      expect(find.textContaining('Vista previa'), findsOneWidget);
      expect(tester.takeException(), isNull);

      for (var i = 0; i < 3; i++) {
        await tester.drag(
          find.byType(ListView).first,
          const Offset(0, -350),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Plantillas sin overflow a $etiqueta px', (tester) async {
      await _configurarMovil(tester, ancho);
      await tester.pumpWidget(_app(tab: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Nueva'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Masivo sin overflow a $etiqueta px', (tester) async {
      await _configurarMovil(tester, ancho);
      await tester.pumpWidget(_app(tab: 3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await _asegurarVisible(
        tester,
        find.byKey(const ValueKey('mensajes-contenido')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('mensajes-contenido')),
        'Hola {nombre}, tenemos novedades en Flumi.',
      );
      await _asegurarVisible(tester, find.text('Calcular destinatarios'));
      await tester.tap(find.text('Calcular destinatarios'));
      await tester.pumpAndSettle();
      await _asegurarVisible(tester, find.textContaining('Se enviará a 42'));
      expect(find.textContaining('Se enviará a 42'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _asegurarVisible(tester, find.textContaining('Enviar a 42'));
      expect(find.textContaining('Enviar a 42'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
