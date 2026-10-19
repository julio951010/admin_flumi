class UsuarioAdmin {
  final String id;
  final String email;
  final String nombre;
  final String genero;
  final String buscaGenero;
  final String ciudad;
  final String biografia;
  final String queBusca;
  final String orientacionSexual;
  final String situacionSentimental;
  final String altura;
  final String educacion;
  final String trabajo;
  final String profesion;
  final String preferenciaRelacion;
  final String bebe;
  final String fuma;
  final String hijos;
  final String personalidad;
  final String signoZodiaco;
  final String mascotas;
  final String religion;
  final String idiomas;
  final String tatuajes;
  final String fotoVerificacion;

  final int? edad;
  final int? preferenciaEdadMin;
  final int? preferenciaEdadMax;
  final int? scorePopularidad;

  final double? ubicacionLat;
  final double? ubicacionLon;

  final bool verificadoStatus;
  final bool suspendido;
  final bool isAdmin;
  final bool perfilCompletado;
  final bool ocultarEnLinea;
  final bool ocultarEdad;
  final bool ocultarPerfil;
  final bool ocultarVisitas;

  final DateTime? creadoEn;
  final DateTime? ultimaConexion;
  final DateTime? fechaNacimiento;

  final List<String> fotosUrls;
  final List<String> intereses;
  final dynamic preguntasPerfil;

  UsuarioAdmin({
    required this.id,
    this.email = '',
    this.nombre = '',
    this.genero = '',
    this.buscaGenero = '',
    this.ciudad = '',
    this.biografia = '',
    this.queBusca = '',
    this.orientacionSexual = '',
    this.situacionSentimental = '',
    this.altura = '',
    this.educacion = '',
    this.trabajo = '',
    this.profesion = '',
    this.preferenciaRelacion = '',
    this.bebe = '',
    this.fuma = '',
    this.hijos = '',
    this.personalidad = '',
    this.signoZodiaco = '',
    this.mascotas = '',
    this.religion = '',
    this.idiomas = '',
    this.tatuajes = '',
    this.fotoVerificacion = '',
    this.edad,
    this.preferenciaEdadMin,
    this.preferenciaEdadMax,
    this.scorePopularidad,
    this.ubicacionLat,
    this.ubicacionLon,
    this.verificadoStatus = false,
    this.suspendido = false,
    this.isAdmin = false,
    this.perfilCompletado = false,
    this.ocultarEnLinea = false,
    this.ocultarEdad = false,
    this.ocultarPerfil = false,
    this.ocultarVisitas = false,
    this.creadoEn,
    this.ultimaConexion,
    this.fechaNacimiento,
    this.fotosUrls = const [],
    this.intereses = const [],
    this.preguntasPerfil,
  });

  factory UsuarioAdmin.desdeMapa(Map<String, dynamic> m) {
    final fotos = m['fotos_urls'];
    final intereses = m['intereses'];
    return UsuarioAdmin(
      id: m['id'] as String,
      email: (m['email'] as String?) ?? '',
      nombre: (m['nombre'] as String?) ?? '',
      genero: (m['genero'] as String?) ?? '',
      buscaGenero: (m['busca_genero'] as String?) ?? '',
      ciudad: (m['ciudad'] as String?) ?? '',
      biografia: (m['biografia'] as String?) ?? '',
      queBusca: (m['que_busca'] as String?) ?? '',
      orientacionSexual: (m['orientacion_sexual'] as String?) ?? '',
      situacionSentimental: (m['situacion_sentimental'] as String?) ?? '',
      altura: (m['altura'] as String?) ?? '',
      educacion: (m['educacion'] as String?) ?? '',
      trabajo: (m['trabajo'] as String?) ?? '',
      profesion: (m['profesion'] as String?) ?? '',
      preferenciaRelacion: (m['preferencia_relacion'] as String?) ?? '',
      bebe: (m['bebe'] as String?) ?? '',
      fuma: (m['fuma'] as String?) ?? '',
      hijos: (m['hijos'] as String?) ?? '',
      personalidad: (m['personalidad'] as String?) ?? '',
      signoZodiaco: (m['signo_zodiaco'] as String?) ?? '',
      mascotas: (m['mascotas'] as String?) ?? '',
      religion: (m['religion'] as String?) ?? '',
      idiomas: (m['idiomas'] as String?) ?? '',
      tatuajes: (m['tatuajes'] as String?) ?? '',
      fotoVerificacion: (m['foto_verificacion'] as String?) ?? '',
      edad: m['edad'] as int?,
      preferenciaEdadMin: m['preferencia_edad_min'] as int?,
      preferenciaEdadMax: m['preferencia_edad_max'] as int?,
      scorePopularidad: m['score_popularidad'] as int?,
      ubicacionLat: (m['ubicacion_lat'] as num?)?.toDouble(),
      ubicacionLon: (m['ubicacion_lon'] as num?)?.toDouble(),
      verificadoStatus: m['verificado_status'] as bool? ?? false,
      suspendido: m['suspendido'] as bool? ?? false,
      isAdmin: m['is_admin'] as bool? ?? false,
      perfilCompletado: m['perfil_completado'] as bool? ?? false,
      ocultarEnLinea: m['ocultar_en_linea'] as bool? ?? false,
      ocultarEdad: m['ocultar_edad'] as bool? ?? false,
      ocultarPerfil: m['ocultar_perfil'] as bool? ?? false,
      ocultarVisitas: m['ocultar_visitas'] as bool? ?? false,
      creadoEn: _fecha(m['creado_en']),
      ultimaConexion: _fecha(m['ultima_conexion']),
      fechaNacimiento: _fecha(m['fecha_nacimiento']),
      fotosUrls: fotos is List
          ? List<String>.from(fotos.map((e) => e.toString()))
          : const [],
      intereses: intereses is List
          ? List<String>.from(intereses.map((e) => e.toString()))
          : const [],
      preguntasPerfil: m['preguntas_perfil'],
    );
  }

  static DateTime? _fecha(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  /// Mapa con las columnas de la base de datos (sin el id).
  Map<String, dynamic> toMap() => {
        'email': email,
        'nombre': nombre,
        'genero': genero,
        'busca_genero': buscaGenero,
        'ciudad': ciudad,
        'biografia': biografia,
        'que_busca': queBusca,
        'orientacion_sexual': orientacionSexual,
        'situacion_sentimental': situacionSentimental,
        'altura': altura,
        'educacion': educacion,
        'trabajo': trabajo,
        'profesion': profesion,
        'preferencia_relacion': preferenciaRelacion,
        'bebe': bebe,
        'fuma': fuma,
        'hijos': hijos,
        'personalidad': personalidad,
        'signo_zodiaco': signoZodiaco,
        'mascotas': mascotas,
        'religion': religion,
        'idiomas': idiomas,
        'tatuajes': tatuajes,
        'foto_verificacion': fotoVerificacion,
        'intereses': intereses,
        'fotos_urls': fotosUrls,
        'preguntas_perfil': preguntasPerfil,
        'edad': edad,
        'preferencia_edad_min': preferenciaEdadMin,
        'preferencia_edad_max': preferenciaEdadMax,
        'score_popularidad': scorePopularidad,
        'ubicacion_lat': ubicacionLat,
        'ubicacion_lon': ubicacionLon,
        'fecha_nacimiento': fechaNacimiento?.toIso8601String().split('T').first,
        'creado_en': creadoEn?.toIso8601String(),
        'ultima_conexion': ultimaConexion?.toIso8601String(),
        'verificado_status': verificadoStatus,
        'suspendido': suspendido,
        'is_admin': isAdmin,
        'perfil_completado': perfilCompletado,
        'ocultar_en_linea': ocultarEnLinea,
        'ocultar_edad': ocultarEdad,
        'ocultar_perfil': ocultarPerfil,
        'ocultar_visitas': ocultarVisitas,
      };

  String get fotoPrincipal => fotosUrls.isNotEmpty ? fotosUrls.first : '';
}
