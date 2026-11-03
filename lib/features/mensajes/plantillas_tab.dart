import 'package:flutter/material.dart';

import '../../config/tema.dart';
import 'mensajes_comunes.dart';
import 'mensajes_servicio.dart';

/// Pestaña para crear, editar y borrar plantillas reutilizables.
class PlantillasTab extends StatefulWidget {
  final MensajesServicio servicio;

  const PlantillasTab({super.key, required this.servicio});

  @override
  State<PlantillasTab> createState() => _PlantillasTabState();
}

class _PlantillasTabState extends State<PlantillasTab> {
  List<PlantillaMensaje> _plantillas = const [];
  String? _error;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await widget.servicio.plantillas();
      if (!mounted) return;
      setState(() {
        _plantillas = lista;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = mensajeDeError(e);
        _cargando = false;
      });
    }
  }

  Future<void> _editar([PlantillaMensaje? plantilla]) async {
    final resultado = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _EditorPlantilla(plantilla: plantilla),
    );
    if (resultado == null || !mounted) return;

    try {
      await widget.servicio.guardarPlantilla(
        id: plantilla?.id,
        titulo: resultado['titulo']!,
        contenido: resultado['contenido']!,
      );
      if (!mounted) return;
      _snack(plantilla == null ? 'Plantilla creada' : 'Plantilla actualizada');
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      _snack(mensajeDeError(e), error: true);
    }
  }

  Future<void> _eliminar(PlantillaMensaje plantilla) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar plantilla'),
        content: Text('¿Eliminar "${plantilla.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    try {
      await widget.servicio.eliminarPlantilla(plantilla.id);
      if (!mounted) return;
      setState(() {
        _plantillas =
            _plantillas.where((p) => p.id != plantilla.id).toList();
      });
      _snack('Plantilla eliminada');
    } catch (e) {
      if (!mounted) return;
      _snack(mensajeDeError(e), error: true);
    }
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plantillas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_plantillas.length} disponibles',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _cargando ? null : () => _editar(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nueva'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_error != null)
            AvisoCard(
              icono: Icons.error_outline_rounded,
              titulo: 'No se pudieron cargar las plantillas',
              detalle: _error!,
              color: Colors.red.shade700,
              acciones: [
                OutlinedButton.icon(
                  onPressed: _cargar,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reintentar'),
                ),
              ],
            )
          else if (_cargando && _plantillas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_plantillas.isEmpty)
            AvisoCard(
              icono: Icons.notes_rounded,
              titulo: 'Sin plantillas',
              detalle:
                  'Crea mensajes frecuentes para reutilizarlos al enviar. '
                  'Puedes usar {nombre} para saludar a cada usuario.',
              color: Tema.marca,
              acciones: [
                FilledButton.icon(
                  onPressed: () => _editar(),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Crear plantilla'),
                ),
              ],
            )
          else ...[
            for (final plantilla in _plantillas) ...[
              _TarjetaPlantilla(
                plantilla: plantilla,
                onEditar: () => _editar(plantilla),
                onEliminar: () => _eliminar(plantilla),
              ),
              const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 12),
          AvisoCard(
            icono: Icons.lightbulb_outline_rounded,
            titulo: 'Variables disponibles',
            detalle:
                'Usa {nombre} dentro del texto y se sustituirá por el nombre '
                'del destinatario al enviar el mensaje.',
            color: Colors.amber.shade800,
          ),
        ],
      ),
    );
  }
}

class _TarjetaPlantilla extends StatelessWidget {
  final PlantillaMensaje plantilla;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _TarjetaPlantilla({
    required this.plantilla,
    required this.onEditar,
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plantilla.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEditar,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Editar',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: onEliminar,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.red.shade700,
                  ),
                  tooltip: 'Eliminar',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            Text(
              plantilla.contenido,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorPlantilla extends StatefulWidget {
  final PlantillaMensaje? plantilla;

  const _EditorPlantilla({this.plantilla});

  @override
  State<_EditorPlantilla> createState() => _EditorPlantillaState();
}

class _EditorPlantillaState extends State<_EditorPlantilla> {
  final _formKey = GlobalKey<FormState>();
  late final _tituloCtrl =
      TextEditingController(text: widget.plantilla?.titulo ?? '');
  late final _contenidoCtrl =
      TextEditingController(text: widget.plantilla?.contenido ?? '');

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _contenidoCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'titulo': _tituloCtrl.text.trim(),
      'contenido': _contenidoCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.plantilla != null;
    return AlertDialog(
      title: Text(editando ? 'Editar plantilla' : 'Nueva plantilla'),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _tituloCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Escribe un título'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contenidoCtrl,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Contenido',
                hintText: 'Hola {nombre}, …',
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Escribe el contenido'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          child: Text(editando ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
