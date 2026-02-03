package hyk.springframework.lostandfoundsystem.repositories;

import hyk.springframework.lostandfoundsystem.domain.OtpToken;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface OtpTokenRepository extends JpaRepository<OtpToken, Long> {

    Optional<OtpToken> findByEmailAndOtpAndVerifiedFalse(String email, String otp);

    Optional<OtpToken> findTopByEmailAndVerifiedFalseOrderByCreatedAtDesc(String email);

    void deleteByEmail(String email);
}
