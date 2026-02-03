package hyk.springframework.lostandfoundsystem.services;

import hyk.springframework.lostandfoundsystem.domain.OtpToken;
import hyk.springframework.lostandfoundsystem.repositories.OtpTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.Random;

@Slf4j
@Service
@RequiredArgsConstructor
public class OtpService {

    private final OtpTokenRepository otpTokenRepository;
    private final JavaMailSender mailSender;

    @Value("${otp.expiration.minutes:5}")
    private int otpExpirationMinutes;

    @Value("${otp.length:6}")
    private int otpLength;

    @Value("${otp.resend.timeout.seconds:60}")
    private int resendTimeoutSeconds;

    @Value("${spring.mail.username}")
    private String fromEmail;

    /**
     * Generate and send OTP to user's email
     */
    @Transactional
    public void generateAndSendOtp(String email) {
        // Check if can resend (rate limiting)
        Optional<OtpToken> lastOtpOpt = otpTokenRepository
                .findTopByEmailAndVerifiedFalseOrderByCreatedAtDesc(email);

        if (lastOtpOpt.isPresent()) {
            OtpToken lastOtp = lastOtpOpt.get();
            LocalDateTime canResendAt = lastOtp.getCreatedAt().plusSeconds(resendTimeoutSeconds);

            if (LocalDateTime.now().isBefore(canResendAt)) {
                long secondsRemaining = java.time.Duration.between(
                        LocalDateTime.now(), canResendAt).getSeconds();
                throw new RuntimeException(
                        "Please wait " + secondsRemaining + " seconds before requesting a new OTP");
            }
        }

        // Delete any existing OTPs for this email
        otpTokenRepository.deleteByEmail(email);

        // Generate random OTP
        String otp = generateOtp();

        // Create OTP token
        OtpToken otpToken = OtpToken.builder()
                .email(email)
                .otp(otp)
                .createdAt(LocalDateTime.now())
                .expiresAt(LocalDateTime.now().plusMinutes(otpExpirationMinutes))
                .verified(false)
                .build();

        otpTokenRepository.save(otpToken);

        // Send email
        sendOtpEmail(email, otp);

        log.info("OTP generated and sent to: {}", email);
    }

    /**
     * Verify OTP
     */
    @Transactional
    public boolean verifyOtp(String email, String otp) {
        Optional<OtpToken> tokenOpt = otpTokenRepository
                .findByEmailAndOtpAndVerifiedFalse(email, otp);

        if (tokenOpt.isEmpty()) {
            log.warn("Invalid OTP for email: {}", email);
            return false;
        }

        OtpToken token = tokenOpt.get();

        if (token.isExpired()) {
            log.warn("Expired OTP for email: {}", email);
            return false;
        }

        // Mark as verified
        token.setVerified(true);
        otpTokenRepository.save(token);

        log.info("OTP verified successfully for: {}", email);
        return true;
    }

    /**
     * Check if can resend OTP
     */
    public long getSecondsUntilCanResend(String email) {
        Optional<OtpToken> lastOtpOpt = otpTokenRepository
                .findTopByEmailAndVerifiedFalseOrderByCreatedAtDesc(email);

        if (lastOtpOpt.isEmpty()) {
            return 0;
        }

        OtpToken lastOtp = lastOtpOpt.get();
        LocalDateTime canResendAt = lastOtp.getCreatedAt().plusSeconds(resendTimeoutSeconds);

        if (LocalDateTime.now().isAfter(canResendAt)) {
            return 0;
        }

        return java.time.Duration.between(LocalDateTime.now(), canResendAt).getSeconds();
    }

    /**
     * Generate random numeric OTP
     */
    private String generateOtp() {
        Random random = new Random();
        StringBuilder otp = new StringBuilder();

        for (int i = 0; i < otpLength; i++) {
            otp.append(random.nextInt(10));
        }

        return otp.toString();
    }

    /**
     * Send OTP via email
     */
    private void sendOtpEmail(String toEmail, String otp) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(toEmail);
            message.setSubject("Your Lost & Found Login OTP");
            message.setText(String.format(
                    "Hello,\n\n" +
                            "Your OTP for logging into Lost & Found System is:\n\n" +
                            "    %s\n\n" +
                            "This OTP will expire in %d minutes.\n\n" +
                            "If you didn't request this, please ignore this email.\n\n" +
                            "Best regards,\n" +
                            "Lost & Found Team",
                    otp, otpExpirationMinutes));

            mailSender.send(message);
            log.info("OTP email sent successfully to: {}", toEmail);
        } catch (Exception e) {
            log.error("Failed to send OTP email to: {}", toEmail, e);
            throw new RuntimeException("Failed to send OTP email", e);
        }
    }
}
