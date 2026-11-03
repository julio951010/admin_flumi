import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../core/modelo/usuario_admin.dart';
import '../usuarios/usuarios_servicio.dart';

/// Remitente seleccionado en la UI: 'admin' o 'flumi'.
const String remitenteAdminClave = 'admin';
const String remitenteFlumiClave = 'flumi';

String idDeRemitente(String clave) =>
    clave == remitenteFlumiClave ? remitenteFlumiId : remitenteAdministradorId;

String claveDeRemitente(String id) =>
    id == remitenteFlumiId ? remitenteFlumiClave : remitenteAdminClave;

String nombreDeRemitente(String clave) =>
    clave == remitenteFlumiClave ? 'Flumi' : 'Administrador';

/// Un mensaje enviado desde Administrador o Flumi.
class MensajeSistema {
  final String id;
  final String emisorId;
  final String receptorId;
  final String contenido;
  final String estadoEnvio;
  final String receptorNombre;
  final String receptorFoto;
  final DateTime? fecha;

  const MensajeSistema({
    required this.id,
    required this.emisorId,
    required this.receptorId,
    required this.contenido,
    this.estadoEnvio = 'enviado',
    this.receptorNombre = '',
    this.receptorFoto = '',
    this.fecha,
  });

  bool get esAdministrador => emisorId == remitenteAdministradorId;

  String get remitenteClave =>
      esAdministrador ? remitenteAdminClave : remitenteFlumiClave;

  String get remitenteNombre =>
      esAdministrador ? 'Administrador' : 'Flumi';

  factory MensajeSistema.desdeMapa(Map<String, dynamic> m) {
    return MensajeSistema(
      id: (m['id'] ?? '').toString(),
      emisorId: (m['emisor_id'] ?? '').toString(),
      receptorId: (m['receptor_id'] ?? '').toString(),
      contenido: (m['contenido'] ?? '').toString(),
      estadoEnvio: (m['estado_envio'] ?? 'enviado').toString(),
      receptorNombre: (m['receptor_nombre'] ?? 'Usuario').toString(),
      receptorFoto: (m['receptor_foto'] ?? '').toString(),
      fecha: _parseFecha(m['fecha']),
    );
  }
}

/// Página de resultados del historial.
class MensajesPagina {
  final int total;
  final List<MensajeSistema> mensajes;

  const MensajesPagina({required this.total, required this.mensajes});
}

/// Un punto de la serie diaria de envíos.
class MensajeDia {
  final DateTime fecha;
  final int total;

  const MensajeDia({required this.fecha, required this.total});
}

/// Métricas agregadas de los envíos del sistema.
class MensajesStats {
  final int total;
  final int admin;
  final int flumi;
  final int hoy;
  final int ultimos7d;
  final int ultimos30d;
  final int usuariosAlcanzados;
  final int usuariosTotales;
  final List<MensajeDia> serie14d;

  const MensajesStats({
    this.total = 0,
    this.admin = 0,
    this.flumi = 0,
    this.hoy = 0,
    this.ultimos7d = 0,
    this.ultimos30d = 0,
    this.usuariosAlcanzados = 0,
    this.usuariosTotales = 0,
    this.serie14d = const [],
  });

  /// Usuarios activos que todavía no han recibido ningún mensaje del sistema.
  int get usuariosSinMensaje {
    final pendientes = usuariosTotales - usuariosAlcanzados;
    return pendientes < 0 ? 0 : pendientes;
  }

  factory MensajesStats.desdeMapa(Map<String, dynamic> m) {
    final serie = m['serie_14d'];
    return MensajesStats(
      total: _int(m['total']),
      admin: _int(m['admin']),
      flumi: _int(m['flumi']),
      hoy: _int(m['hoy']),
      ultimos7d: _int(m['ultimos_7d']),
      ultimos30d: _int(m['ultimos_30d']),
      usuariosAlcanzados: _int(m['usuarios_alcanzados']),
      usuariosTotales: _int(m['usuarios_totales']),
      serie14d: serie is List
          ? serie
              .whereType<Map>()
              .map((e) => MensajeDia(
                    fecha: _parseFecha(e['fecha']) ?? DateTime.now(),
                    total: _int(e['total']),
                  ))
              .toList()
          : const [],
    );
  }
}

/// Plantilla reutilizable de mensaje.
class PlantillaMensaje {
  final String id;
  final String titulo;
  final String contenido;

  const PlantillaMensaje({
    required this.id,
    required this.titulo,
    required this.contenido,
  });

  factory PlantillaMensaje.desdeMapa(Map<String, dynamic> m) => PlantillaMensaje(
        id: (m['id'] ?? '').toString(),
        titulo: (m['titulo'] ?? '').toString(),
        contenido: (m['contenido'] ?? '').toString(),
      );
}

/// Resultado de un envío masivo.
class ResultadoMasivo {
  final int enviados;
  final int omitidos;
  final int destinatarios;

  const ResultadoMasivo({
    this.enviados = 0,
    this.omitidos = 0,
    this.destinatarios = 0,
  });

  factory ResultadoMasivo.desdeMapa(Map<String, dynamic> m) => ResultadoMasivo(
        enviados: _int(m['enviados']),
        omitidos: _int(m['omitidos']),
        destinatarios: _int(m['destinatarios']),
      );
}

/// Segmentos disponibles para el envío masivo.
class SegmentoMasivo {
  final String clave;
  final String etiqueta;

  const SegmentoMasivo(this.clave, this.etiqueta);

  static const List<SegmentoMasivo> todos = [
    SegmentoMasivo('todos', 'Todos los usuarios activos'),
    SegmentoMasivo('verificados', 'Verificados'),
    SegmentoMasivo('no_verificados', 'No verificados'),
    SegmentoMasivo('perfil_completo', 'Perfil completo'),
    SegmentoMasivo('perfil_incompleto', 'Perfil incompleto'),
    SegmentoMasivo('sin_foto', 'Sin foto de perfil'),
    SegmentoMasivo('activos_7d', 'Activos en los últimos 7 días'),
    SegmentoMasivo('inactivos_30d', 'Inactivos más de 30 días'),
  ];
}

/// Capa de datos para el módulo de Mensajes (Administrador / Flumi).
class MensajesServicio {
  final SupabaseClient _client;
  final UsuariosServicio _usuarios;

  MensajesServicio(this._client, {UsuariosServicio? usuarios})
      : _usuarios = usuarios ?? UsuariosServicio(_client);

  Future<MensajesPagina> listar({
    String busqueda = '',
    String remitente = 'todos',
    int limite = 30,
    int offset = 0,
  }) async {
    final res = await _client.rpc('mensajes_sistema_listar', params: {
      'p_busqueda': busqueda.trim(),
      'p_remitente': remitente == 'todos' ? null : idDeRemitente(remitente),
      'p_limite': limite,
      'p_offset': offset,
    });

    final mapa = res is Map
        ? Map<String, dynamic>.from(res)
        : <String, dynamic>{'total': 0, 'mensajes': const []};
    final lista = mapa['mensajes'];
    return MensajesPagina(
      total: _int(mapa['total']),
      mensajes: lista is List
          ? lista
              .whereType<Map>()
              .map((e) => MensajeSistema.desdeMapa(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
    );
  }

  Future<MensajesStats> stats() async {
    final res = await _client.rpc('mensajes_sistema_stats');
    return MensajesStats.desdeMapa(
      res is Map ? Map<String, dynamic>.from(res) : const {},
    );
  }

  Future<void> eliminar(String id) async {
    await _client.rpc('mensajes_sistema_eliminar', params: {'p_id': id});
  }

  Future<void> enviar({
    required String remitente,
    required String receptorId,
    required String contenido,
  }) async {
    await _client.rpc('enviar_mensaje_admin', params: {
      'p_emisor': idDeRemitente(remitente),
      'p_receptor': receptorId,
      'p_contenido': contenido.trim(),
    });
  }

  /// Reenvía un mensaje ya enviado, conservando su remitente original.
  Future<void> reenviar(MensajeSistema mensaje) => enviar(
        remitente: mensaje.remitenteClave,
        receptorId: mensaje.receptorId,
        contenido: mensaje.contenido,
      );

  Future<List<UsuarioAdmin>> buscarUsuarios(String texto,
      {int limite = 8}) async {
    final query = texto.trim();
    if (query.isEmpty) return const [];

    // UUID exacto: búsqueda directa.
    if (query.length == 36 && query.contains('-')) {
      try {
        return [await _usuarios.obtener(query)];
      } catch (_) {
        return const [];
      }
    }

    return _usuarios.listar(busqueda: query, porPagina: limite);
  }

  Future<List<PlantillaMensaje>> plantillas() async {
    final res = await _client
        .from('mensajes_plantillas')
        .select('id,titulo,contenido')
        .order('titulo');
    return (res as List)
        .map((e) => PlantillaMensaje.desdeMapa(
              Map<String, dynamic>.from(e),
            ))
        .toList();
  }

  Future<void> guardarPlantilla({
    String? id,
    required String titulo,
    required String contenido,
  }) async {
    final datos = {
      'titulo': titulo.trim(),
      'contenido': contenido.trim(),
      'actualizado_en': DateTime.now().toIso8601String(),
    };
    if (id == null) {
      await _client.from('mensajes_plantillas').insert(datos);
    } else {
      await _client.from('mensajes_plantillas').update(datos).eq('id', id);
    }
  }

  Future<void> eliminarPlantilla(String id) async {
    await _client.from('mensajes_plantillas').delete().eq('id', id);
  }

  Future<int> contarMasivo({
    required String remitente,
    required String segmento,
    required bool soloSinMensaje,
    required int limite,
  }) async {
    final res = await _client.rpc('mensajes_masivo_contar', params: {
      'p_emisor': idDeRemitente(remitente),
      'p_segmento': segmento,
      'p_solo_sin_mensaje': soloSinMensaje,
      'p_limite': limite,
    });
    return _int(res);
  }

  Future<ResultadoMasivo> enviarMasivo({
    required String remitente,
    required String segmento,
    required String contenido,
    required bool soloSinMensaje,
    required int limite,
  }) async {
    final res = await _client.rpc('enviar_mensaje_masivo', params: {
      'p_emisor': idDeRemitente(remitente),
      'p_segmento': segmento,
      'p_contenido': contenido.trim(),
      'p_solo_sin_mensaje': soloSinMensaje,
      'p_limite': limite,
    });
    return ResultadoMasivo.desdeMapa(
      res is Map ? Map<String, dynamic>.from(res) : const {},
    );
  }
}

DateTime? _parseFecha(dynamic valor) {
  if (valor == null) return null;
  if (valor is DateTime) return valor.toLocal();
  return DateTime.tryParse(valor.toString())?.toLocal();
}

int _int(dynamic valor) {
  if (valor is int) return valor;
  if (valor is num) return valor.toInt();
  if (valor is String) return int.tryParse(valor) ?? 0;
  return 0;
}
