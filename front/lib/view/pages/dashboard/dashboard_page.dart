import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../models/person.dart';
import '../../../providers/app_provider.dart';
import '../../../service/family_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFamily());
  }

  Future<void> _loadFamily() async {
    final f = await FamilyService.instance.getMyFamily();
    if (!mounted) return;
    if (f != null && f.allMembers.isNotEmpty) {
      context.read<SelectedMemberProvider>().setFamily(f);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedMemberProvider>(
      builder: (context, provider, _) {
        final person = provider.selectedPerson;
        final isChild = provider.selectedIndex >= 2;
        final members = provider.family.allMembers;

        if (person == null || members.isEmpty) {
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
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Aucun membre. Ajoutez des membres depuis l\'API ou utilisez les données démo.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isChild
                  ? [
                      const Color(0xFFE8F5E9),
                      const Color(0xFFF1F8E9),
                      Colors.white,
                    ]
                  : [
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tableau de bord',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Family members carousel
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: members.length,
                            itemBuilder: (context, index) {
                              final p = members[index];
                              final selected = index == provider.selectedIndex;
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: GestureDetector(
                                  onTap: () => provider.selectMember(index),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: selected
                                                ? AppColors.primaryColor
                                                : Colors.grey.shade300,
                                            width: selected ? 3 : 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primaryColor
                                                  .withValues(alpha: 0.2),
                                              blurRadius: selected ? 12 : 4,
                                              spreadRadius: selected ? 2 : 0,
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          backgroundColor: selected
                                              ? AppColors.primaryLight
                                                  .withValues(alpha: 0.3)
                                              : Colors.grey.shade200,
                                          child: Text(
                                            p.name.isNotEmpty
                                                ? p.name[0].toUpperCase()
                                                : '?',
                                            style: GoogleFonts.poppins(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryDark,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          p.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: selected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: selected
                                                ? AppColors.primaryColor
                                                : AppColors.textSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Biometrics carousel (PageView)
                        _sectionTitle('Biométrie'),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 140,
                          child: PageView(
                            children: [
                              _biometricCard1(person),
                              _biometricCard2(person),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Vitals carousel
                        _sectionTitle('Vitalité'),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 130,
                          child: PageView(
                            children: [
                              _sugarCard(person),
                              _bpHeartCard(person),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Safety card
                        _sectionTitle('Sécurité'),
                        const SizedBox(height: 12),
                        _safetyCard(person),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _biometricCard1(Person p) {
    return _softCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _metricItem('IMC', p.bmi.toStringAsFixed(1), 'kg/m²'),
              _metricItem('Taille', '${(p.height * 100).round()}', 'cm'),
              _metricItem('Poids', '${p.weight.round()}', 'kg'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _biometricCard2(Person p) {
    return _softCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bloodtype, color: AppColors.primaryColor, size: 28),
              const SizedBox(width: 12),
              Text(
                'Groupe ${p.bloodType}${p.rhFactor}',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (p.age < 18 && !p.vaccinesUpToDate)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Vaccins à mettre à jour',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.sugarWarning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value $unit',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Color _sugarColor(double gPerL) {
    if (gPerL <= 1.10) return AppColors.sugarNormal;
    if (gPerL <= 1.40) return AppColors.sugarWarning;
    return AppColors.sugarHigh;
  }

  Widget _sugarCard(Person p) {
    final color = _sugarColor(p.sugarLevel);
    return _softCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Glycémie',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${p.sugarLevel.toStringAsFixed(2)} g/L',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.monitor_heart, color: color, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _bpHeartCard(Person p) {
    return _softCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tension',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${p.systolicBP}/${p.diastolicBP}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Fréquence cardiaque',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${p.heartRate} bpm',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _safetyCard(Person p) {
    return _softCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.sugarWarning, size: 22),
              const SizedBox(width: 8),
              Text(
                'Allergies',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            p.allergies.isEmpty
                ? 'Aucune connue'
                : p.allergies.join(', '),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.medical_services,
                  color: AppColors.primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Maladies chroniques',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            p.chronicDiseases.isEmpty
                ? 'Aucune'
                : p.chronicDiseases.join(', '),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _softCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
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
      child: child,
    );
  }
}
