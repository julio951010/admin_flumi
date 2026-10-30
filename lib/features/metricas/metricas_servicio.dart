import 'package:supabase_flutter/supabase_flutter.dart';

/// Instalaciones de una versión concreta.
class InstalacionesVersion {
  final String version;
  final int total;

  const InstalacionesVersion({required this.version, required this.total});

  factory InstalacionesVersion.desdeMapa(Map<String, dynamic> m) =>
      InstalacionesVersion(
        version: (m['version'] as String?) ?? 'desconocida',
        total: (m['total'] as num?)?.toInt() ?? 0,
      );
}

/// Instalaciones nuevas en un día.
class InstalacionesDia {
  final String fecha;
  final int instalaciones;

  const InstalacionesDia({
    required this.fecha,
    required this.instalaciones,
  });

  factory InstalacionesDia.desdeMapa(Map<String, dynamic> m) =>
      InstalacionesDia(
        fecha: (m['fecha'] as String?) ?? '',
        instalaciones: (m['instalaciones'] as num?)?.toInt() ?? 0,
      );
}

/// Resultado de la RPC `estadisticas_instalaciones`.
class MetricasInstalaciones {
  final int total;
  final int activasHoy;
  final int activas7d;
  final int activas30d;
  final int nuevasHoy;
  final int nuevas7d;
  final int nuevas30d;
  final List<InstalacionesVersion> porVersion;
  final List<InstalacionesDia> serie30d;

  const MetricasInstalaciones({
    required this.total,
    required this.activasHoy,
    required this.activas7d,
    required this.activas30d,
    required this.nuevasHoy,
    required this.nuevas7d,
    required this.nuevas30d,
    required this.porVersion,
    required this.serie30d,
  });

  static int _i(Map<String, dynamic> m, String k) =>
      (m[k] as num?)?.toInt() ?? 0;

  factory MetricasInstalaciones.desdeMapa(Map<String, dynamic> m) {
    final versiones = ((m['por_version'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(InstalacionesVersion.desdeMapa)
        .toList();
    final serie = ((m['serie_30d'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(InstalacionesDia.desdeMapa)
        .toList();
    return MetricasInstalaciones(
      total: _i(m, 'total'),
      activasHoy: _i(m, 'activas_hoy'),
      activas7d: _i(m, 'activas_7d'),
      activas30d: _i(m, 'activas_30d'),
      nuevasHoy: _i(m, 'nuevas_hoy'),
      nuevas7d: _i(m, 'nuevas_7d'),
      nuevas30d: _i(m, 'nuevas_30d'),
      porVersion: versiones,
      serie30d: serie,
    );
  }
}

/// Capa de datos de las métricas de instalación.
class MetricasServicio {
  final SupabaseClient _client;

  MetricasServicio(this._client);

  Future<MetricasInstalaciones> obtener() async {
    final res = await _client.rpc('estadisticas_instalaciones');
    return MetricasInstalaciones.desdeMapa(
      Map<String, dynamic>.from(res as Map),
    );
  }

  /// Devuelve `null` si la migración aún no está aplicada o falla la red,
  /// para no romper el dashboard.
  Future<MetricasInstalaciones?> obtenerOpcional() async {
    try {
      return await obtener();
    } catch (_) {
      return null;
    }
  }
}
