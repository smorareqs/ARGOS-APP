import 'package:argos_app/features/chat/data/chat_repository.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _accessProvider = Provider.autoDispose<({bool internal, bool guest})>(chatAccess);

/// Acceso al chat (Más y Perfil) con los no leídos. No se muestra sin permiso.
class ChatEntryTile extends ConsumerWidget {
  const ChatEntryTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(_accessProvider);
    if (!access.internal && !access.guest) return const SizedBox.shrink();
    final unread = ref.watch(chatUnreadProvider).valueOrNull ?? 0;
    return AppListTile(
      icon: CustomIcons.chat,
      title: 'Chat',
      subtitle: access.guest ? 'Equipo y huéspedes' : 'Habla con tu equipo',
      trailing: unread == 0
          ? null
          : Semantics(
              label: '$unread sin leer',
              excludeSemantics: true,
              child: Container(
                constraints: const BoxConstraints(minWidth: 22),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: CustomColors.primary,
                  borderRadius: BorderRadius.circular(CustomDimensions.radiusPill),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  textAlign: TextAlign.center,
                  style: CustomTypography.label.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
      onTap: () => context.push(access.internal ? '/chat' : '/chat?kind=guest'),
    );
  }
}
