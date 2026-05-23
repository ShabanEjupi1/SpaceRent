import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/partner_repository.dart';
import '../domain/partner.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../notifications/email_service.dart';
import '../../bookings/data/booking_repository.dart';

class PartnerApplyScreen extends HookConsumerWidget {
  const PartnerApplyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final companyController = useTextEditingController();
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final phoneController = useTextEditingController();

    final isSubmitting = useState<bool>(false);
    final isSuccess = useState<bool>(false);
    final lang = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F1A), Color(0xFF1E1E3F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 460,
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF16162B).withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(40),
              child: isSuccess.value
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 80, color: Color(0xFF00CEC9)),
                        const SizedBox(height: 24),
                        Text(
                          tr('application_received', ref),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tr('application_thanks', ref),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C5CE7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(tr('back_to_app', ref), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  : Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Language Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _LangBtn(
                                label: 'EN',
                                isActive: lang == 'en',
                                onTap: () => ref.read(localeProvider.notifier).state = 'en',
                              ),
                              const SizedBox(width: 8),
                              _LangBtn(
                                label: 'AL',
                                isActive: lang == 'sq',
                                onTap: () => ref.read(localeProvider.notifier).state = 'sq',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  'assets/images/spacerent_logo.png',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C5CE7).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.handshake_outlined, color: Color(0xFF00CEC9), size: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('join_spacerent', ref),
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit'),
                                  ),
                                  Text(
                                    tr('become_partner', ref),
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          TextFormField(
                            controller: companyController,
                            decoration: InputDecoration(
                              labelText: tr('company_name', ref),
                              labelStyle: const TextStyle(color: Colors.white60),
                              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (v) => v == null || v.isEmpty ? tr('enter_company', ref) : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: tr('contact_person', ref),
                              labelStyle: const TextStyle(color: Colors.white60),
                              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (v) => v == null || v.isEmpty ? tr('enter_contact', ref) : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: tr('business_email', ref),
                              labelStyle: const TextStyle(color: Colors.white60),
                              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (v) => v == null || !v.contains('@') ? tr('invalid_email', ref) : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: tr('contact_phone', ref),
                              labelStyle: const TextStyle(color: Colors.white60),
                              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (v) => v == null || v.isEmpty ? tr('enter_phone_number', ref) : null,
                          ),
                          const SizedBox(height: 36),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C5CE7),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: isSubmitting.value
                                  ? null
                                  : () async {
                                      if (formKey.currentState!.validate()) {
                                        isSubmitting.value = true;
                                        final app = PartnerApplication(
                                          id: const Uuid().v4(),
                                          companyName: companyController.text.trim(),
                                          contactName: nameController.text.trim(),
                                          email: emailController.text.trim(),
                                          phone: phoneController.text.trim(),
                                          status: 'Pending',
                                        );

                                         try {
                                           await ref.read(partnerRepositoryProvider).submitApplication(app);
                                           
                                           // Send partner application confirmation email
                                           final emailService = EmailService(ref.read(supabaseClientProvider));
                                           await emailService.sendPartnerApplicationReceivedEmail(
                                             toEmail: app.email,
                                             companyName: app.companyName,
                                             contactName: app.contactName,
                                           );

                                           isSuccess.value = true;
                                         } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')),
                                            );
                                          }
                                          isSubmitting.value = false;
                                        }
                                      }
                                    },
                              child: isSubmitting.value
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(tr('submit_application', ref), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/partner/login'),
                              child: Text(
                                tr('already_partner', ref),
                                style: const TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold),
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
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _LangBtn({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6C5CE7) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? const Color(0xFF6C5CE7) : Colors.white.withOpacity(0.12)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
