import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/modelo/usuario_admin.dart';

/// Capa de datos para el módulo de Usuarios (tabla profiles).
class UsuariosServicio {
  final SupabaseClient _client;

  UsuariosServicio(this._client);

  Future<List<UsuarioAdmin>> listar({
    int pagina = 0,
    int porPagina = 20,
    String? busqueda,
    String filtro = 'todos',
    String orden = 'recientes',
  }) async {
    final filtroBusqueda = busqueda != null && busqueda.trim().isNotEmpty
        ? '%${busqueda.trim()}%'
        : '%';

    // Construir ordenamiento
    String orderColumn = 'creado_en';
    bool ascending = false;
    switch (orden) {
      case 'recientes':
        orderColumn = 'creado_en';
        ascending = false;
        break;
      case 'antiguos':
        orderColumn = 'creado_en';
        ascending = true;
        break;
      case 'nombre_az':
        orderColumn = 'nombre';
        ascending = true;
        break;
      case 'nombre_za':
        orderColumn = 'nombre';
        ascending = false;
        break;
      case 'popularidad':
        orderColumn = 'score_popularidad';
        ascending = false;
        break;
      case 'ultima_conexion':
        orderColumn = 'ultima_conexion';
        ascending = false;
        break;
    }

    var query = _client
        .from('profiles')
        .select()
        .ilike('nombre', filtroBusqueda);

    // Aplicar filtros
    switch (filtro) {
      case 'verificados':
        query = query.eq('verificado_status', true);
        break;
      case 'suspendidos':
        query = query.eq('suspendido', true);
        break;
      case 'con_foto':
        query = query.not('foto_principal', 'is', null).neq('foto_principal', '');
        break;
      case 'perfil_completo':
        query = query.eq('perfil_completado', true);
        break;
      case 'recientes':
        final hace7dias = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
        query = query.gte('creado_en', hace7dias);
        break;
    }

    final res = await query
        .order(orderColumn, ascending: ascending)
        .range(pagina * porPagina, (pagina + 1) * porPagina - 1);

    return res.map((e) => UsuarioAdmin.desdeMapa(e)).toList();
  }

  Future<UsuarioAdmin> obtener(String id) async {
    final res = await _client
        .from('profiles')
        .select()
        .eq('id', id)
        .single();
    return UsuarioAdmin.desdeMapa(res);
  }

  Future<void> actualizar(String id, Map<String, dynamic> cambios) async {
    await _client.from('profiles').update(cambios).eq('id', id);
  }

  Future<void> borrar(String id) async {
    await _client.from('profiles').delete().eq('id', id);
  }
}
