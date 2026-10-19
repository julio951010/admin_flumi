import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/modelo/reporte.dart';
import '../../core/modelo/usuario_admin.dart';

/// Capa de datos para el módulo de Reportes (tabla `reports`, la misma
/// donde flumi_app escribe los reportes de usuarios).
class ReportesServicio {
  final SupabaseClient _client;

  ReportesServicio(this._client);

  Future<List<Reporte>> listar({String? estado, int porPagina = 50}) async {
    var q = _client.from('reports').select();
    if (estado != null) q = q.eq('estado', estado);
    final res = await q
        .order('timestamp', ascending: false)
        .limit(porPagina);
    return (res as List)
        .map((e) => Reporte.desdeMapa(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cambiarEstado(dynamic id, String estado) async {
    await _client.from('reports').update({
      'estado': estado,
      'resuelto_en':
          estado == 'pendiente' ? null : DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> suspenderReportado(String reportadoId) async {
    await _client
        .from('profiles')
        .update({'suspendido': true}).eq('id', reportadoId);
  }

  Future<UsuarioAdmin> obtenerReportado(String reportadoId) async {
    final res = await _client
        .from('profiles')
        .select()
        .eq('id', reportadoId)
        .single();
    return UsuarioAdmin.desdeMapa(res);
  }
}
