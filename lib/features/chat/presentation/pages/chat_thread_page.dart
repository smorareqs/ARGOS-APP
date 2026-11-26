import 'dart:io';

import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/chat/data/chat_repository.dart';
import 'package:argos_app/features/chat/models/chat.dart';
import 'package:argos_app/features/guest/presentation/providers/guest_session.dart';
import 'package:argos_app/features/hr/presentation/widgets/hr_widgets.dart';
import 'package:argos_app/features/tickets/presentation/widgets/draft_photos.dart';
import 'package:argos_app/features/uploads/data/repositories/upload_queue.dart';
import 'package:argos_app/features/uploads/models/pending_upload.dart';
import 'package:argos_app/features/uploads/presentation/providers/upload_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// B23 · Conversación del personal: burbujas por día, fotos, cargar
/// anteriores al subir y escribir abajo. Archivada = solo lectura.
class ChatThreadPage extends ConsumerWidget {
  const ChatThreadPage({super.key, required this.id, this.now});

  final String id;
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conv = ref.watch(conversationProvider(id)).valueOrNull;
    final r = conv?.reservation;
    final overline = r != null
        ? '${r.propertyCode} · ${r.code}'
        : (conv?.isGroup ?? false)
        ? 'Grupo · ${conv!.participants.length} personas'
        : 'Chat';
    return HrPage(
      title: conv?.title.isNotEmpty == true ? conv!.title : 'Conversación',
      overline: overline,
      trailing: conv == null
          ? null
          : AppIconButton(
              icon: conv.muted ? CustomIcons.muted : CustomIcons.notifications,
              semanticLabel: conv.muted ? 'Activar avisos' : 'Silenciar',
              onPressed: () async {
                try {
                  await ref.read(chatRepositoryProvider).mute(id, !conv.muted);
                  ref.invalidate(conversationProvider(id));
                  if (context.mounted) {
                    showToast(context, conv.muted ? 'Avisos activados.' : 'Conversación silenciada.');
                  }
                } on Object catch (e) {
                  if (context.mounted) showToast(context, errorMessage(e));
                }
              },
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (r != null) _ReservationStrip(reservation: r),
          Expanded(
            child: _ThreadView(
              threadId: id,
              now: now,
              showSenders: conv == null || conv.isGroup || conv.isGuest,
              archived: conv?.isArchived ?? false,
              allowPhotos: true,
              archivedText: 'Conversación archivada. Ya no se puede escribir.',
            ),
          ),
        ],
      ),
    );
  }
}

/// F8 · Chat del huésped con la empresa (solo texto).
class GuestChatPage extends ConsumerWidget {
  const GuestChatPage({super.key, this.now});

  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = guestMeOf(ref.watch(guestSessionProvider));
    final info = ref.watch(guestChatInfoProvider).valueOrNull;
    return HrPage(
      title: me?.tenantName.isNotEmpty == true ? me!.tenantName : 'Anfitrión',
      overline: 'Chat de tu estancia',
      body: _ThreadView(
        threadId: guestThread,
        now: now,
        showSenders: true,
        archived: info?.isArchived ?? false,
        allowPhotos: false,
        archivedText: 'Tu estancia terminó. Para algo más, escribe a la empresa por correo.',
        emptyText: 'Escribe aquí si necesitas algo durante tu estancia. Te responde el equipo.',
      ),
    );
  }
}

class _ReservationStrip extends StatelessWidget {
  const _ReservationStrip({required this.reservation});

  final ChatReservation reservation;

  @override
  Widget build(BuildContext context) {
    String d(DateTime x) => '${x.day}/${x.month}';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CustomColors.surface,
        borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
        border: Border.all(color: CustomColors.border),
      ),
      child: Row(
        children: [
          const Icon(CustomIcons.property, size: 18, color: CustomColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${reservation.guestName} · ${reservation.propertyName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CustomTypography.bodySmall.copyWith(color: CustomColors.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          Text('${d(reservation.checkIn)} – ${d(reservation.checkOut)}', style: CustomTypography.label),
        ],
      ),
    );
  }
}

class _ThreadView extends ConsumerStatefulWidget {
  const _ThreadView({
    required this.threadId,
    required this.showSenders,
    required this.archived,
    required this.allowPhotos,
    required this.archivedText,
    this.emptyText = 'Aún no hay mensajes. Escribe el primero.',
    this.now,
  });

  final String threadId;
  final bool showSenders;
  final bool archived;
  final bool allowPhotos;
  final String archivedText;
  final String emptyText;
  final DateTime? now;

  @override
  ConsumerState<_ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends ConsumerState<_ThreadView> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  late final _photo = DraftPhotos('chat-${widget.threadId}', entity: 'chat');
  late final UploadQueue _queue;

  @override
  void initState() {
    super.initState();
    _queue = ref.read(uploadQueueProvider);
    _text.addListener(() => setState(() {}));
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 200) {
        ref.read(chatThreadProvider(widget.threadId).notifier).loadOlder();
      }
    });
  }

  @override
  void dispose() {
    if (widget.allowPhotos) _photo.discard(_queue);
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  ImageProvider? _image(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('/') || url.startsWith('file:')) return FileImage(File(url.replaceFirst('file://', '')));
    return NetworkImage(url);
  }

  void _openImage(ImageProvider image) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                child: Image(image: image, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: SafeArea(
                child: IconButton(
                  tooltip: 'Cerrar',
                  color: Colors.white,
                  icon: const Icon(CustomIcons.close),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(List<PendingUpload> photos) async {
    final body = _text.text.trim();
    final photo = photos.isEmpty ? null : photos.first;
    if (body.isEmpty && photo?.fileId == null) return;
    _text.clear();
    final ok = await ref
        .read(chatThreadProvider(widget.threadId).notifier)
        .send(body: body, fileId: photo?.fileId, previewUrl: photo?.localPath);
    if (photo != null && ok) await _queue.remove(photo.id);
    if (!ok && mounted) showToast(context, 'No se pudo enviar. Toca el mensaje para reintentar.');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatThreadProvider(widget.threadId));
    final ctrl = ref.read(chatThreadProvider(widget.threadId).notifier);
    final photos = widget.allowPhotos ? _photo.of(ref) : const <PendingUpload>[];
    final now = widget.now ?? DateTime.now();
    final photoReady = photos.isNotEmpty && DraftPhotos.allUploaded(photos);
    final canSend = _text.text.trim().isNotEmpty ? (photos.isEmpty || photoReady) : photoReady;

    Widget list;
    if (state.messages.isEmpty && state.loading) {
      list = const Center(child: CircularProgressIndicator(color: CustomColors.primary));
    } else if (state.messages.isEmpty && state.error != null) {
      list = hrError(state.error, ctrl.refresh);
    } else if (state.messages.isEmpty) {
      list = ListView(
        padding: const EdgeInsets.all(16),
        children: [EmptyState(icon: CustomIcons.forum, title: 'Sin mensajes', message: widget.emptyText)],
      );
    } else {
      final items = _buildItems(state.messages, now);
      list = ListView.builder(
        controller: _scroll,
        reverse: true,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        itemCount: items.length + (state.loadingOlder ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == items.length) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            );
          }
          return items[i];
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: list),
        ChatComposer(
          controller: _text,
          enabled: !widget.archived,
          disabledText: widget.archivedText,
          canSend: canSend,
          hintText: widget.allowPhotos ? 'Escribe un mensaje' : 'Escribe tu mensaje',
          onSend: () => _send(photos),
          onCamera: !widget.allowPhotos || photos.isNotEmpty
              ? null
              : () =>
                    _photo.take(context, ref, module: 'chat', kind: 'image', title: 'Foto para el chat', maxPhotos: 1),
          attachment: photos.isEmpty ? null : _Attachment(upload: photos.first, queue: _queue),
        ),
      ],
    );
  }

  /// Lista invertida (lo más nuevo primero) con un separador por día.
  List<Widget> _buildItems(List<ChatMessage> messages, DateTime now) {
    final out = <Widget>[];
    for (var i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      final prev = i > 0 ? messages[i - 1] : null;
      final sameDay =
          prev != null &&
          prev.createdAt.year == m.createdAt.year &&
          prev.createdAt.month == m.createdAt.month &&
          prev.createdAt.day == m.createdAt.day;
      final grouped =
          sameDay &&
          !prev.isSystem &&
          !m.isSystem &&
          prev.mine == m.mine &&
          prev.senderId == m.senderId &&
          m.createdAt.difference(prev.createdAt).inMinutes < 5;
      final image = _image(m.fileUrl);
      out.add(
        ChatBubble(
          key: ValueKey(m.id),
          mine: m.mine,
          time: chatTime(m.createdAt),
          body: m.body,
          sender: widget.showSenders && !m.mine && !grouped && m.senderName.isNotEmpty ? m.senderName : null,
          image: image,
          system: m.isSystem,
          grouped: grouped,
          state: switch (m.state) {
            MessageState.sent => ChatSendState.sent,
            MessageState.sending => ChatSendState.sending,
            MessageState.failed => ChatSendState.failed,
          },
          onRetry: m.state == MessageState.failed
              ? () => ref.read(chatThreadProvider(widget.threadId).notifier).retry(m)
              : null,
          onOpenImage: image == null ? null : () => _openImage(image),
        ),
      );
      if (!sameDay) out.add(ChatDayDivider(label: chatDayLabel(m.createdAt, now)));
    }
    return out;
  }
}

/// La foto por mandar, con su estado de subida y para quitarla.
class _Attachment extends StatelessWidget {
  const _Attachment({required this.upload, required this.queue});

  final PendingUpload upload;
  final UploadQueue queue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PhotoThumb(
          image: FileImage(File(upload.localPath)),
          size: 64,
          status: switch (upload.status) {
            UploadStatus.queued => PhotoUploadStatus.queued,
            UploadStatus.uploading => PhotoUploadStatus.uploading,
            UploadStatus.done => PhotoUploadStatus.done,
            UploadStatus.error => PhotoUploadStatus.error,
          },
          progress: upload.progress,
          onRetry: () => queue.retry(upload.id),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(switch (upload.status) {
            UploadStatus.done => 'Foto lista para enviar',
            UploadStatus.error => upload.lastError ?? 'No se pudo subir. Toca para reintentar.',
            _ => 'Subiendo foto…',
          }, style: CustomTypography.bodySmall),
        ),
        AppIconButton(icon: CustomIcons.close, semanticLabel: 'Quitar foto', onPressed: () => queue.remove(upload.id)),
      ],
    );
  }
}
