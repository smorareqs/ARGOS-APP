import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/hr/data/hr_repository.dart';
import 'package:argos_app/features/hr/models/hr.dart';
import 'package:argos_app/features/hr/presentation/widgets/hr_widgets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// B20 · Mis boletas: una por período cerrado con el líquido; al tocarla se
/// ve el detalle (devengos y descuentos) y se abre el PDF.
class PayslipsPage extends ConsumerWidget {
  const PayslipsPage({super.key, this.openId});

  /// Boleta a abrir al entrar (aviso "Tu boleta está lista").
  final String? openId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(payslipsProvider);
    final list = async.valueOrNull;
    Future<void> refresh() => ref.refresh(payslipsProvider.future).then((_) {}, onError: (_) {});

    Widget body;
    if (list == null && async.isLoading) {
      body = hrLoading(first: 140);
    } else if (list == null) {
      body = hrError(async.error, refresh);
    } else if (list.isEmpty) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 40),
          EmptyState(
            icon: CustomIcons.document,
            title: 'Aún no tienes boletas',
            message: 'Cuando RRHH cierre la nómina, tu boleta aparece aquí y te avisamos.',
          ),
        ],
      );
    } else {
      final last = list.first;
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _LatestCard(slip: last, onTap: () => showPayslip(context, last)),
          if (list.length > 1) ...[
            const SizedBox(height: 22),
            const SectionHeader(title: 'Anteriores'),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final s in list.skip(1))
                    AppListTile(
                      icon: CustomIcons.document,
                      title: s.periodName,
                      subtitle: s.basis,
                      trailing: Text(quetzales(s.net), style: CustomTypography.data.copyWith(fontSize: 15)),
                      onTap: () => showPayslip(context, s),
                    ),
                ],
              ),
            ),
          ],
        ],
      );
      if (openId != null) {
        final target = list.where((s) => s.id == openId).firstOrNull;
        if (target != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && ModalRoute.of(context)?.isCurrent == true) showPayslip(context, target);
          });
        }
      }
    }

    return HrPage(title: 'Mis boletas', overline: 'Nómina', onRefresh: refresh, body: body);
  }
}

class _LatestCard extends StatelessWidget {
  const _LatestCard({required this.slip, required this.onTap});

  final Payslip slip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CustomColors.primary,
      borderRadius: BorderRadius.circular(CustomDimensions.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(CustomDimensions.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ÚLTIMA BOLETA', style: CustomTypography.label.copyWith(color: Colors.white70, letterSpacing: 1.2, fontSize: 11.5)),
              const SizedBox(height: 4),
              Text(slip.periodName, style: CustomTypography.cardTitle.copyWith(color: Colors.white, fontSize: 17)),
              const SizedBox(height: 14),
              Text('Recibes', style: CustomTypography.bodySmall.copyWith(color: Colors.white70)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(quetzales(slip.net), style: CustomTypography.display.copyWith(color: Colors.white, fontSize: 38, height: 1.1)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${slip.basis} · Total ${quetzales(slip.gross)}',
                      style: CustomTypography.bodySmall.copyWith(color: Colors.white70),
                    ),
                  ),
                  Text('Ver detalle', style: CustomTypography.label.copyWith(color: CustomColors.secondary)),
                  const Icon(CustomIcons.chevronRight, color: CustomColors.secondary, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// PayslipViewer: devengos, descuentos, líquido y el PDF.
Future<void> showPayslip(BuildContext context, Payslip s) => showArgosSheet<void>(
  context,
  builder: (sheetContext) => SheetScaffold(
    title: s.periodName,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.basis, style: CustomTypography.bodySmall),
          const SizedBox(height: 14),
          _Block(title: 'Ingresos', lines: s.lines, total: ('Total ingresos', s.gross)),
          const SizedBox(height: 12),
          _Block(title: 'Descuentos', lines: s.deductions, total: ('Total descuentos', s.totalDeductions), negative: true),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: CustomColors.tealWashed, borderRadius: BorderRadius.circular(CustomDimensions.radiusCard)),
            child: Row(
              children: [
                Expanded(child: Text('Líquido a recibir', style: CustomTypography.cardTitle.copyWith(fontSize: 16))),
                Text(quetzales(s.net), style: CustomTypography.data.copyWith(fontSize: 20, color: CustomColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (s.url != null)
            SecondaryButton(
              label: 'Abrir boleta en PDF',
              onPressed: () async {
                final ok = await launchUrl(Uri.parse(s.url!), mode: LaunchMode.externalApplication);
                if (!ok && sheetContext.mounted) showToast(sheetContext, 'No se pudo abrir el PDF.');
              },
            )
          else
            Text(
              'El PDF firmado lo descarga RRHH desde la web; pídelo si lo necesitas.',
              style: CustomTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    ),
  ),
);

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.lines, required this.total, this.negative = false});

  final String title;
  final List<(String, double)> lines;
  final (String, double) total;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title.toUpperCase(), style: CustomTypography.label.copyWith(color: CustomColors.textMuted, letterSpacing: 1.1)),
          const SizedBox(height: 8),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(l.$1, style: CustomTypography.body)),
                  Text('${negative && l.$2 > 0 ? '−' : ''}${quetzales(l.$2)}', style: CustomTypography.data.copyWith(fontSize: 14.5)),
                ],
              ),
            ),
          const Divider(height: 18, color: CustomColors.divider),
          Row(
            children: [
              Expanded(
                child: Text(total.$1, style: CustomTypography.label.copyWith(color: CustomColors.textPrimary)),
              ),
              Text(
                '${negative && total.$2 > 0 ? '−' : ''}${quetzales(total.$2)}',
                style: CustomTypography.data.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
