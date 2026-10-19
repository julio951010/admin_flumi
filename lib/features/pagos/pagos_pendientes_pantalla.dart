import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PagosPendientesPantalla extends StatefulWidget {
  const PagosPendientesPantalla({super.key});
  @override
  State<PagosPendientesPantalla> createState() => _PagosPendientesPantallaState();
}

class _PagosPendientesPantallaState extends State<PagosPendientesPantalla> {
  List<Map<String, dynamic>> _pagos = [];
  bool _cargando = true;
  String? _error;
  RealtimeChannel? _chan;

  String _filtro = 'pendiente'; // pendiente | todos

  @override
  void initState() {
    super.initState();
    _cargar();
    _suscribirRealtime();
  }

  @override
  void dispose() {
    if (_chan != null) Supabase.instance.client.removeChannel(_chan!);
    super.dispose();
  }

  void _suscribirRealtime() {
    try {
      _chan = Supabase.instance.client.channel('pagos-admin').onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'pagos', callback: (_) => _cargar()).subscribe();
    } catch (_) {}
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      var q = Supabase.instance.client.from('pagos').select('*, profiles!pagos_usuario_id_fkey(nombre)').order('creado_en', ascending: false).limit(100);
      if (_filtro == 'pendiente') q = Supabase.instance.client.from('pagos').select('*, profiles!pagos_usuario_id_fkey(nombre)').eq('estado', 'pendiente').order('creado_en', ascending: false).limit(100);
      final res = await q;
      setState(() { _pagos = List<Map<String, dynamic>>.from(res as List); _cargando = false; });
    } catch (e) {
      setState(() { _error = 'Error: $e'; _cargando = false; });
    }
  }

  Future<void> _verificar(String id, String estado, {String? motivo}) async {
    try {
      final res = await Supabase.instance.client.rpc('verificar_pago', params: {'p_pago_id': id, 'p_estado': estado, if (motivo != null) 'p_motivo': motivo});
      if (res is Map && res['ok'] != true) throw res['error'] ?? 'Error';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pago $estado'), backgroundColor: estado == 'aprobado' ? Colors.green : Colors.orange));
      await _cargar();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _rechazarConMotivo(Map<String, dynamic> pago) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Rechazar pago'), content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Motivo (se notifica al usuario)', hintText: 'Ej: Nro. no coincide con monto'), maxLines: 3), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Rechazar'))]));
    if (ok == true) await _verificar(pago['id'] as String, 'rechazado', motivo: ctrl.text.trim().isEmpty ? 'Pago rechazado. Verifica el Nro.' : ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagos pendientes'),
        actions: [
          DropdownButton<String>(value: _filtro, underline: const SizedBox(), items: const [DropdownMenuItem(value: 'pendiente', child: Text('Pendientes')), DropdownMenuItem(value: 'todos', child: Text('Todos'))], onChanged: (v) => setState(() { _filtro = v!; _cargar(); })),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: _cargar, child: const Text('Reintentar'))])))
              : _pagos.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]), const SizedBox(height: 12), Text(_filtro == 'pendiente' ? 'Sin pagos pendientes' : 'Sin pagos', style: TextStyle(color: Colors.grey[600]))]))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _pagos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final p = _pagos[i];
                        final estado = (p['estado'] as String?) ?? 'pendiente';
                        final esPendiente = estado == 'pendiente';
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _colorEstado(estado).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)), child: Text(estado.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _colorEstado(estado)))),
                                  const Spacer(),
                                  Text(_fmtFecha(p['creado_en']), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                ]),
                                const SizedBox(height: 10),
                                Text('${p['plan']} · ${p['dias']} días · ${p['monto']} CUP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text('Usuario: ${p['profiles'] != null ? (p['profiles']['nombre'] ?? p['usuario_id'].toString().substring(0, 8)) : p['usuario_id'].toString().substring(0, 8)}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                const SizedBox(height: 8),
                                _fila('Método', (p['metodo'] as String?) == 'transfermovil' ? 'Transfermóvil' : 'EnZona'),
                                _fila('Tarjeta', (p['tarjeta_destino'] as String?) ?? '-'),
                                _fila('Móvil', (p['movil_confirmar'] as String?) ?? '-'),
                                _fila('Nro. Transacción', (p['nro_transaccion'] as String?) ?? '-', mono: true),
                                if (p['motivo_rechazo'] != null) _fila('Motivo', p['motivo_rechazo'] as String),
                                const SizedBox(height: 12),
                                if (esPendiente)
                                  Row(children: [
                                    Expanded(child: OutlinedButton.icon(onPressed: () => _rechazarConMotivo(p), icon: const Icon(Icons.close, size: 16), label: const Text('Rechazar'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red))),
                                    const SizedBox(width: 10),
                                    Expanded(child: FilledButton.icon(onPressed: () => _verificar(p['id'] as String, 'aprobado'), icon: const Icon(Icons.check, size: 16), label: const Text('Aprobar'), style: FilledButton.styleFrom(backgroundColor: Colors.green))),
                                  ])
                                else
                                  Row(children: [
                                    Icon(_iconEstado(estado), size: 16, color: _colorEstado(estado)),
                                    const SizedBox(width: 6),
                                    Text('Verificado: ${p['verificado_en'] != null ? _fmtFecha(p['verificado_en']) : '-'}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                  ]),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _fila(String l, String v, {bool mono = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [Text('$l: ', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)), Expanded(child: Text(v, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: mono ? 'monospace' : null)))]),
      );

  Color _colorEstado(String e) => switch (e) { 'aprobado' => Colors.green, 'rechazado' => Colors.red, _ => Colors.orange };
  IconData _iconEstado(String e) => switch (e) { 'aprobado' => Icons.check_circle, 'rechazado' => Icons.cancel, _ => Icons.schedule };
  String _fmtFecha(dynamic v) {
    try { final d = DateTime.parse(v.toString()); return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}'; } catch (_) { return v.toString(); }
  }
}
