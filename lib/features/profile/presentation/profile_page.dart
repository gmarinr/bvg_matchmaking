import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/domain/sport.dart';
import '../../../core/utils/labels.dart';
import '../../auth/data/auth_providers.dart';
import '../../matches/presentation/providers/matches_list_providers.dart';
import '../data/profile_providers.dart';
import '../domain/profile.dart';
import 'providers/profile_page_providers.dart';

/// Perfil deportivo: datos básicos del usuario y los deportes con su nivel
/// autodeclarado.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final profileAsync = ref.watch(myProfileProvider);

    if (user == null) {
      return const _Message(
        icon: Icons.lock_outline,
        title: 'Inicia sesión para ver tu perfil',
      );
    }

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _Message(
        icon: Icons.cloud_off_outlined,
        title: 'No pudimos cargar tu perfil',
        action: FilledButton.icon(
          onPressed: () => ref.invalidate(myProfileProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ),
      data: (profile) => _ProfileForm(
        key: ValueKey(profile?.updatedAt ?? user.id),
        userId: user.id,
        email: user.email,
        profile: profile,
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({
    super.key,
    required this.userId,
    required this.email,
    required this.profile,
  });

  final String userId;
  final String email;
  final Profile? profile;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayName;
  late final TextEditingController _commune;
  late final TextEditingController _availability;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _displayName = TextEditingController(text: p?.displayName ?? '');
    _commune = TextEditingController(text: p?.commune ?? '');
    _availability = TextEditingController(text: p?.generalAvailability ?? '');
  }

  @override
  void dispose() {
    _displayName.dispose();
    _commune.dispose();
    _availability.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final now = DateTime.now();
    final base = widget.profile;
    final profile = Profile(
      id: widget.userId,
      displayName: _displayName.text.trim(),
      commune: _commune.text.trim(),
      createdAt: base?.createdAt ?? now,
      updatedAt: now,
      avatarUrl: base?.avatarUrl,
      generalAvailability: _availability.text.trim().isEmpty
          ? null
          : _availability.text.trim(),
    );

    try {
      await ref.read(profileRepositoryProvider).upsertProfile(profile);
      ref.invalidate(myProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil guardado.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos guardar tu perfil.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = _displayName.text.trim();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Sin nombre aún' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.profile == null) ...[
            const SizedBox(height: 20),
            _Banner(
              icon: Icons.info_outline,
              text: 'Completa tu perfil para que otros sepan quién eres '
                  'cuando pidas sumarte a un partido.',
            ),
          ],
          const SizedBox(height: 24),

          const _Label('Nombre para mostrar'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _displayName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Ej: Camila Rojas',
              prefixIcon: Icon(Icons.person_outline),
            ),
            onChanged: (_) => setState(() {}),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Escribe cómo quieres que te vean'
                : null,
          ),
          const SizedBox(height: 16),

          const _Label('Comuna'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _commune,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Ej: Ñuñoa',
              prefixIcon: Icon(Icons.map_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Indica tu comuna' : null,
          ),
          const SizedBox(height: 16),

          const _Label('Disponibilidad (opcional)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _availability,
            textCapitalization: TextCapitalization.sentences,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Ej: martes y jueves después de las 19:00',
            ),
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Guardando…' : 'Guardar perfil'),
          ),
          const SizedBox(height: 32),

          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 20),
          const _Label('Mis deportes'),
          const SizedBox(height: 4),
          Text(
            'El nivel es autodeclarado: sirve como referencia, no es una '
            'clasificación oficial.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          _MySportsSection(userId: widget.userId),
        ],
      ),
    );
  }
}

/// Deportes declarados por el usuario, con su nivel y la opción de agregar
/// o quitar del catálogo controlado.
class _MySportsSection extends ConsumerStatefulWidget {
  const _MySportsSection({required this.userId});

  final String userId;

  @override
  ConsumerState<_MySportsSection> createState() => _MySportsSectionState();
}

class _MySportsSectionState extends ConsumerState<_MySportsSection> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(myUserSportsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos actualizar tus deportes.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addSport(List<Sport> available) async {
    final sport = await showModalBottomSheet<Sport>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Agregar deporte',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            for (final sport in available)
              ListTile(
                leading: const Icon(Icons.sports_outlined),
                title: Text(sport.name),
                onTap: () => Navigator.of(context).pop(sport),
              ),
          ],
        ),
      ),
    );
    if (sport == null) return;

    await _run(
      () => ref.read(profileRepositoryProvider).setUserSport(
            UserSport(
              userId: widget.userId,
              sportId: sport.id,
              skillLevel: SkillLevel.intermediate,
            ),
          ),
    );
  }

  Future<void> _setLevel(UserSport current, SkillLevel level) => _run(
        () => ref.read(profileRepositoryProvider).setUserSport(
              UserSport(
                userId: current.userId,
                sportId: current.sportId,
                skillLevel: level,
              ),
            ),
      );

  Future<void> _remove(UserSport current) => _run(
        () => ref.read(profileRepositoryProvider).removeUserSport(
              userId: current.userId,
              sportId: current.sportId,
            ),
      );

  @override
  Widget build(BuildContext context) {
    final mineAsync = ref.watch(myUserSportsProvider);
    // El catálogo también debe estar cargado para poder ofrecer deportes.
    final sportsAsync = ref.watch(sportsProvider);
    final catalog = ref.watch(sportsByIdProvider);

    if (mineAsync.isLoading || sportsAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      );
    }

    return mineAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => Text(
        'No pudimos cargar tus deportes.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      data: (mine) {
        final available = catalog.values
            .where((s) => !mine.any((us) => us.sportId == s.id))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (mine.isEmpty)
              _Banner(
                icon: Icons.sports_soccer_outlined,
                text: 'Todavía no declaras ningún deporte.',
              )
            else
              for (final us in mine) ...[
                _SportLevelCard(
                  sportName: catalog[us.sportId]?.name ?? us.sportId,
                  level: us.skillLevel,
                  enabled: !_busy,
                  onLevelChanged: (level) => _setLevel(us, level),
                  onRemove: () => _remove(us),
                ),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed:
                  _busy || available.isEmpty ? null : () => _addSport(available),
              icon: const Icon(Icons.add),
              label: Text(
                available.isEmpty
                    ? 'Ya declaraste todos los deportes'
                    : 'Agregar deporte',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SportLevelCard extends StatelessWidget {
  const _SportLevelCard({
    required this.sportName,
    required this.level,
    required this.enabled,
    required this.onLevelChanged,
    required this.onRemove,
  });

  final String sportName;
  final SkillLevel level;
  final bool enabled;
  final ValueChanged<SkillLevel> onLevelChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sportName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Quitar $sportName',
                onPressed: enabled ? onRemove : null,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Wrap(
              spacing: 8,
              children: [
                for (final option in SkillLevel.values)
                  ChoiceChip(
                    label: Text(option.label),
                    selected: option == level,
                    onSelected:
                        enabled ? (_) => onLevelChanged(option) : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .labelLarge
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, this.action});

  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
