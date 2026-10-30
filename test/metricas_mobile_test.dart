import 'package:admin_flumi/config/tema.dart';
import 'package:admin_flumi/features/dashboard/dashboard_pantalla.dart';
import 'package:admin_flumi/features/dashboard/dashboard_servicio.dart';
import 'package:admin_flumi/features/metricas/metricas_pantalla.dart';
import 'package:admin_flumi/features/metricas/metricas_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicios falsos: evitan red y permiten renderizar las pantallas llenas.
class FakeMetricasPublic extends MetricasServicio {
  final MetricasInstalaciones datos;

  FakeMetricasPublic(this.datos) : super(_clienteFalso());

  @override
  Future<MetricasInstalaciones> obtener() async => datos;
}

class FakeDashboardPublic extends DashboardServicio {
  final DashboardStats datos;

  FakeDashboardPublic(this.datos) : super(_clienteFalso());

  @override
  Future<DashboardStats> obtener() async => datos;
}

/// Cliente sin red ni temporizadores de auth (solo para tests de layout).
SupabaseClient _clienteFalso() => SupabaseClient(
      'http://localhost',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

MetricasInstalaciones metricasPublic() {
  final base = DateTime(2026, 9, 30);
  String fecha(int i) {
    final d = base.add(Duration(days: i));
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  return MetricasInstalaciones(
    total: 4321,
    activasHoy: 120,
    activas7d: 1450,
    activas30d: 3210,
    nuevasHoy: 37,
    nuevas7d: 640,
    nuevas30d: 2100,
    porVersion: const [
      InstalacionesVersion(version: '1.0.1+2', total: 3980),
      InstalacionesVersion(version: '1.0.0+1', total: 300),
      InstalacionesVersion(version: 'desconocida', total: 41),
    ],
    serie30d: List.generate(
      30,
      (i) => InstalacionesDia(
        fecha: fecha(i),
        instalaciones: (i * 7) % 23,
      ),
    ),
  );
}

DashboardStats statsPublic() {
  const dias = [
    '2026-10-24',
    '2026-10-25',
    '2026-10-26',
    '2026-10-27',
    '2026-10-28',
    '2026-10-29',
    '2026-10-30',
  ];
  return DashboardStats(
    usuariosTotal: 1234,
    usuariosHoy: 12,
    usuarios7d: 88,
    verificados: 500,
    perfilesCompletados: 900,
    ocultos: 3,
    enLinea: 45,
    matchesTotal: 3210,
    mensajesTotal: 98765,
    mensajesHoy: 432,
    likesHoy: 210,
    visitasHoy: 100,
    reportesPendientes: 2,
    soportesPendientes: 1,
    pagosPendientes: 3,
    plus: 10,
    premium: 5,
    serie7d: [
      for (var i = 0; i < dias.length; i++)
        SerieDia(
          fecha: dias[i],
          usuarios: i * 3,
          mensajes: i * 10,
          matches: i,
        ),
    ],
  );
}

Future<void> _configurarMovil(WidgetTester tester, double ancho) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(ancho, 780) * 3;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home) => MaterialApp(
      theme: Tema.claro(),
      // Simula el padding del AdminShell en móvil (16 px por lado).
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: home),
      ),
    );

void main() {
  for (final ancho in <double>[320, 360, 411]) {
    testWidgets('MÃ©tricas sin overflow a ${ancho.toInt()} px', (tester) async {
      await _configurarMovil(tester, ancho);

      await tester.pumpWidget(
        _app(
          MetricasPantalla(
            servicioMetricas: FakeMetricasPublic(metricasPublic()),
            servicioDashboard: FakeDashboardPublic(statsPublic()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Recorrer la pÃ¡gina para forzar el layout de todas las secciones.
      for (var i = 0; i < 4; i++) {
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Dashboard sin overflow a ${ancho.toInt()} px', (tester) async {
      await _configurarMovil(tester, ancho);

      await tester.pumpWidget(
        _app(
          DashboardPantalla(
            servicio: FakeDashboardPublic(statsPublic()),
            servicioMetricas: FakeMetricasPublic(metricasPublic()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      for (var i = 0; i < 4; i++) {
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
