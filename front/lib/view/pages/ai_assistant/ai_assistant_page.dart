import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../providers/app_provider.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage>
    with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  late AnimationController _heartController;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _messages.add(ChatMessage(
      isUser: false,
      text: 'Bonjour ! Je suis votre assistant santé familial. '
          'Vous pouvez me demander des conseils, scanner un repas, '
          'trouver un pédiatre ou vérifier des symptômes.',
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  bool _hasAnomaly() {
    final p = context.read<SelectedMemberProvider>().selectedPerson;
    if (p == null) return false;
    if (p.sugarLevel > 1.40) return true;
    if (p.systolicBP >= 140 || p.diastolicBP >= 90) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final hasAnomaly = _hasAnomaly();

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
        child: Column(
          children: [
            // Header with medical assistant icon (heartbeat when anomaly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  _AiIcon(heartController: _heartController, hasAnomaly: hasAnomaly),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assistant Santé',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          hasAnomaly
                              ? 'Anomalie détectée — posez-moi vos questions'
                              : 'En ligne',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: hasAnomaly
                                ? AppColors.sugarWarning
                                : AppColors.sugarNormal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Quick actions
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _quickAction(
                    icon: Icons.restaurant,
                    label: 'Scanner un repas',
                    onTap: () => _sendQuick('Scanner ce repas'),
                  ),
                  const SizedBox(width: 10),
                  _quickAction(
                    icon: Icons.child_care,
                    label: 'Trouver un pédiatre',
                    onTap: () => _sendQuick('Trouver un pédiatre proche'),
                  ),
                  const SizedBox(width: 10),
                  _quickAction(
                    icon: Icons.medical_services,
                    label: 'Vérifier symptômes',
                    onTap: () => _sendQuick('Vérifier mes symptômes'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Chat list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _chatBubble(_messages[index]);
                },
              ),
            ),
            // Input
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white.withValues(alpha: 0.95),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius:
                            BorderRadius.circular(AppStyles.radiusLarge),
                      ),
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Écrivez un message...',
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                    child: InkWell(
                      onTap: _sendMessage,
                      borderRadius:
                          BorderRadius.circular(AppStyles.radiusMedium),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.send, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendQuick(String text) {
    setState(() {
      _messages.add(ChatMessage(isUser: true, text: text));
      _messages.add(ChatMessage(
        isUser: false,
        text: 'Reçu. Pour l’instant je suis en mode démo — cette action sera '
            'connectée à un service réel (scan, carte, triage).',
      ));
    });
  }

  void _sendMessage() {
    final t = _textController.text.trim();
    if (t.isEmpty) return;
    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(isUser: true, text: t));
      _messages.add(ChatMessage(
        isUser: false,
        text: 'Merci pour votre message. En production, une IA analysera '
            'votre demande et vous répondra avec des conseils personnalisés.',
      ));
    });
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      elevation: 2,
      shadowColor: AppColors.primaryColor.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatBubble(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!msg.isUser) const SizedBox(width: 4),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: msg.isUser
                    ? AppColors.primaryGradient
                    : null,
                color: msg.isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: msg.isUser ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (msg.isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class ChatMessage {
  final bool isUser;
  final String text;

  ChatMessage({required this.isUser, required this.text});
}

class _AiIcon extends StatelessWidget {
  final AnimationController heartController;
  final bool hasAnomaly;

  const _AiIcon({
    required this.heartController,
    required this.hasAnomaly,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: heartController,
      builder: (context, child) {
        final scale = hasAnomaly
            ? 1.0 + (heartController.value * 0.12)
            : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                  blurRadius: hasAnomaly ? 14 : 8,
                  spreadRadius: hasAnomaly ? 2 : 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.medical_services,
              color: Colors.white,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}
