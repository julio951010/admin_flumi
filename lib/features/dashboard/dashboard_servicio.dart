import 'package:supabase_flutter/supabase_flutter.dart';

/// Estadísticas agregadas del backend (RPC `estadisticas_admin`).
class DashboardStats {
  final int usuariosTotal;
  final int usuariosHoy;
  final int usuarios7d;
  final int verificados;
  final int perfilesCompletados;
  final int ocultos;
  final int enLinea;
  final int matchesTotal;
  final int mensajesTotal;
  final int mensajesHoy;
  final int likesHoy;
  final int visitasHoy;
  final int reportesPendientes;
  final int soportesPendientes;
  final int pagosPendientes;
  final int plus;
  final int premium;
  final List<SerieDia> serie7d;

  const DashboardStats({
    required this.usuariosTotal,
    required this.usuariosHoy,
    required this.usuarios7d,
    required this.verificados,
    required this.perfilesCompletados,
    required this.ocultos,
    required this.enLinea,
    required this.matchesTotal,
    required this.mensajesTotal,
    required this.mensajesHoy,
    required this.likesHoy,
    required this.visitasHoy,
    required this.reportesPendientes,
    required this.soportesPendientes,
    required this.pagosPendientes,
    required this.plus,
    required this.premium,
    required this.serie7d,
  });

  static int _i(Map<String, dynamic> m, String k) =>
      (m[k] as num?)?.toInt() ?? 0;

  factory DashboardStats.desdeMapa(Map<String, dynamic> m) {
    final subs = (m['suscripciones'] as Map<String, dynamic>?) ?? const {};
    final serie = ((m['serie_7d'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SerieDia.desdeMapa)
        .toList();
    return DashboardStats(
      usuariosTotal: _i(m, 'usuarios_total'),
      usuariosHoy: _i(m, 'usuarios_hoy'),
      usuarios7d: _i(m, 'usuarios_7d'),
      verificados: _i(m, 'verificados'),
      perfilesCompletados: _i(m, 'perfiles_completados'),
      ocultos: _i(m, 'ocultos'),
      enLinea: _i(m, 'en_linea'),
      matchesTotal: _i(m, 'matches_total'),
      mensajesTotal: _i(m, 'mensajes_total'),
      mensajesHoy: _i(m, 'mensajes_hoy'),
      likesHoy: _i(m, 'likes_hoy'),
      visitasHoy: _i(m, 'visitas_hoy'),
      reportesPendientes: _i(m, 'reportes_pendientes'),
      soportesPendientes: _i(m, 'soportes_pendientes'),
      pagosPendientes: _i(m, 'pagos_pendientes'),
      plus: _i(subs, 'plus'),
      premium: _i(subs, 'premium'),
      serie7d: serie,
    );
  }
}

class SerieDia {
  final String fecha;
  final int usuarios;
  final int mensajes;
  final int matches;

  const SerieDia({
    required this.fecha,
    required this.usuarios,
    required this.mensajes,
    required this.matches,
  });

  factory SerieDia.desdeMapa(Map<String, dynamic> m) => SerieDia(
        fecha: (m['fecha'] as String?) ?? '',
        usuarios: (m['usuarios'] as num?)?.toInt() ?? 0,
        mensajes: (m['mensajes'] as num?)?.toInt() ?? 0,
        matches: (m['matches'] as num?)?.toInt() ?? 0,
      );
}

/// Capa de datos del dashboard (una sola llamada RPC).
class DashboardServicio {
  final SupabaseClient _client;

  DashboardServicio(this._client);

  Future<DashboardStats> obtener() async {
    final res = await _client.rpc('estadisticas_admin');
    return DashboardStats.desdeMapa(
        Map<String, dynamic>.from(res as Map));
  }
}
