import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../models/ai_response.dart';
import '../../../providers/app_provider.dart';
import '../../../service/ai_service.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

enum _MsgKind { user, ai, doctors, nutrition, mealAnalysis, loading }

class _Msg {
  final _MsgKind kind;
  final String? text;
  final List<AiPlace>? doctors;
  final AiNutrition? nutrition;
  final AiMealAnalysis? mealAnalysis;
  const _Msg({required this.kind, this.text, this.doctors, this.nutrition, this.mealAnalysis});
}

class _AiAssistantPageState extends State<AiAssistantPage>
    with TickerProviderStateMixin {
  final List<_Msg> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late AnimationController _pulseController;
  bool _sending = false;
  String? _pendingImageBase64;
  String? _pendingImageName;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _messages.add(const _Msg(
      kind: _MsgKind.ai,
      text: 'Bonjour\u00a0! Je suis votre assistant sant\u00e9 familial. '
          'Je peux analyser votre profil, sugg\u00e9rer des m\u00e9decins proches, '
          'cr\u00e9er un plan nutritionnel ou analyser votre repas en photo. '
          'Posez-moi une question\u00a0!',
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _pulseController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool _hasAnomaly() {
    final p = context.read<SelectedMemberProvider>().selectedPerson;
    if (p == null) return false;
    return p.sugarLevel > 1.40 || p.systolicBP >= 140 || p.diastolicBP >= 90;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send({
    required String userText,
    bool includeDoctors = false,
    bool includeNutrition = false,
  }) async {
    if (_sending) return;
    final person = context.read<SelectedMemberProvider>().selectedPerson;
    setState(() {
      _sending = true;
      _messages.add(_Msg(kind: _MsgKind.user, text: userText));
      _messages.add(const _Msg(kind: _MsgKind.loading));
    });
    _scrollToBottom();

    AiAssistantResponse? response;
    try {
      response = await AiService.instance
          .chat(
            personId: person?.id,
            includeDoctors: includeDoctors,
            includeNutrition: includeNutrition,
            imageBase64: _pendingImageBase64,
            userMessage: userText,
          )
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      response = null;
    }

    if (!mounted) return;
    setState(() {
      _sending = false;
      _pendingImageBase64 = null;
      _pendingImageName = null;
      _messages.removeWhere((m) => m.kind == _MsgKind.loading);

      if (response == null) {
        _messages.add(const _Msg(
          kind: _MsgKind.ai,
          text: 'Impossible de joindre le serveur. V\u00e9rifiez la connexion ou le backend.',
        ));
        return;
      }
      if (response.note != null && response.note!.isNotEmpty) {
        _messages.add(_Msg(kind: _MsgKind.ai, text: response.note));
      }
      if (response.mealAnalysis != null) {
        _messages.add(_Msg(kind: _MsgKind.mealAnalysis, mealAnalysis: response.mealAnalysis));
      }
      if (response.nutrition != null) {
        _messages.add(_Msg(kind: _MsgKind.nutrition, nutrition: response.nutrition));
      }
      if (response.doctors.isNotEmpty) {
        _messages.add(_Msg(kind: _MsgKind.doctors, doctors: response.doctors));
      }
      if (response.note == null && response.nutrition == null &&
          response.doctors.isEmpty && response.mealAnalysis == null) {
        _messages.add(const _Msg(
          kind: _MsgKind.ai,
          text: 'Votre profil a \u00e9t\u00e9 analys\u00e9. Tout semble normal\u00a0!',
        ));
      }
    });
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    try {
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes == null) return;
        setState(() {
          _pendingImageBase64 = base64Encode(bytes);
          _pendingImageName = file.name;
        });
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 75,
          maxWidth: 1024,
        );
        if (picked == null) return;
        final bytes = await picked.readAsBytes();
        setState(() {
          _pendingImageBase64 = base64Encode(bytes);
          _pendingImageName = picked.name;
        });
      }
    } catch (_) {}
  }

  void _sendTyped() {
    final t = _textController.text.trim();
    if (t.isEmpty && _pendingImageBase64 == null) return;
    _textController.clear();
    final text = t.isEmpty ? 'Analyse mon repas' : t;
    // Let the backend LLM decide which tools to use based on the message
    _send(userText: text, includeDoctors: true, includeNutrition: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedMemberProvider>(
      builder: (context, provider, _) {
        final hasAnomaly = _hasAnomaly();
        return Container(
          color: const Color(0xFFF0F4F8),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(provider, hasAnomaly),
                _buildMemberBar(provider),
                _buildQuickActions(),
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildBubble(_messages[i]),
                  ),
                ),
                if (_pendingImageBase64 != null) _buildImagePreviewBar(),
                _buildInputBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(SelectedMemberProvider provider, bool hasAnomaly) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00897B), Color(0xFF00ACC1)],
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) {
              final glow = hasAnomaly ? _pulseController.value * 6 : 0.0;
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.4),
                      blurRadius: 8 + glow,
                      spreadRadius: glow / 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.health_and_safety, color: Colors.white, size: 26),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assistant Sant\u00e9',
                    style: GoogleFonts.poppins(
                        fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                Row(children: [
                  Container(
                    width: 7, height: 7,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      color: hasAnomaly ? const Color(0xFFFFCC02) : const Color(0xFF69F0AE),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      hasAnomaly ? 'Anomalie d\u00e9tect\u00e9e' : 'En ligne \u00b7 IA active',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberBar(SelectedMemberProvider provider) {
    final members = provider.family.allMembers;
    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        itemBuilder: (_, i) {
          final m = members[i];
          final selected = provider.selectedIndex == i;
          return GestureDetector(
            onTap: () => provider.selectMember(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(colors: [Color(0xFF00897B), Color(0xFF00ACC1)])
                    : null,
                color: selected ? null : const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: selected
                        ? Colors.white.withValues(alpha: 0.3)
                        : AppColors.primaryLight.withValues(alpha: 0.2),
                    child: Text(
                      m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : AppColors.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(m.name.split(' ').first,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.textPrimary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
        child: Row(
          children: [
            _QuickChip(
              icon: Icons.monitor_heart, label: 'Bilan sant\u00e9',
              color: const Color(0xFF00897B),
              onTap: () => _send(userText: 'Faites un bilan sant\u00e9 complet.', includeDoctors: true, includeNutrition: true),
            ),
            const SizedBox(width: 8),
            _QuickChip(
              icon: Icons.person_search, label: 'M\u00e9decin',
              color: const Color(0xFF0288D1),
              onTap: () => _send(userText: 'Trouvez un m\u00e9decin sp\u00e9cialiste proche.', includeDoctors: true),
            ),
            const SizedBox(width: 8),
            _QuickChip(
              icon: Icons.restaurant_menu, label: 'Nutrition',
              color: const Color(0xFFE53935),
              onTap: () => _send(userText: 'Donnez-moi un plan nutritionnel personnalis\u00e9.', includeNutrition: true),
            ),
            const SizedBox(width: 8),
            _QuickChip(
              icon: Icons.camera_enhance, label: 'Analyser repas',
              color: const Color(0xFF7B1FA2),
              onTap: () async {
                await _pickImage();
                if (_pendingImageBase64 != null) {
                  _send(userText: 'Analyse mon repas en photo.', includeNutrition: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreviewBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.primaryLight.withValues(alpha: 0.15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(_pendingImageBase64!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.image, size: 20, color: AppColors.primaryColor),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Image jointe',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(_pendingImageName ?? 'photo.jpg',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() { _pendingImageBase64 = null; _pendingImageName = null; }),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 13, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final hasImage = _pendingImageBase64 != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _sending ? null : _pickImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hasImage ? AppColors.primaryColor : const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasImage ? Icons.image_rounded : Icons.add_photo_alternate_outlined,
                size: 22,
                color: hasImage ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: hasImage ? 'Commentaire\u2026 (optionnel)' : '\u00c9crivez un message\u2026',
                  hintStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendTyped(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : _sendTyped,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                gradient: _sending ? null : const LinearGradient(colors: [Color(0xFF00897B), Color(0xFF00ACC1)]),
                color: _sending ? Colors.grey.shade300 : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _sending
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_Msg msg) {
    switch (msg.kind) {
      case _MsgKind.user: return _userBubble(msg.text!);
      case _MsgKind.ai: return _aiBubble(msg.text!);
      case _MsgKind.loading: return _loadingBubble();
      case _MsgKind.doctors: return _doctorsBubble(msg.doctors!);
      case _MsgKind.nutrition: return _nutritionBubble(msg.nutrition!);
      case _MsgKind.mealAnalysis: return _mealBubble(msg.mealAnalysis!);
    }
  }

  Widget _userBubble(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 48),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF00897B), Color(0xFF00ACC1)]),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(text, style: GoogleFonts.inter(fontSize: 14, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _aiBubble(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28, height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF00897B), Color(0xFF00ACC1)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.health_and_safety, color: Colors.white, size: 15),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4), topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Text(text, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28, height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF00897B), Color(0xFF00ACC1)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.health_and_safety, color: Colors.white, size: 15),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4), topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DotPulse(),
                const SizedBox(width: 10),
                Text('Analyse en cours\u2026',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _doctorsBubble(List<AiPlace> doctors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF0288D1).withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF0288D1), Color(0xFF26C6DA)]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(children: [
                const Icon(Icons.local_hospital, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('M\u00e9decins recommand\u00e9s',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ]),
            ),
            ...doctors.map((d) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: const Color(0xFF0288D1).withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: Color(0xFF0288D1), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        if (d.address != null)
                          Text(d.address!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  if (d.openNow != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: d.openNow! ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(d.openNow! ? 'Ouvert' : 'Ferm\u00e9',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                              color: d.openNow! ? AppColors.sugarNormal : AppColors.sugarHigh)),
                    ),
                ],
              ),
            )),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _nutritionBubble(AiNutrition n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFFE53935).withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF7043)]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(children: [
                const Icon(Icons.restaurant_menu, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(n.title,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.description, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                  if (n.shoppingList.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('\uD83D\uDED2 Liste de courses',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: n.shoppingList.map((item) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFF7043).withValues(alpha: 0.4)),
                        ),
                        child: Text(item, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFE64A19))),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealBubble(AiMealAnalysis m) {
    final ok = m.isCompatible;
    final color = ok ? const Color(0xFF43A047) : const Color(0xFFE53935);
    final bgColor = ok ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: bgColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
              child: Row(children: [
                Icon(ok ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded, color: color, size: 20),
                const SizedBox(width: 8),
                Text(ok ? '\u2705 Repas compatible' : '\u26a0\ufe0f Repas d\u00e9conseill\u00e9',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.reasoning, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                  if (m.alternativeSuggestion != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline, size: 14, color: Color(0xFF1565C0)),
                          const SizedBox(width: 6),
                          Expanded(child: Text(m.alternativeSuggestion!,
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1565C0)))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotPulse extends StatefulWidget {
  @override
  State<_DotPulse> createState() => _DotPulseState();
}

class _DotPulseState extends State<_DotPulse> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 900), vsync: this)..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_ctrl.value * 3 - i).clamp(0.0, 1.0);
            final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickChip({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}