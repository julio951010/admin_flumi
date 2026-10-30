import 'package:flutter/material.dart';

/// Breakpoints responsivos para el admin
class AdminBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < desktop;
  static bool isDesktop(double width) => width >= desktop;
}

/// Layout responsivo reutilizable para páginas del admin
class AdminResponsiveLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool usePadding;

  const AdminResponsiveLayout({
    super.key,
    required this.child,
    this.padding,
    this.usePadding = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = AdminBreakpoints.isMobile(constraints.maxWidth);
        final isTablet = AdminBreakpoints.isTablet(constraints.maxWidth);

        final horizontalPadding = isMobile
            ? 16.0
            : isTablet
                ? 24.0
                : 32.0;
        final verticalPadding = isMobile ? 16.0 : 24.0;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile
                  ? double.infinity
                  : isTablet
                      ? 800
                      : 1200,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Header responsivo reutilizable
class AdminPageHeader extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<Widget>? acciones;
  final VoidCallback? onBack;

  const AdminPageHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acciones,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = AdminBreakpoints.isMobile(constraints.maxWidth);

        return Padding(
          padding: EdgeInsets.only(
            bottom: 16,
            left: isMobile ? 16 : 24,
            right: isMobile ? 16 : 24,
            top: 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile || Navigator.of(context).canPop())
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  tooltip: 'Volver',
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitulo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitulo!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (acciones != null && acciones!.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: acciones!,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Contenedor de tarjeta adaptable
class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;

  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    this.color,
    this.elevation = 1,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      color: color ?? Colors.white,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: padding!,
        child: child,
      ),
    );
  }
}

/// Fila de estadísticas responsiva
class AdminStatsRow extends StatelessWidget {
  final List<Widget> children;

  const AdminStatsRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double childAspectRatio;

        final width = MediaQuery.of(context).size.width;
        if (AdminBreakpoints.isMobile(width)) {
          crossAxisCount = 2;
          childAspectRatio = 1.6;
        } else if (AdminBreakpoints.isTablet(width)) {
          crossAxisCount = 3;
          childAspectRatio = 1.8;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 2.0;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: children,
        );
      },
    );
  }
}

/// Tarjeta de estadística
class AdminStatCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color? color;
  final String? subtitulo;
  final VoidCallback? onTap;

  const AdminStatCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    this.color,
    this.subtitulo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, color: cardColor, size: 22),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitulo!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Botón de acción responsivo
class AdminActionButton extends StatelessWidget {
  final String label;
  final IconData icono;
  final VoidCallback? onPressed;
  final Color? color;
  final bool cargando;
  final bool expanded;

  const AdminActionButton({
    super.key,
    required this.label,
    required this.icono,
    this.onPressed,
    this.color,
    this.cargando = false,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expanded ? double.infinity : null,
      child: FilledButton.icon(
        onPressed: cargando ? null : onPressed,
        icon: cargando
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icono, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

/// Input responsivo
class AdminTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helperText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final int? maxLength;

  const AdminTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: InputBorder.none,
      ),
    );
  }
}

/// Badge de estado
class AdminStatusChip extends StatelessWidget {
  final String texto;
  final Color color;
  final IconData? icono;
  final bool outlined;

  const AdminStatusChip({
    super.key,
    required this.texto,
    required this.color,
    this.icono,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icono != null) ...[
              Icon(icono, size: 14, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Separador con etiqueta
class AdminSectionDivider extends StatelessWidget {
  final String texto;
  final IconData? icono;

  const AdminSectionDivider({
    super.key,
    required this.texto,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          if (icono != null) ...[
            Icon(icono, size: 18, color: Colors.grey.shade500),
            const SizedBox(width: 8),
          ],
          Text(
            texto,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: Colors.grey.shade300,
              thickness: 1,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón de acción flotante responsivo
class AdminFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icono;
  final String? tooltip;
  final String? label;

  const AdminFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icono,
    this.tooltip,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: Icon(icono),
      label: label != null ? Text(label!) : const SizedBox.shrink(),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

/// Modal bottom sheet responsivo
Future<T?> showAdminBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? titulo,
  double maxHeightFactor = 0.9,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (titulo != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: builder(context),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Switch tile adaptado
class AdminSwitchTile extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final bool valor;
  final ValueChanged<bool> onChanged;
  final IconData? iconoInicial;

  const AdminSwitchTile({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.valor,
    required this.onChanged,
    this.iconoInicial,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: iconoInicial != null
          ? CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(iconoInicial, size: 20, color: Theme.of(context).colorScheme.primary),
            )
          : null,
      title: Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: subtitulo != null
          ? Text(subtitulo!, style: TextStyle(fontSize: 12, color: Colors.grey[500]))
          : null,
      trailing: Switch(
        value: valor,
        onChanged: onChanged,
        activeThumbColor: Theme.of(context).colorScheme.primary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

/// Página admin con header, scroll y footer
class AdminPage extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<Widget> children;
  final List<Widget>? accionesHeader;
  final VoidCallback? onBack;

  const AdminPage({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.children,
    this.accionesHeader,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
                onPressed: onBack ?? () => Navigator.pop(context),
              )
            : null,
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          ...?accionesHeader,
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (subtitulo != null) ...[
              Text(
                subtitulo!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}