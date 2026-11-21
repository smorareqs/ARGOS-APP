import 'dart:async';
import 'dart:io';

import 'package:argos_app/core/media/photo_processor.dart';
import 'package:camera/camera.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Qué se va a fotografiar.
class CameraRequest {
  const CameraRequest({
    this.title,
    this.propertyCode,
    this.reference,
    this.referenceLabel = 'Antes',
    this.maxPhotos,
  });

  /// Texto arriba ("Tender la cama").
  final String? title;

  /// Va en la marca de agua.
  final String? propertyCode;

  /// Foto "antes" que se muestra semitransparente para encuadrar la
  /// "después" igual (ux-ui.md B5).
  final ImageProvider? reference;
  final String referenceLabel;
  final int? maxPhotos;
}

/// Abre la cámara a pantalla completa. Devuelve las fotos ya comprimidas y
/// con marca de agua (JPEG), o null si se cerró sin tomar ninguna.
Future<List<Uint8List>?> openCamera(
  BuildContext context, [
  CameraRequest request = const CameraRequest(),
]) {
  return Navigator.of(context, rootNavigator: true).push<List<Uint8List>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CameraPage(request: request),
    ),
  );
}

/// B5 · Cámara integrada (ux-ui.md §3.4): obturador de 72 dp, flash,
/// cambio de cámara, miniaturas de las últimas tomas y referencia "antes".
class CameraPage extends StatefulWidget {
  const CameraPage({super.key, this.request = const CameraRequest()});

  final CameraRequest request;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

enum _Problem { none, denied, noCamera, failed }

class _Shot {
  _Shot(this.future);

  final Future<Uint8List> future;
  Uint8List? bytes;
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  static const _dark = Color(0xFF0B1A1D);

  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  var _cameraIndex = 0;
  var _flash = FlashMode.auto;
  var _problem = _Problem.none;
  var _capturing = false;
  var _showReference = true;
  var _flashOverlay = false;
  final _shots = <_Shot>[];

  bool get _full =>
      widget.request.maxPhotos != null &&
      _shots.length >= widget.request.maxPhotos!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (state == AppLifecycleState.inactive) {
      _controller = null;
      controller?.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && controller == null) {
      _start();
    }
  }

  Future<void> _start() async {
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _problem = _Problem.noCamera);
        return;
      }
      if (_cameraIndex == 0) {
        final back = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        _cameraIndex = back < 0 ? 0 : back;
      }
      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      try {
        await controller.setFlashMode(_flash);
      } on CameraException {
        // Cámaras sin flash (la frontal casi siempre).
      }
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _problem = _Problem.none;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(
        () => _problem = e.code.startsWith('CameraAccess')
            ? _Problem.denied
            : _Problem.failed,
      );
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final current = _cameras[_cameraIndex].lensDirection;
    final next = _cameras.indexWhere((c) => c.lensDirection != current);
    final old = _controller;
    setState(() {
      _controller = null;
      _cameraIndex = next < 0 ? (_cameraIndex + 1) % _cameras.length : next;
    });
    await old?.dispose();
    await _start();
  }

  Future<void> _cycleFlash() async {
    final next = switch (_flash) {
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.off,
      _ => FlashMode.auto,
    };
    try {
      await _controller?.setFlashMode(next);
      setState(() => _flash = next);
    } on CameraException {
      _toast('Esta cámara no tiene flash.');
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing || _full) return;
    setState(() => _capturing = true);
    HapticFeedback.mediumImpact();
    try {
      final file = await controller.takePicture();
      setState(() => _flashOverlay = true);
      Future<void>.delayed(
        const Duration(milliseconds: 120),
        () => mounted ? setState(() => _flashOverlay = false) : null,
      );
      final takenAt = DateTime.now();
      final shot = _Shot(
        file.readAsBytes().then((raw) async {
          // El original sin comprimir no se guarda.
          unawaited(File(file.path).delete().then((_) {}, onError: (_) {}));
          return processPhoto(
            raw,
            takenAt: takenAt,
            propertyCode: widget.request.propertyCode,
          );
        }),
      );
      shot.future.then((bytes) {
        if (mounted) setState(() => shot.bytes = bytes);
      }, onError: (_) {
        if (!mounted) return;
        setState(() => _shots.remove(shot));
        _toast('No se pudo guardar la foto. Intenta de nuevo.');
      });
      setState(() => _shots.add(shot));
    } on CameraException {
      _toast('No se pudo tomar la foto. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _done() async {
    if (_shots.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final results = <Uint8List>[];
    for (final shot in List.of(_shots)) {
      try {
        results.add(await shot.future);
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).pop(results);
  }

  Future<bool> _confirmDiscard() async {
    if (_shots.isEmpty) return true;
    return showConfirmSheet(
      context,
      title: 'Descartar fotos',
      message:
          'Tomaste ${_shots.length} ${_shots.length == 1 ? 'foto' : 'fotos'} '
          'que todavía no se guardaron. Si sales, se pierden.',
      confirmLabel: 'Descartar',
      destructive: true,
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _shots.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: _dark,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildViewfinder(),
            if (_flashOverlay) const ColoredBox(color: Color(0x99FFFFFF)),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  const Spacer(),
                  if (_shots.isNotEmpty) _buildShotsStrip(),
                  _buildControls(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewfinder() {
    final controller = _controller;
    if (_problem != _Problem.none) return _buildProblem();
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: CustomColors.secondary),
      );
    }
    final size = controller.value.previewSize!;
    final reference = widget.request.reference;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              // previewSize viene en horizontal; el teléfono está vertical.
              width: size.height,
              height: size.width,
              child: CameraPreview(controller),
            ),
          ),
          if (reference != null)
            AnimatedOpacity(
              opacity: _showReference ? 0.35 : 0,
              duration: CustomMotion.resolve(context, CustomMotion.base),
              child: IgnorePointer(
                child: Image(image: reference, fit: BoxFit.cover),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProblem() {
    final (icon, title, message) = switch (_problem) {
      _Problem.denied => (
        CustomIcons.camera,
        'Permite usar la cámara',
        'ARGOS necesita la cámara para las fotos de evidencia. Actívala en '
            'Ajustes › Aplicaciones › ARGOS › Permisos y vuelve a intentar.',
      ),
      _Problem.noCamera => (
        CustomIcons.camera,
        'No hay cámara disponible',
        'Este teléfono no tiene una cámara que ARGOS pueda usar.',
      ),
      _ => (
        CustomIcons.error,
        'No se pudo abrir la cámara',
        'Cierra otras apps que la estén usando y vuelve a intentar.',
      ),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0x1FFFFFFF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: CustomColors.secondary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: CustomTypography.sectionTitle.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: CustomTypography.body.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            if (_problem != _Problem.noCamera) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Intentar de nuevo',
                isExpanded: false,
                onPressed: () {
                  setState(() => _problem = _Problem.none);
                  _start();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final hasFlash =
        _controller != null &&
        _cameras.isNotEmpty &&
        _cameras[_cameraIndex].lensDirection == CameraLensDirection.back;
    final reference = widget.request.reference;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          AppIconButton(
            icon: CustomIcons.close,
            semanticLabel: 'Cerrar cámara',
            color: Colors.white,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: widget.request.title == null
                ? const SizedBox.shrink()
                : Text(
                    widget.request.title!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CustomTypography.verdana(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          if (reference != null)
            _Pill(
              label: widget.request.referenceLabel,
              active: _showReference,
              onTap: () => setState(() => _showReference = !_showReference),
            ),
          if (hasFlash)
            AppIconButton(
              icon: switch (_flash) {
                FlashMode.always => CustomIcons.flashOn,
                FlashMode.off => CustomIcons.flashOff,
                _ => CustomIcons.flashAuto,
              },
              semanticLabel: switch (_flash) {
                FlashMode.always => 'Flash encendido',
                FlashMode.off => 'Flash apagado',
                _ => 'Flash automático',
              },
              color: Colors.white,
              onPressed: _cycleFlash,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildShotsStrip() {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _shots.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final shot = _shots[_shots.length - 1 - i];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: shot.bytes == null
                      ? const ColoredBox(
                          color: Color(0x33FFFFFF),
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Image.memory(
                          shot.bytes!,
                          fit: BoxFit.cover,
                          cacheWidth: 156,
                        ),
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: Semantics(
                  button: true,
                  label: 'Quitar foto',
                  child: GestureDetector(
                    onTap: () => setState(() => _shots.remove(shot)),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: CustomColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CustomIcons.close,
                        size: 14,
                        color: CustomColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    final count = _shots.length;
    final max = widget.request.maxPhotos;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _cameras.length > 1 && _problem == _Problem.none
                  ? Container(
                      decoration: const BoxDecoration(
                        color: Color(0x26FFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: AppIconButton(
                        icon: CustomIcons.cameraSwitch,
                        semanticLabel: 'Cambiar de cámara',
                        color: Colors.white,
                        onPressed: _switchCamera,
                      ),
                    )
                  : null,
            ),
          ),
          Expanded(
            child: Center(
              child: _Shutter(
                enabled: _controller != null && !_capturing && !_full,
                busy: _capturing,
                onPressed: _capture,
              ),
            ),
          ),
          SizedBox(
            width: 96,
            child: Align(
              alignment: Alignment.centerRight,
              child: count == 0
                  ? null
                  : Material(
                      color: CustomColors.secondary,
                      borderRadius: BorderRadius.circular(9999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(9999),
                        onTap: _done,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            max == null ? 'Listo · $count' : 'Listo · $count/$max',
                            style: CustomTypography.verdana(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Obturador de 72 dp: anillo blanco con centro que se encoge al tocar.
class _Shutter extends StatefulWidget {
  const _Shutter({
    required this.enabled,
    required this.busy,
    required this.onPressed,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onPressed;

  @override
  State<_Shutter> createState() => _ShutterState();
}

class _ShutterState extends State<_Shutter> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final duration = CustomMotion.resolve(context, CustomMotion.fast);
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: 'Tomar foto',
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _down = false);
                widget.onPressed();
              }
            : null,
        child: Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.enabled ? Colors.white : const Color(0x66FFFFFF),
              width: 4,
            ),
          ),
          child: AnimatedScale(
            scale: _down ? 0.86 : 1,
            duration: duration,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.enabled ? Colors.white : const Color(0x66FFFFFF),
              ),
              child: widget.busy
                  ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: CustomColors.primary,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: active,
      label: 'Mostrar foto $label como guía',
      child: Material(
        color: active ? CustomColors.secondary : const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(9999),
        child: InkWell(
          borderRadius: BorderRadius.circular(9999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CustomIcons.compare, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label.toUpperCase(),
                  style: CustomTypography.verdana(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
