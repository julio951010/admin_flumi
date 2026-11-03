import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/tema.dart';
import 'mensajes_comunes.dart';
import 'mensajes_servicio.dart';

/// Pestaña de historial: métricas + mensajes enviados desde las cuentas
/// de sistema, con búsqueda, filtros, reenvío y borrado.
class HistorialTab extends StatefulWidget {
  final MensajesServicio servicio;
  final ValueListenable<int> version;
  final VoidCallback? onIrAEnviar;

  const HistorialTab({
    super.key,
    required this.servicio,
    required this.version,
    this.onIrAEnviar,
  });

  @override
  State<HistorialTab> createState() => _HistorialTabState();
}

class _HistorialTabState extends State<HistorialTab> {
  final _busquedaCtrl = TextEditingController();
  Timer? _debounce;

  static const int _limite = 30;

  String _remitente = 'todos';
  List<MensajeSistema> _mensajes = const [];
  MensajesStats? _stats;
  String? _error;
  bool _cargando = true;
  bool _cargandoMas = false;
  int _total = 0;
  int _cargaId = 0;

  @override
  void initState() {
    super.initState();
    widget.version.addListener(_recargar);
    _cargar();
  }

  @override
  void dispose() {
    widget.version.removeListener(_recargar);
    _debounce?.cancel();
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _recargar() {
    if (!mounted) return;
    _cargar();
  }

  Future<void> _cargar({bool mas = false}) async {
    if (!mounted) return;
    final id = ++_cargaId;
    setState(() {
      if (mas) {
        _cargandoMas = true;
      } else {
        _cargando = true;
        _error = null;
      }
    });

    MensajesPagina? pagina;
    MensajesStats? stats;
    String? error;

    try {
      pagina = await widget.servicio.listar(
        busqueda: _busquedaCtrl.text,
        remitente: _remitente,
        limite: _limite,
        offset: mas ? _mensajes.length : 0,
      );
    } catch (e) {
      error = mensajeDeError(e);
    }

    try {
      stats = await widget.servicio.stats();
    } catch (_) {
      stats = _stats;
    }

    if (!mounted || id != _cargaId) return;
    setState(() {
      if (pagina != null) {
        _total = pagina.total;
        _mensajes = mas
            ? [..._mensajes, ...pagina.mensajes]
            : pagina.mensajes;
      }
      _stats = stats;
      _error = error;
      _cargando = false;
      _cargandoMas = false;
    });
  }

  void _onBusqueda(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _cargar();
    });
  }

  void _cambiarRemitente(String valor) {
    if (_remitente == valor) return;
    setState(() => _remitente = valor);
    _cargar();
  }

  Future<void> _verDetalle(MensajeSistema mensaje) async {
    final accion = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalleMensaje(mensaje: mensaje),
    );
    if (!mounted || accion == null) return;

    switch (accion) {
      case 'reenviar':
        await _reenviar(mensaje);
        break;
      case 'eliminar':
        await _eliminar(mensaje);
        break;
      case 'copiar':
        await Clipboard.setData(ClipboardData(text: mensaje.contenido));
        _snack('Mensaje copiado');
        break;
    }
  }

  Future<void> _reenviar(MensajeSistema mensaje) async {
    final confirmar = await _confirmar(
      titulo: 'Reenviar mensaje',
      detalle:
          'Se enviará de nuevo el mismo mensaje a ${mensaje.receptorNombre} '
          'como ${mensaje.remitenteNombre}.',
      textoAccion: 'Reenviar',
    );
    if (confirmar != true) return;

    try {
      await widget.servicio.reenviar(mensaje);
      if (!mounted) return;
      _snack('Mensaje reenviado a ${mensaje.receptorNombre}');
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      _snack(mensajeDeError(e), error: true);
    }
  }

  Future<void> _eliminar(MensajeSistema mensaje) async {
    final confirmar = await _confirmar(
      titulo: 'Eliminar mensaje',
      detalle:
          'El mensaje desaparecerá también del chat de '
          '${mensaje.receptorNombre}. Esta acción no se puede deshacer.',
      textoAccion: 'Eliminar',
      destructivo: true,
    );
    if (confirmar != true) return;

    try {
      await widget.servicio.eliminar(mensaje.id);
      if (!mounted) return;
      setState(() {
        _mensajes = _mensajes.where((m) => m.id != mensaje.id).toList();
        if (_total > 0) _total--;
      });
      _snack('Mensaje eliminado');
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      _snack(mensajeDeError(e), error: true);
    }
  }

  Future<bool?> _confirmar({
    required String titulo,
    required String detalle,
    required String textoAccion,
    bool destructivo = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(detalle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: destructivo
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(textoAccion),
          ),
        ],
      ),
    );
  }

  void _snack(String texto, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargar,
      color: Tema.marca,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 32),
        children: [
          if (_stats != null) ...[
            _ResumenEnvios(stats: _stats!),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _busquedaCtrl,
            onChanged: _onBusqueda,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por usuario, contenido o UUID',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _busquedaCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _busquedaCtrl.clear();
                        _onBusqueda('');
                        setState(() {});
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FiltroChip(
                etiqueta: 'Todos',
                activo: _remitente == 'todos',
                onTap: () => _cambiarRemitente('todos'),
              ),
              _FiltroChip(
                etiqueta: 'Administrador',
                activo: _remitente == remitenteAdminClave,
                color: colorRemitente(remitenteAdminClave),
                onTap: () => _cambiarRemitente(remitenteAdminClave),
              ),
              _FiltroChip(
                etiqueta: 'Flumi',
                activo: _remitente == remitenteFlumiClave,
                color: colorRemitente(remitenteFlumiClave),
                onTap: () => _cambiarRemitente(remitenteFlumiClave),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null)
            AvisoCard(
              icono: Icons.error_outline_rounded,
              titulo: 'No se pudo cargar el historial',
              detalle: _error!,
              color: Colors.red.shade700,
              acciones: [
                OutlinedButton.icon(
                  onPressed: () => _cargar(),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reintentar'),
                ),
              ],
            )
          else if (_cargando && _mensajes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_mensajes.isEmpty)
            _EstadoVacio(
              hayFiltros: _remitente != 'todos' ||
                  _busquedaCtrl.text.trim().isNotEmpty,
              onEnviar: widget.onIrAEnviar,
              onLimpiar: () {
                _busquedaCtrl.clear();
                setState(() => _remitente = 'todos');
                _cargar();
              },
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$_total ${_total == 1 ? 'mensaje' : 'mensajes'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_cargando)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (final mensaje in _mensajes) ...[
              _TarjetaMensaje(
                mensaje: mensaje,
                onTap: () => _verDetalle(mensaje),
                onCopiar: () async {
                  await Clipboard.setData(
                    ClipboardData(text: mensaje.contenido),
                  );
                  _snack('Mensaje copiado');
                },
                onReenviar: () => _reenviar(mensaje),
                onEliminar: () => _eliminar(mensaje),
              ),
              const SizedBox(height: 8),
            ],
            if (_mensajes.length < _total) ...[
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed:
                    _cargandoMas ? null : () => _cargar(mas: true),
                icon: _cargandoMas
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded, size: 18),
                label: Text('Cargar más (${_total - _mensajes.length})'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String etiqueta;
  final bool activo;
  final Color? color;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.etiqueta,
    required this.activo,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tono = color ?? Tema.marca;
    return ChoiceChip(
      label: Text(etiqueta),
      selected: activo,
      onSelected: (_) => onTap(),
      selectedColor: tono.withValues(alpha: 0.15),
      side: BorderSide(
        color: activo ? tono : Colors.grey.shade300,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
        color: activo ? tono : Colors.grey.shade700,
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final bool hayFiltros;
  final VoidCallback? onEnviar;
  final VoidCallback onLimpiar;

  const _EstadoVacio({
    required this.hayFiltros,
    required this.onEnviar,
    required this.onLimpiar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      width: double.infinity,
      child: Column(
        children: [
          Icon(
            hayFiltros
                ? Icons.search_off_rounded
                : Icons.forum_outlined,
            size: 44,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            hayFiltros
                ? 'No hay mensajes con esos filtros'
                : 'Todavía no has enviado mensajes',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hayFiltros
                ? 'Prueba con otro nombre o cambia el remitente.'
                : 'Los envíos desde Administrador y Flumi aparecerán aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (hayFiltros)
                OutlinedButton.icon(
                  onPressed: onLimpiar,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                  label: const Text('Limpiar filtros'),
                ),
              if (onEnviar != null)
                FilledButton.icon(
                  onPressed: onEnviar,
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Enviar mensaje'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaMensaje extends StatelessWidget {
  final MensajeSistema mensaje;
  final VoidCallback onTap;
  final VoidCallback onCopiar;
  final VoidCallback onReenviar;
  final VoidCallback onEliminar;

  const _TarjetaMensaje({
    required this.mensaje,
    required this.onTap,
    required this.onCopiar,
    required this.onReenviar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarIniciales(
                nombre: mensaje.receptorNombre,
                claveRemitente: mensaje.remitenteClave,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            mensaje.receptorNombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        RemitenteBadge(
                          clave: mensaje.remitenteClave,
                          compacto: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mensaje.contenido,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      fechaCorta(mensaje.fecha),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onSelected: (valor) {
                  switch (valor) {
                    case 'ver':
                      onTap();
                      break;
                    case 'copiar':
                      onCopiar();
                      break;
                    case 'reenviar':
                      onReenviar();
                      break;
                    case 'eliminar':
                      onEliminar();
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'ver', child: Text('Ver mensaje')),
                  PopupMenuItem(value: 'copiar', child: Text('Copiar texto')),
                  PopupMenuItem(value: 'reenviar', child: Text('Reenviar')),
                  PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumenEnvios extends StatelessWidget {
  final MensajesStats stats;

  const _ResumenEnvios({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Resumen de envíos',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${stats.usuariosAlcanzados} de ${stats.usuariosTotales} usuarios',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final columnas = constraints.maxWidth >= 720 ? 4 : 2;
            const separacion = 10.0;
            final ancho =
                (constraints.maxWidth - separacion * (columnas - 1)) / columnas;
            final tiles = [
              StatTile(
                titulo: 'Total enviados',
                valor: '${stats.total}',
                icono: Icons.forum_rounded,
                color: Tema.marca,
                detalle: 'Últimos 30 días: ${stats.ultimos30d}',
              ),
              StatTile(
                titulo: 'Hoy',
                valor: '${stats.hoy}',
                icono: Icons.today_rounded,
                color: Colors.green.shade700,
                detalle: 'Últimos 7 días: ${stats.ultimos7d}',
              ),
              StatTile(
                titulo: 'Administrador',
                valor: '${stats.admin}',
                icono: Icons.admin_panel_settings_rounded,
                color: colorRemitente(remitenteAdminClave),
                detalle: 'Enviados como Admin',
              ),
              StatTile(
                titulo: 'Flumi',
                valor: '${stats.flumi}',
                icono: Icons.smart_toy_rounded,
                color: colorRemitente(remitenteFlumiClave),
                detalle: 'Enviados como Flumi',
              ),
            ];
            return Wrap(
              spacing: separacion,
              runSpacing: separacion,
              children: [
                for (final tile in tiles)
                  SizedBox(width: ancho, child: tile),
              ],
            );
          },
        ),
        if (stats.serie14d.isNotEmpty) ...[
          const SizedBox(height: 10),
          _SerieEnvios(serie: stats.serie14d),
        ],
      ],
    );
  }
}

class _SerieEnvios extends StatelessWidget {
  final List<MensajeDia> serie;

  const _SerieEnvios({required this.serie});

  @override
  Widget build(BuildContext context) {
    final maximo = serie.fold<int>(1, (a, b) => b.total > a ? b.total : a);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Envíos de los últimos ${serie.length} días',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'máx. $maximo',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 74,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final dia in serie)
                  Expanded(
                    child: Tooltip(
                      message:
                          '${dia.fecha.day}/${dia.fecha.month}: ${dia.total}',
                      child: Container(
                        height: 8 + 62 * (dia.total / maximo),
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: Tema.marca.withValues(
                            alpha: dia.total == 0 ? 0.14 : 0.75,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetalleMensaje extends StatelessWidget {
  final MensajeSistema mensaje;

  const _DetalleMensaje({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  RemitenteBadge(clave: mensaje.remitenteClave),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fechaCorta(mensaje.fecha),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  AvatarIniciales(
                    nombre: mensaje.receptorNombre,
                    claveRemitente: mensaje.remitenteClave,
                    radio: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mensaje.receptorNombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Para: ${mensaje.receptorId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              SelectableText(
                mensaje.contenido,
                style: const TextStyle(fontSize: 14, height: 1.45),
              ),
              const SizedBox(height: 8),
              Text(
                '${fechaCompleta(mensaje.fecha)} · '
                '${estadoLegible(mensaje.estadoEnvio)}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, 'copiar'),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copiar'),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context, 'reenviar'),
                    icon: const Icon(Icons.replay_rounded, size: 16),
                    label: const Text('Reenviar'),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context, 'eliminar'),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Colors.red.shade700,
                    ),
                    label: Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
