import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/tema.dart';
import '../../features/usuarios/usuarios_servicio.dart';
import '../../core/modelo/usuario_admin.dart';

class EnviarMensajeAdminPantalla extends StatefulWidget {
  const EnviarMensajeAdminPantalla({super.key});

  @override
  State<EnviarMensajeAdminPantalla> createState() => _EnviarMensajeAdminPantallaState();
}

class _EnviarMensajeAdminPantallaState extends State<EnviarMensajeAdminPantalla> {
  final _formKey = GlobalKey<FormState>();
  final _destinatarioCtrl = TextEditingController();
  final _mensajeCtrl = TextEditingController();
  final _servicio = UsuariosServicio(Supabase.instance.client);

  String _remitente = 'admin'; // 'admin' o 'flumi'
  bool _enviando = false;
  String? _resultado;
  bool _exito = false;
  UsuarioAdmin? _destinatarioSeleccionado;

  static const String _adminId = '00000000-0000-0000-0000-00000000000a';
  static const String _flumiId = '00000000-0000-0000-0000-00000000000f';

  @override
  void dispose() {
    _destinatarioCtrl.dispose();
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarDestinatario() async {
    final query = _destinatarioCtrl.text.trim();
    if (query.isEmpty) return;

    try {
      // Buscar por ID exacto o nombre/email
      UsuarioAdmin? usuario;
      if (query.length == 36 && query.contains('-')) {
        // Posible UUID
        usuario = await _servicio.obtener(query);
      } else {
        // Buscar por nombre
        final lista = await _servicio.listar(busqueda: query, porPagina: 5);
        if (lista.isNotEmpty) {
          usuario = lista.first;
        }
      }

      if (!mounted) return;
      setState(() {
        _destinatarioSeleccionado = usuario;
        _resultado = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _destinatarioSeleccionado = null;
        _exito = false;
        _resultado = 'Error al buscar: $e';
      });
    }
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_destinatarioSeleccionado == null) {
      setState(() {
        _exito = false;
        _resultado = 'Selecciona un destinatario válido';
      });
      return;
    }

    if (_destinatarioSeleccionado!.id == (_remitente == 'admin' ? _adminId : _flumiId)) {
      setState(() {
        _exito = false;
        _resultado = 'No puedes enviarte un mensaje a ti mismo';
      });
      return;
    }

    setState(() {
      _enviando = true;
      _resultado = null;
    });

    try {
      final remitenteId = _remitente == 'admin' ? _adminId : _flumiId;
      await Supabase.instance.client.rpc('enviar_mensaje_admin', params: {
        'p_emisor': remitenteId,
        'p_receptor': _destinatarioSeleccionado!.id,
        'p_contenido': _mensajeCtrl.text.trim(),
      });

      if (!mounted) return;
      setState(() {
        _exito = true;
        _resultado = 'Mensaje enviado correctamente a ${_destinatarioSeleccionado!.nombre}';
        _mensajeCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _exito = false;
        _resultado = e.toString();
      });
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildAppBar(colorScheme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Form(
                key: _formKey,
                child: _buildContent(colorScheme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enviar mensaje como sistema',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              'Comunicación · Admin/Flumi',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Tema.marca.withValues(alpha: 0.08),
                Tema.marca.withValues(alpha: 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selector de remitente
        _buildRemitenteSelector(colorScheme),
        const SizedBox(height: 24),

        // Buscador de destinatario
        _buildDestinatarioSearch(colorScheme),
        if (_destinatarioSeleccionado != null) ...[
          const SizedBox(height: 16),
          _buildDestinatarioCard(colorScheme),
        ],
        const SizedBox(height: 24),

        // Campo de mensaje
        _buildMensajeField(colorScheme),
        const SizedBox(height: 24),

        // Botón enviar
        _buildEnviarButton(colorScheme),

        if (_resultado != null) ...[
          const SizedBox(height: 16),
          _buildResultadoCard(colorScheme),
        ],

        const SizedBox(height: 16),
        _buildInfoCard(colorScheme),
      ],
    );
  }

  Widget _buildRemitenteSelector(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enviar como',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _RemitenteOption(
                id: 'admin',
                nombre: 'Administrador',
                icon: Icons.admin_panel_settings_rounded,
                color: Colors.orange,
                seleccionado: _remitente == 'admin',
                onTap: () => setState(() => _remitente = 'admin'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RemitenteOption(
                id: 'flumi',
                nombre: 'Flumi',
                icon: Icons.smart_toy_rounded,
                color: Tema.marca,
                seleccionado: _remitente == 'flumi',
                onTap: () => setState(() => _remitente = 'flumi'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDestinatarioSearch(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Destinatario',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _destinatarioCtrl,
                decoration: InputDecoration(
                  labelText: 'UUID, nombre o email',
                  hintText: 'Ej: 123e4567-e89b... o "Juan Pérez"',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _destinatarioCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _destinatarioCtrl.clear();
                            setState(() => _destinatarioSeleccionado = null);
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa un destinatario' : null,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _buscarDestinatario,
              icon: const Icon(Icons.person_search_rounded, size: 18),
              label: const Text('Buscar'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDestinatarioCard(ColorScheme colorScheme) {
    final u = _destinatarioSeleccionado!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: u.fotoPrincipal.isNotEmpty ? NetworkImage(u.fotoPrincipal) : null,
            child: u.fotoPrincipal.isEmpty ? const Icon(Icons.person, size: 24) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.nombre,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (u.email.isNotEmpty)
                  Text(
                    u.email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                Text(
                  'ID: ${u.id}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => setState(() => _destinatarioSeleccionado = null),
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildMensajeField(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mensaje',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _mensajeCtrl,
          maxLines: 5,
          minLines: 3,
          decoration: InputDecoration(
            hintText: 'Escribe el mensaje aquí...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            alignLabelWithHint: true,
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'El mensaje no puede estar vacío' : null,
        ),
      ],
    );
  }

  Widget _buildEnviarButton(ColorScheme colorScheme) {
    final remitenteColor = _remitente == 'admin' ? Colors.orange : Tema.marca;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _enviando ? null : _enviar,
        icon: _enviando
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.send_rounded),
        label: Text(_enviando ? 'Enviando...' : 'Enviar mensaje como ${_remitente == 'admin' ? 'Administrador' : 'Flumi'}'),
        style: FilledButton.styleFrom(
          backgroundColor: remitenteColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildResultadoCard(ColorScheme colorScheme) {
    final isError = !_exito;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isError ? Colors.red : Colors.green).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isError ? Colors.red : Colors.green).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: isError ? Colors.red : Colors.green,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _resultado!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isError ? Colors.red.shade700 : Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 20, color: Tema.marca),
              const SizedBox(width: 8),
              Text(
                'Cómo funciona',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            'El mensaje se envía desde el perfil del sistema (Admin o Flumi), no desde tu cuenta personal',
            'El destinatario lo verá como un mensaje normal en su chat',
            'Solo admins pueden usar esta función (validado por RLS en BD)',
            'Remitentes permitidos: Administrador (UUID fijo) y Flumi (UUID fijo)',
            'No puedes enviarte mensajes a ti mismo',
          ].map((txt) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 13)),
                Expanded(
                  child: Text(
                    txt,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _RemitenteOption extends StatelessWidget {
  final String id;
  final String nombre;
  final IconData icon;
  final Color color;
  final bool seleccionado;
  final VoidCallback onTap;

  const _RemitenteOption({
    required this.id,
    required this.nombre,
    required this.icon,
    required this.color,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: seleccionado ? color.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: seleccionado ? color : Theme.of(context).colorScheme.outlineVariant,
              width: seleccionado ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: seleccionado ? color : Theme.of(context).colorScheme.onSurfaceVariant, size: 28),
              const SizedBox(height: 8),
              Text(
                nombre,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: seleccionado ? color : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (seleccionado)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(Icons.check_circle, color: color, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}