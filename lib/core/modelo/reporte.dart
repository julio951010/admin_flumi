/// Modelo del reporte de un usuario hacia otro (tabla `reports` de
/// flumi_app: detalle/creado_en se mapean a descripcion/creadoEn).
class Reporte {
  final dynamic id;
  final String reportadoId;
  final String? reportanteId;
  final String motivo;
  final String? descripcion;
  final String estado;
  final DateTime? creadoEn;
  final DateTime? resueltoEn;

  Reporte({
    required this.id,
    required this.reportadoId,
    this.reportanteId,
    required this.motivo,
    this.descripcion,
    required this.estado,
    this.creadoEn,
    this.resueltoEn,
  });

  factory Reporte.desdeMapa(Map<String, dynamic> m) {
    DateTime? parsearFecha(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    return Reporte(
      id: m['id'],
      reportadoId: m['reportado_id']?.toString() ?? '',
      reportanteId: m['reportante_id']?.toString(),
      motivo: (m['motivo'] ?? '').toString(),
      descripcion: m['detalle']?.toString(),
      estado: (m['estado'] ?? 'pendiente').toString(),
      creadoEn: parsearFecha(m['timestamp']),
      resueltoEn: parsearFecha(m['resuelto_en']),
    );
  }

  Map<String, dynamic> toMap() => {
        'reportado_id': reportadoId,
        'reportante_id': reportanteId,
        'motivo': motivo,
        'detalle': descripcion,
        'estado': estado,
        'timestamp': creadoEn?.toIso8601String(),
        'resuelto_en': resueltoEn?.toIso8601String(),
      };

  Reporte copyCon({String? estado, DateTime? resueltoEn}) => Reporte(
        id: id,
        reportadoId: reportadoId,
        reportanteId: reportanteId,
        motivo: motivo,
        descripcion: descripcion,
        estado: estado ?? this.estado,
        creadoEn: creadoEn,
        resueltoEn: resueltoEn ?? this.resueltoEn,
      );
}
