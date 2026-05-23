import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/partner_repository.dart';

class PartnerRegisterScreen extends HookConsumerWidget {
  final String? token;

  const PartnerRegisterScreen({
    super.key,
    this.token,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final companyController = useTextEditingController();
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final phoneController = useTextEditingController();

    final isSubmitting = useState<bool>(false);
    final isSuccess = useState<bool>(false);
    final errorMessage = useState<String?>(null);

    // Validate token exists
    final isTokenProvided = token != null && token!.isNotEmpty;

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
              child: !isTokenProvided
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 80, color: Colors.redAccent),
                        const SizedBox(height: 24),
                        const Text(
                          'Access Restricted',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit'),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'A valid partner onboarding token is required to access registration. If you have been confirmed by the administrator, please use the invitation link sent to your email.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 32),
                        TextButton(
                          onPressed: () => context.go('/'),
                          child: const Text('Return to Home', style: TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  : isSuccess.value
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 80, color: Color(0xFF00CEC9)),
                            const SizedBox(height: 24),
                            const Text(
                              'Onboarding Complete!',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit'),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Your partner profile is active. You can now add vehicles to the fleet, accept bookings, and manage reservations.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
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
                                onPressed: () => context.go('/admin'),
                                child: const Text('Go to Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
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
                              const Row(
                                children: [
                                  Icon(Icons.badge, color: Color(0xFF00CEC9), size: 24),
                                  SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Partner Onboarding',
                                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit'),
                                      ),
                                      Text(
                                        'Finalize your registration profile',
                                        style: TextStyle(color: Colors.white54, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              if (errorMessage.value != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    errorMessage.value!,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              TextFormField(
                                controller: companyController,
                                decoration: const InputDecoration(
                                  labelText: 'Company / Business Name',
                                  labelStyle: TextStyle(color: Colors.white60),
                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                ),
                                style: const TextStyle(color: Colors.white),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Contact Person Name',
                                  labelStyle: TextStyle(color: Colors.white60),
                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                ),
                                style: const TextStyle(color: Colors.white),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Business Email',
                                  labelStyle: TextStyle(color: Colors.white60),
                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                ),
                                style: const TextStyle(color: Colors.white),
                                validator: (v) => v == null || !v.contains('@') ? 'Invalid email' : null,
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Contact Phone Number',
                                  labelStyle: TextStyle(color: Colors.white60),
                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                ),
                                style: const TextStyle(color: Colors.white),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 32),

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
                                            errorMessage.value = null;
                                            try {
                                              await ref.read(partnerRepositoryProvider).verifyTokenAndRegisterPartner(
                                                    token: token!,
                                                    companyName: companyController.text.trim(),
                                                    contactName: nameController.text.trim(),
                                                    email: emailController.text.trim(),
                                                    phone: phoneController.text.trim(),
                                                  );
                                              isSuccess.value = true;
                                            } catch (e) {
                                              errorMessage.value = e.toString().replaceFirst('Exception: ', '');
                                            } finally {
                                              isSubmitting.value = false;
                                            }
                                          }
                                        },
                                  child: isSubmitting.value
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text('Complete Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
