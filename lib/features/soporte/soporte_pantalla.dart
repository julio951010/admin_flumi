import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/tema.dart';

class SoportePantalla extends StatefulWidget {
  const SoportePantalla({super.key});
  @override
  State<SoportePantalla> createState() => _SoportePantallaState();
}

class _ConversacionSoporte {
  final String usuarioId;
  final String nombre;
  final String ultimoMensaje;
  final DateTime ultimoEn;
  final int pendientes;

  const _ConversacionSoporte({
    required this.usuarioId,
    required this.nombre,
    required this.ultimoMensaje,
    required this.ultimoEn,
    required this.pendientes,
  });
}

class _SoportePantallaState extends State<SoportePantalla> {
  List<_ConversacionSoporte> _conversaciones = [];
  bool _cargando = true;
  String? _error;
  RealtimeChannel? _chan;
  bool _soloPendientes = true;

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
      _chan = Supabase.instance.client
          .channel('soporte-admin')
          .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'soporte_mensajes',
              callback: (_) => _cargar())
          .subscribe();
    } catch (_) {}
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final res = await Supabase.instance.client
          .from('soporte_mensajes')
          .select('usuario_id,mensaje,respondido,creado_en,profiles!soporte_mensajes_usuario_id_fkey(nombre)')
          .order('creado_en', ascending: false)
          .limit(500);
      final porUsuario = <String, _ConversacionSoporte>{};
      for (final r in (res as List).cast<Map<String, dynamic>>()) {
        final uid = (r['usuario_id'] as String?) ?? '';
        if (uid.isEmpty || porUsuario.containsKey(uid)) {
          if (uid.isNotEmpty && porUsuario.containsKey(uid) && r['respondido'] == false) {
            final actual = porUsuario[uid]!;
            porUsuario[uid] = _ConversacionSoporte(
              usuarioId: actual.usuarioId,
              nombre: actual.nombre,
              ultimoMensaje: actual.ultimoMensaje,
              ultimoEn: actual.ultimoEn,
              pendientes: actual.pendientes + 1,
            );
          }
          continue;
        }
        final perfil = r['profiles'] as Map<String, dynamic>?;
        porUsuario[uid] = _ConversacionSoporte(
          usuarioId: uid,
          nombre: (perfil?['nombre'] as String?) ?? uid.substring(0, 8),
          ultimoMensaje: (r['mensaje'] as String?) ?? '',
          ultimoEn: DateTime.tryParse((r['creado_en'] as String?) ?? '') ?? DateTime.now(),
          pendientes: r['respondido'] == false ? 1 : 0,
        );
      }
      var lista = porUsuario.values.toList();
      if (_soloPendientes) {
        lista = lista.where((c) => c.pendientes > 0).toList();
      }
      if (mounted) setState(() { _conversaciones = lista; _cargando = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soporte'),
        actions: [
          Row(
            children: [
              const Text('Pendientes', style: TextStyle(fontSize: 13)),
              Switch(
                value: _soloPendientes,
                onChanged: (v) => setState(() { _soloPendientes = v; _cargar(); }),
                activeThumbColor: Tema.marca,
              ),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 48), const SizedBox(height: 12), Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: _cargar, child: const Text('Reintentar'))])))
              : _conversaciones.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.green[300]), const SizedBox(height: 12), Text(_soloPendientes ? 'Sin mensajes pendientes' : 'Sin mensajes de soporte', style: TextStyle(color: Colors.grey[600]))]))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _conversaciones.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final c = _conversaciones[i];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Tema.marca.withValues(alpha: 0.12),
                              child: Text(c.nombre.isNotEmpty ? c.nombre[0].toUpperCase() : '?', style: TextStyle(color: Tema.marca, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(c.ultimoMensaje, maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: c.pendientes > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(20)),
                                    child: Text('${c.pendientes}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF6C00))),
                                  )
                                : const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => HiloSoportePage(conversacion: c)),
                              );
                              _cargar();
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}

class HiloSoportePage extends StatefulWidget {
  final _ConversacionSoporte conversacion;
  const HiloSoportePage({super.key, required this.conversacion});

  @override
  State<HiloSoportePage> createState() => _HiloSoportePageState();
}

class _HiloSoportePageState extends State<HiloSoportePage> {
  List<Map<String, dynamic>> _tickets = [];
  bool _cargando = true;
  final Map<String, TextEditingController> _ctrls = {};
  final Set<String> _enviando = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final res = await Supabase.instance.client
          .from('soporte_mensajes')
          .select('id,mensaje,respuesta,respondido,creado_en')
          .eq('usuario_id', widget.conversacion.usuarioId)
          .order('creado_en', ascending: true)
          .limit(200);
      if (!mounted) return;
      setState(() {
        _tickets = List<Map<String, dynamic>>.from(res as List);
        _cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _responder(String ticketId) async {
    final ctrl = _ctrls[ticketId];
    final texto = ctrl?.text.trim() ?? '';
    if (texto.isEmpty || _enviando.contains(ticketId)) return;
    setState(() => _enviando.add(ticketId));
    try {
      await Supabase.instance.client.from('soporte_mensajes').update({
        'respuesta': texto,
        'respondido': true,
        'respondido_en': DateTime.now().toIso8601String(),
      }).eq('id', ticketId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Respuesta enviada'), backgroundColor: Colors.green));
      }
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _enviando.remove(ticketId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.conversacion.nombre)),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
              ? const Center(child: Text('Sin mensajes'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final t = _tickets[i];
                    final id = t['id'] as String;
                    final respondido = (t['respondido'] as bool?) ?? false;
                    _ctrls.putIfAbsent(id, () => TextEditingController());
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text((t['mensaje'] as String?) ?? '',
                                style: const TextStyle(fontSize: 14)),
                            if (respondido && ((t['respuesta'] as String?) ?? '').isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Tema.marca.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.support_agent,
                                        size: 16, color: Tema.marca),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                          (t['respuesta'] as String?) ?? '',
                                          style: const TextStyle(fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 10),
                              TextField(
                                controller: _ctrls[id],
                                minLines: 1,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: 'Escribe la respuesta...',
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _enviando.contains(id)
                                      ? null
                                      : () => _responder(id),
                                  icon: _enviando.contains(id)
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Icon(Icons.send, size: 16),
                                  label: Text(_enviando.contains(id)
                                      ? 'Enviando...'
                                      : 'Responder'),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: Tema.marca),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
