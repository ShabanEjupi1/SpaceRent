import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for sending email notifications via Supabase Edge Function.
/// The Edge Function "send-email" must be deployed to your Supabase project.
class EmailService {
  final SupabaseClient _supabase;

  EmailService(this._supabase);

  /// Sends a partner invite email with their registration link
  Future<void> sendPartnerInviteEmail({
    required String toEmail,
    required String companyName,
    required String contactName,
    required String inviteToken,
  }) async {
    final registrationUrl =
        'https://shabanejupi1.github.io/SpaceRent/partner/register?token=$inviteToken';

    await _sendEmail(
      to: toEmail,
      subject: 'SpaceRent Kosovo — Your Partner Registration Link',
      html: '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#0F0F1A;font-family:'Segoe UI',Arial,sans-serif;">
  <div style="max-width:600px;margin:40px auto;background:#16162B;border-radius:16px;overflow:hidden;border:1px solid rgba(255,255,255,0.08);">
    <div style="background:linear-gradient(135deg,#6C5CE7,#00CEC9);padding:32px;text-align:center;">
      <h1 style="color:white;margin:0;font-size:28px;">🚀 SpaceRent Kosovo</h1>
      <p style="color:rgba(255,255,255,0.85);margin:8px 0 0;">Partner Onboarding Invitation</p>
    </div>
    <div style="padding:32px;color:#E0E0E0;line-height:1.6;">
      <p>Dear <strong style="color:white;">$contactName</strong>,</p>
      <p>Congratulations! Your partner application for <strong style="color:#00CEC9;">$companyName</strong> has been approved by the SpaceRent Kosovo admin team.</p>
      <p>Click the button below to complete your registration and set up your fleet dashboard:</p>
      <div style="text-align:center;margin:32px 0;">
        <a href="$registrationUrl" style="display:inline-block;background:#6C5CE7;color:white;padding:14px 32px;border-radius:12px;text-decoration:none;font-weight:bold;font-size:16px;">Complete Registration →</a>
      </div>
      <p style="color:#888;font-size:13px;">If the button doesn't work, copy and paste this URL:<br/>
      <a href="$registrationUrl" style="color:#00CEC9;font-size:12px;word-break:break-all;">$registrationUrl</a></p>
      <hr style="border:none;border-top:1px solid rgba(255,255,255,0.08);margin:24px 0;"/>
      <p style="color:#666;font-size:12px;text-align:center;">SpaceRent Kosovo • Premium Car Rental Platform</p>
    </div>
  </div>
</body>
</html>
''',
    );
  }

  /// Sends a partner application receipt confirmation email
  Future<void> sendPartnerApplicationReceivedEmail({
    required String toEmail,
    required String companyName,
    required String contactName,
  }) async {
    await _sendEmail(
      to: toEmail,
      subject: 'SpaceRent Kosovo — Partner Application Received',
      html: '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#0F0F1A;font-family:'Segoe UI',Arial,sans-serif;">
  <div style="max-width:600px;margin:40px auto;background:#16162B;border-radius:16px;overflow:hidden;border:1px solid rgba(255,255,255,0.08);">
    <div style="background:linear-gradient(135deg,#6C5CE7,#00CEC9);padding:32px;text-align:center;">
      <h1 style="color:white;margin:0;font-size:28px;">🚀 SpaceRent Kosovo</h1>
      <p style="color:rgba(255,255,255,0.85);margin:8px 0 0;">Partner Application Received</p>
    </div>
    <div style="padding:32px;color:#E0E0E0;line-height:1.6;">
      <p>Dear <strong style="color:white;">$contactName</strong>,</p>
      <p>Thank you for applying to become a fleet partner with <strong style="color:#00CEC9;">SpaceRent Kosovo</strong> representing <strong style="color:white;">$companyName</strong>.</p>
      <p>We have successfully received your application. Our administrative team is currently reviewing your details. Once approved, you will receive an onboarding email containing your custom registration link to set up your fleet portal.</p>
      <p>If you have any questions in the meantime, please feel free to reach out to us at <a href="mailto:shaban.ejj@gmail.com" style="color:#00CEC9;">shaban.ejj@gmail.com</a>.</p>
      <hr style="border:none;border-top:1px solid rgba(255,255,255,0.08);margin:24px 0;"/>
      <p style="color:#666;font-size:12px;text-align:center;">SpaceRent Kosovo • Premium Car Rental Platform</p>
    </div>
  </div>
</body>
</html>
''',
    );
  }

  /// Sends booking confirmation/status emails to customer, admin, and partner
  Future<void> sendBookingStatusEmail({
    required String toEmail,
    required String recipientName,
    required String vehicleName,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String startDate,
    required String endDate,
    required String totalPrice,
    required String newStatus,
    required String paymentStatus, // 'Paid' or 'Unpaid'
    required String language, // 'en' or 'sq'
  }) async {
    final isAlbanian = language == 'sq';

    final statusLabels = {
      'Confirmed': isAlbanian ? 'Konfirmuar' : 'Confirmed',
      'Cancelled': isAlbanian ? 'Anuluar' : 'Cancelled',
      'Rejected': isAlbanian ? 'Refuzuar' : 'Rejected',
      'Pending': isAlbanian ? 'Në Pritje' : 'Pending',
    };

    final paymentLabels = {
      'Paid': isAlbanian ? 'Paguar' : 'Paid',
      'Unpaid': isAlbanian ? 'E papaguar' : 'Unpaid',
    };

    final statusLabel = statusLabels[newStatus] ?? newStatus;
    final paymentLabel = paymentLabels[paymentStatus] ?? paymentStatus;

    final statusColor = newStatus == 'Confirmed'
        ? '#00CEC9'
        : (newStatus == 'Cancelled' || newStatus == 'Rejected'
            ? '#FF6B6B'
            : '#FFC107');

    final paymentColor = paymentStatus == 'Paid' ? '#00CEC9' : '#FF6B6B';

    final subject = isAlbanian
        ? 'SpaceRent Kosovë — Rezervimi $statusLabel për $vehicleName'
        : 'SpaceRent Kosovo — Booking $statusLabel for $vehicleName';

    final greeting = isAlbanian
        ? 'I/E nderuar/a <strong style="color:white;">$recipientName</strong>,'
        : 'Dear <strong style="color:white;">$recipientName</strong>,';

    final bodyText = isAlbanian
        ? 'Statusi i rezervimit tuaj për <strong style="color:#00CEC9;">$vehicleName</strong> është ndryshuar.'
        : 'The status of your booking for <strong style="color:#00CEC9;">$vehicleName</strong> has been updated.';

    final detailsTitle = isAlbanian ? 'Detajet e Rezervimit' : 'Booking Details';
    final customerLabel = isAlbanian ? 'Klienti' : 'Customer';
    final phoneLabel = isAlbanian ? 'Telefoni' : 'Phone';
    final emailLabel = isAlbanian ? 'Email' : 'Email';
    final datesLabel = isAlbanian ? 'Datat' : 'Dates';
    final totalLabel = isAlbanian ? 'Totali' : 'Total';
    final statusTitleLabel = isAlbanian ? 'Statusi' : 'Status';
    final paymentTitleLabel = isAlbanian ? 'Pagesa' : 'Payment';

    await _sendEmail(
      to: toEmail,
      subject: subject,
      html: '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#0F0F1A;font-family:'Segoe UI',Arial,sans-serif;">
  <div style="max-width:600px;margin:40px auto;background:#16162B;border-radius:16px;overflow:hidden;border:1px solid rgba(255,255,255,0.08);">
    <div style="background:linear-gradient(135deg,#6C5CE7,#00CEC9);padding:32px;text-align:center;">
      <h1 style="color:white;margin:0;font-size:28px;">🚀 SpaceRent Kosovo</h1>
      <p style="color:rgba(255,255,255,0.85);margin:8px 0 0;">Booking $statusLabel</p>
    </div>
    <div style="padding:32px;color:#E0E0E0;line-height:1.6;">
      <p>$greeting</p>
      <p>$bodyText</p>
      
      <div style="background:rgba(255,255,255,0.03);border:1px solid rgba(255,255,255,0.08);border-radius:12px;padding:20px;margin:24px 0;">
        <h3 style="color:#00CEC9;margin:0 0 16px;font-size:16px;">$detailsTitle</h3>
        <table style="width:100%;color:#CCC;font-size:14px;">
          <tr><td style="padding:6px 0;color:#888;">$customerLabel:</td><td style="padding:6px 0;"><strong>$customerName</strong></td></tr>
          <tr><td style="padding:6px 0;color:#888;">$phoneLabel:</td><td style="padding:6px 0;">$customerPhone</td></tr>
          <tr><td style="padding:6px 0;color:#888;">$emailLabel:</td><td style="padding:6px 0;">$customerEmail</td></tr>
          <tr><td style="padding:6px 0;color:#888;">🚗 ${isAlbanian ? 'Automjeti' : 'Vehicle'}:</td><td style="padding:6px 0;"><strong style="color:white;">$vehicleName</strong></td></tr>
          <tr><td style="padding:6px 0;color:#888;">📅 $datesLabel:</td><td style="padding:6px 0;">$startDate — $endDate</td></tr>
          <tr><td style="padding:6px 0;color:#888;">💰 $totalLabel:</td><td style="padding:6px 0;"><strong style="color:#00CEC9;font-size:18px;">€$totalPrice</strong></td></tr>
          <tr><td style="padding:6px 0;color:#888;">$statusTitleLabel:</td><td style="padding:6px 0;"><span style="background:${statusColor}22;color:$statusColor;padding:4px 12px;border-radius:6px;font-weight:bold;font-size:13px;">$statusLabel</span></td></tr>
          <tr><td style="padding:6px 0;color:#888;">$paymentTitleLabel:</td><td style="padding:6px 0;"><span style="background:${paymentColor}22;color:$paymentColor;padding:4px 12px;border-radius:6px;font-weight:bold;font-size:13px;">$paymentLabel</span></td></tr>
        </table>
      </div>
      
      <hr style="border:none;border-top:1px solid rgba(255,255,255,0.08);margin:24px 0;"/>
      <p style="color:#666;font-size:12px;text-align:center;">SpaceRent Kosovo • Premium Car Rental Platform</p>
    </div>
  </div>
</body>
</html>
''',
    );
  }

  /// Internal method to call the Supabase Edge Function
  Future<void> _sendEmail({
    required String to,
    required String subject,
    required String html,
  }) async {
    try {
      await _supabase.functions.invoke(
        'send-email',
        body: {
          'to': to,
          'subject': subject,
          'html': html,
        },
      );
    } catch (e) {
      // Log but don't crash — email is non-critical
      // ignore: avoid_print
      print('[EmailService] Failed to send email to $to: $e');
    }
  }
}
