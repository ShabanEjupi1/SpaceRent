import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/partner_repository.dart';
import '../domain/partner.dart';

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
                        const Text(
                          'Application Received!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Thank you for applying to SpaceRent Kosovo. Our team will review your credentials and email you an onboarding confirmation containing your secure invite link.',
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
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Back to App', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C5CE7).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.handshake_outlined, color: Color(0xFF00CEC9), size: 24),
                              ),
                              const SizedBox(width: 14),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Join SpaceRent',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit'),
                                  ),
                                  Text(
                                    'Become a Kosovo Partner Hub',
                                    style: TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          TextFormField(
                            controller: companyController,
                            decoration: const InputDecoration(
                              labelText: 'Company / Business Name',
                              labelStyle: TextStyle(color: Colors.white60),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (v) => v == null || v.isEmpty ? 'Please enter company name' : null,
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
                            validator: (v) => v == null || v.isEmpty ? 'Please enter contact name' : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Business Email Address',
                              labelStyle: TextStyle(color: Colors.white60),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (v) => v == null || !v.contains('@') ? 'Invalid email address' : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Contact Phone Number',
                              labelStyle: TextStyle(color: Colors.white60),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (v) => v == null || v.isEmpty ? 'Please enter phone number' : null,
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

                                        await ref.read(partnerRepositoryProvider).submitApplication(app);
                                        isSuccess.value = true;
                                      }
                                    },
                              child: isSubmitting.value
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Submit Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/partner/login'),
                              child: const Text(
                                'Already a partner? Sign In here',
                                style: TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold),
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
