import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/partner_repository.dart';

class PartnerLoginScreen extends HookConsumerWidget {
  const PartnerLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final emailController = useTextEditingController();
    final phoneController = useTextEditingController();

    final isSubmitting = useState<bool>(false);
    final errorMessage = useState<String?>(null);

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
                    // Brand Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5CE7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.handshake_outlined, color: Color(0xFF00CEC9), size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Partner Portal',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Outfit',
                              ),
                            ),
                            Text(
                              'SpaceRent Kosovo Hubs',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
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
                      decoration: const InputDecoration(
                        labelText: 'Registered Business Email',
                        labelStyle: TextStyle(color: Colors.white60, fontSize: 13),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00CEC9))),
                        prefixIcon: Icon(Icons.email_outlined, color: Colors.white38, size: 18),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email address' : null,
                    ),
                    const SizedBox(height: 20),

                    // Phone Input
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Registered Contact Phone',
                        labelStyle: TextStyle(color: Colors.white60, fontSize: 13),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00CEC9))),
                        prefixIcon: Icon(Icons.phone_outlined, color: Colors.white38, size: 18),
                      ),
                      obscureText: true, // Acts as a password for authentication privacy
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      validator: (v) => v == null || v.isEmpty ? 'Enter your contact phone number' : null,
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
                                    errorMessage.value = 'Invalid partner credentials or profile is suspended.';
                                  }
                                  isSubmitting.value = false;
                                }
                              },
                        child: isSubmitting.value
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Sign In to Dashboard',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Footer Link
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/'),
                        child: const Text(
                          'Return to Customer App',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
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
