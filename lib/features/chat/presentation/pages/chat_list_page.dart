import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/chat/data/chat_repository.dart';
import 'package:argos_app/features/chat/models/chat.dart';
import 'package:argos_app/features/hr/presentation/widgets/hr_widgets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _chatAccessProvider = Provider.autoDispose<({bool internal, bool guest})>(chatAccess);

/// B22 · Chat: conversaciones del equipo y, con chat.guest, de huéspedes.
/// No leídos, último mensaje y hora; búsqueda y "Nueva".
class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key, this.initialKind = 'internal', this.now});

  final String initialKind;
  final DateTime? now;

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  late String _kind = widget.initialKind;
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(_chatAccessProvider);
    final kind = access.guest ? _kind : 'internal';
    final async = ref.watch(conversationsProvider(kind));
    final list = async.valueOrNull;
    Future<void> refresh() => ref.refresh(conversationsProvider(kind).future).then((_) {}, onError: (_) {});
    final now = widget.now ?? DateTime.now();

    Widget body;
    if (list == null && async.isLoading) {
      body = hrLoading(cards: 5, first: 72);
    } else if (list == null) {
      body = hrError(async.error, refresh);
    } else {
      final q = _query.trim().toLowerCase();
      final shown = q.isEmpty
          ? list
          : list
                .where(
                  (c) =>
                      c.title.toLowerCase().contains(q) ||
                      (c.reservation?.propertyCode.toLowerCase().contains(q) ?? false) ||
                      (c.reservation?.code.toLowerCase().contains(q) ?? false),
                )
                .toList();
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (access.guest) ...[
            PeriodSwitch(
              options: const [('internal', 'Equipo'), ('guest', 'Huéspedes')],
              value: kind,
              onChanged: (v) => setState(() => _kind = v),
            ),
            const SizedBox(height: 12),
          ],
          if (list.length > 5) ...[
            SearchField(onSearch: (v) => setState(() => _query = v), hintText: 'Buscar conversación'),
            const SizedBox(height: 12),
          ],
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: EmptyState(
                icon: CustomIcons.forum,
                title: kind == 'guest' ? 'Sin chats de huéspedes' : 'Aún no tienes conversaciones',
                message: kind == 'guest'
                    ? 'Cuando un huésped confirmado escriba, su conversación aparece aquí.'
                    : 'Toca "Nueva" para escribirle a alguien del equipo.',
              ),
            )
          else if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: EmptyState(icon: CustomIcons.search, title: 'Nada con ese nombre'),
            )
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < shown.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 72, color: CustomColors.divider),
                    _ConversationRow(conversation: shown[i], now: now),
                  ],
                ],
              ),
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: CustomColors.background,
      body: HrPage(title: 'Chat', overline: kind == 'guest' ? 'Huéspedes' : 'Equipo', onRefresh: refresh, body: body),
      floatingActionButton: access.internal && kind == 'internal'
          ? FloatingActionButton.extended(
              onPressed: () => showNewChat(context),
              backgroundColor: CustomColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(CustomIcons.add),
              label: Text('Nueva', style: CustomTypography.button.copyWith(color: Colors.white)),
            )
          : null,
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation, required this.now});

  final Conversation conversation;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final last = c.lastMessage;
    final preview = last == null
        ? 'Sin mensajes'
        : last.isSystem
        ? last.preview
        : last.mine
        ? 'Tú: ${last.preview}'
        : (c.isGroup || c.isGuest) && !c.isGuest
        ? '${last.senderName.split(' ').first}: ${last.preview}'
        : last.preview;
    final unread = c.unread > 0;
    final subtitle = c.reservation == null ? null : '${c.reservation!.propertyCode} · ${c.reservation!.code}';

    return InkWell(
      onTap: () => context.push('/chat/${c.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            c.isGroup
                ? Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(color: CustomColors.tealWashed, shape: BoxShape.circle),
                    child: const Icon(CustomIcons.people, color: CustomColors.primary, size: 22),
                  )
                : Avatar(name: c.title, size: 46, variant: c.isGuest ? AvatarVariant.company : AvatarVariant.person),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CustomTypography.cardTitle.copyWith(
                            fontSize: 16,
                            fontWeight: unread ? FontWeight.w700 : null,
                          ),
                        ),
                      ),
                      if (c.muted) ...[
                        const Icon(CustomIcons.muted, size: 14, color: CustomColors.textMuted),
                        const SizedBox(width: 4),
                      ],
                      if (c.lastMessageAt != null)
                        Text(
                          chatListTime(c.lastMessageAt!, now),
                          style: CustomTypography.verdana(
                            fontSize: 11.5,
                            color: unread ? CustomColors.secondary : CustomColors.textMuted,
                            fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                  if (subtitle != null)
                    Text(subtitle, style: CustomTypography.verdana(fontSize: 11.5, color: CustomColors.tealMuted)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CustomTypography.bodySmall.copyWith(
                            color: unread ? CustomColors.textPrimary : CustomColors.textSecondary,
                          ),
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: CustomColors.secondary,
                            borderRadius: BorderRadius.circular(CustomDimensions.radiusPill),
                          ),
                          child: Text(
                            c.unread > 99 ? '99+' : '${c.unread}',
                            textAlign: TextAlign.center,
                            style: CustomTypography.verdana(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      if (c.isArchived) ...[
                        const SizedBox(width: 8),
                        const StatusBadge(label: 'Archivada', variant: StatusBadgeVariant.pending),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Nueva": elegir una persona (1:1) o varias con nombre de grupo.
Future<void> showNewChat(BuildContext context) => showArgosSheet<void>(context, builder: (_) => const _NewChatSheet());

class _NewChatSheet extends ConsumerStatefulWidget {
  const _NewChatSheet();

  @override
  ConsumerState<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends ConsumerState<_NewChatSheet> {
  final _picked = <String>{};
  final _title = TextEditingController();
  var _query = '';
  var _busy = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final c = await ref
          .read(chatRepositoryProvider)
          .create(_picked.toList(), title: _picked.length > 1 ? _title.text : null);
      ref.invalidate(conversationsProvider('internal'));
      if (!mounted) return;
      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      router.push('/chat/${c.id}');
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(chatPeopleProvider);
    final people = async.valueOrNull ?? const <ChatPerson>[];
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty ? people : people.where((p) => p.name.toLowerCase().contains(q)).toList();
    final group = _picked.length > 1;
    return SheetScaffold(
      title: 'Nueva conversación',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchField(onSearch: (v) => setState(() => _query = v), hintText: 'Buscar persona'),
          const SizedBox(height: 10),
          Flexible(
            child: async.isLoading && people.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final p in shown)
                        CheckboxListTile(
                          value: _picked.contains(p.id),
                          onChanged: (v) => setState(() => v == true ? _picked.add(p.id) : _picked.remove(p.id)),
                          activeColor: CustomColors.primary,
                          contentPadding: EdgeInsets.zero,
                          secondary: Avatar(name: p.name, size: 38),
                          title: Text(
                            p.name,
                            style: CustomTypography.body.copyWith(fontSize: 15, color: CustomColors.textPrimary),
                          ),
                          subtitle: p.role == null ? null : Text(p.role!, style: CustomTypography.bodySmall),
                        ),
                    ],
                  ),
          ),
          if (group) ...[
            const SizedBox(height: 8),
            AppTextField(controller: _title, hintText: 'Nombre del grupo (opcional)'),
          ],
          const SizedBox(height: 12),
          PrimaryButton(
            label: _picked.isEmpty ? 'Elige a alguien' : (group ? 'Crear grupo de ${_picked.length + 1}' : 'Escribir'),
            isLoading: _busy,
            onPressed: _picked.isEmpty || _busy ? null : _create,
          ),
        ],
      ),
    );
  }
}
