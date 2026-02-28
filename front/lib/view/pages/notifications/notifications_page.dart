import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../providers/app_provider.dart';

enum NotificationType { healthAlert, vaccineReminder }

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime date;
  final String? memberName;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.date,
    this.memberName,
  });
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SelectedMemberProvider>();
    final family = provider.family;

    // Build notifications from family data (logical alerts)
    final items = <NotificationItem>[];

    for (final p in family.allMembers) {
      if (p.sugarLevel > 1.40) {
        items.add(NotificationItem(
          id: 'sugar-${p.name}',
          type: NotificationType.healthAlert,
          title: 'Glycémie élevée',
          body: 'La glycémie de ${p.name} est élevée (${p.sugarLevel.toStringAsFixed(2)} g/L). Pensez à consulter.',
          date: DateTime.now().subtract(const Duration(hours: 2)),
          memberName: p.name,
        ));
      }
      if (p.systolicBP >= 140 || p.diastolicBP >= 90) {
        items.add(NotificationItem(
          id: 'bp-${p.name}',
          type: NotificationType.healthAlert,
          title: 'Tension à surveiller',
          body: 'La tension de ${p.name} (${p.systolicBP}/${p.diastolicBP}) est au-dessus de la normale.',
          date: DateTime.now().subtract(const Duration(hours: 5)),
          memberName: p.name,
        ));
      }
      if (p.age < 18 && !p.vaccinesUpToDate) {
        items.add(NotificationItem(
          id: 'vaccine-${p.name}',
          type: NotificationType.vaccineReminder,
          title: 'Rappel vaccinal',
          body: 'Les vaccins de ${p.name} ne sont pas à jour. Prenez rendez-vous avec un pédiatre.',
          date: DateTime.now().subtract(const Duration(days: 1)),
          memberName: p.name,
        ));
      }
    }

    // Demo reminder if no alerts
    if (items.isEmpty) {
      items.add(NotificationItem(
        id: 'demo',
        type: NotificationType.vaccineReminder,
        title: 'Rappel vaccinal',
        body: 'Vérifiez le carnet de vaccination de tous les enfants.',
        date: DateTime.now(),
      ));
    }

    items.sort((a, b) => b.date.compareTo(a.date));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundGradient.colors[0],
            Colors.white,
          ],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text(
                  'Notifications',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = items[index];
                  return _NotificationCard(item: item);
                },
                childCount: items.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;

  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isAlert = item.type == NotificationType.healthAlert;
    final icon = isAlert ? Icons.warning_amber_rounded : Icons.vaccines;
    final color = isAlert ? AppColors.sugarWarning : AppColors.primaryColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.radiusCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          item.title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            item.body,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        trailing: Text(
          _formatDate(item.date),
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return '${d.day}/${d.month}';
  }
}
