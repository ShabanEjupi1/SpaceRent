import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/partner_repository.dart';
import '../../../core/l10n/locale_provider.dart';

class PartnerLoginScreen extends HookConsumerWidget {
  const PartnerLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final emailController = useTextEditingController();
    final phoneController = useTextEditingController();

    final isSubmitting = useState<bool>(false);
    final errorMessage = useState<String?>(null);
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
              width: 440,
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF16162B).withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(40),
              child: Form(
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

                    // Brand Header with Logo
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/spacerent_logo.png',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C5CE7).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
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
                              tr('partner_portal', ref),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Outfit',
                              ),
                            ),
                            Text(
                              tr('spacerent_kosovo_hubs', ref),
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    if (errorMessage.value != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage.value!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email Input
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: tr('registered_email', ref),
                        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00CEC9))),
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white38, size: 18),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      validator: (v) => v == null || !v.contains('@') ? tr('enter_valid_email', ref) : null,
                    ),
                    const SizedBox(height: 20),

                    // Phone Input
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: tr('registered_phone', ref),
                        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00CEC9))),
                        prefixIcon: const Icon(Icons.phone_outlined, color: Colors.white38, size: 18),
                      ),
                      obscureText: true, // Acts as a password for authentication privacy
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      validator: (v) => v == null || v.isEmpty ? tr('enter_phone', ref) : null,
                    ),
                    const SizedBox(height: 36),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSubmitting.value
                            ? null
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  isSubmitting.value = true;
                                  errorMessage.value = null;

                                  final email = emailController.text.trim();
                                  final phone = phoneController.text.trim();

                                  final partner = await ref
                                      .read(partnerRepositoryProvider)
                                      .loginPartner(email, phone);

                                  if (partner != null) {
                                    ref.read(currentPartnerProvider.notifier).state = partner;
                                    ref.read(isAdminProvider.notifier).state = false;
                                    if (context.mounted) {
                                      context.go('/admin');
                                    }
                                  } else {
                                    errorMessage.value = tr('invalid_credentials', ref);
                                  }
                                  isSubmitting.value = false;
                                }
                              },
                        child: isSubmitting.value
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                tr('sign_in', ref),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Footer Link
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/'),
                        child: Text(
                          tr('return_customer_app', ref),
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
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
