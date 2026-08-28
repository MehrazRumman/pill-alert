import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../domain/models.dart';
import '../../navigation/nav_actions.dart';
import '../../theme/theme.dart';
import '../components/scaffold.dart';

/// Stable signature of the notifications the inbox derives, so "mark all read" and the Home bell's
/// unread dot are computed from exactly one definition and cannot drift apart.
String inboxSignature(List<Medicine> medicines, List<StockStatus> stock) {
  final low = stock.where((s) => s.isLow).map((s) => s.medicineId).toSet();
  final ids = medicines.where((m) => low.contains(m.id)).map((m) => m.id).toList()..sort();
  return ids.join('|');
}

/// Whether the inbox holds anything the patient has not yet marked read.
bool hasUnreadInbox(List<Medicine> medicines, List<StockStatus> stock, String readSignature) {
  final signature = inboxSignature(medicines, stock);
  return signature.isNotEmpty && signature != readSignature;
}

class _InboxItem {
  const _InboxItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.amber,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool amber;
  final VoidCallback? onTap;
}

/// Notification inbox (6b): day-grouped; unread carries a 4px warm left rule, read drops to 72%.
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final settingsStore = context.settingsStore;

    return Scaffold(
      backgroundColor: colors.paper,
      body: ListenableBuilder(
        listenable: settingsStore,
        builder: (context, _) => RepoBuilder<(List<Medicine>, List<StockStatus>)>(
          query: (repo) async => (await repo.medicines(), await repo.stockStatuses()),
          builder: (context, data) {
            final (meds, stock) = data;
            // Real, derived notifications only — one low-stock note per medicine running low.
            final lowMeds = meds
                .where((m) => stock.any((s) => s.medicineId == m.id && s.isLow))
                .toList();
            final today = lowMeds
                .map((m) => _InboxItem(
                      icon: Icons.inventory_2,
                      title: context.tr(
                        '${m.displayName} ফুরিয়ে আসছে',
                        '${m.displayName} running low', hi: '${m.displayName} कम पड़ रही है', es: 'Queda poco de ${m.displayName}',
                      ),
                      body: context.tr('রিফিলে গিয়ে মজুত ঠিক করুন', 'Open Refill to update stock'),
                      amber: true,
                      onTap: context.nav.openRefill,
                    ))
                .toList();
            const earlier = <_InboxItem>[];

            final signature = inboxSignature(meds, stock);
            final allRead =
                signature.isNotEmpty && settingsStore.value.inboxReadSignature == signature;
            final canMarkRead = signature.isNotEmpty && !allRead;

            return Column(
              children: [
                NirbhorTopBar(
                  title: context.tr('খবর', 'Notifications'),
                  onBack: context.nav.back,
                  trailing: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: canMarkRead
                        ? () => settingsStore.setInboxReadSignature(signature)
                        : null,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: Dimens.tapMin),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                      child: Text(
                        context.tr('সব পড়া হয়েছে', 'Mark all read'),
                        style: context.type.cardTitleSecondary.copyWith(
                          // Dim when there is nothing left to mark, so the tap target reads as inert.
                          color: canMarkRead ? colors.calm : colors.ink3,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimens.screenPadding,
                      vertical: 12,
                    ),
                    child: SafeArea(
                      top: false,
                      child: today.isEmpty && earlier.isEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 40),
                                Text(
                                  context.tr('এখন কোনো খবর নেই', 'No notifications yet'),
                                  style: context.type.cardTitlePrimary.copyWith(color: colors.ink),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  context.tr(
                                    'ওষুধ ও মজুতের খবর এখানে আসবে।',
                                    'Dose and stock alerts will appear here.',
                                  ),
                                  style: context.type.body.copyWith(color: colors.ink3),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _InboxGroup(
                                  label: context.tr('আজ', 'Today'),
                                  items: today,
                                  read: allRead,
                                ),
                                const _InboxGroup(label: '', items: earlier, read: true),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InboxGroup extends StatelessWidget {
  const _InboxGroup({required this.label, required this.items, required this.read});

  final String label;
  final List<_InboxItem> items;
  final bool read;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: context.type.sectionLabel.copyWith(color: colors.ink3)),
          const SizedBox(height: Dimens.cardGap),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimens.cardGap),
              child: Opacity(
                opacity: read ? 0.72 : 1,
                child: Material(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(Dimens.radiusCard),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: item.onTap,
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            color: read ? Colors.transparent : colors.warm,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: item.amber ? colors.warmSoft : colors.calmSoft,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      size: 20,
                                      color: item.amber ? colors.warmD : colors.calmD,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.title,
                                          style: context.type.cardTitleSecondary
                                              .copyWith(color: colors.ink),
                                        ),
                                        Text(
                                          item.body,
                                          style: context.type.meta.copyWith(color: colors.ink3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
