package hyk.springframework.lostandfoundsystem.services;

import hyk.springframework.lostandfoundsystem.domain.Claim;
import hyk.springframework.lostandfoundsystem.domain.LostFoundItem;
import hyk.springframework.lostandfoundsystem.domain.security.User;
import hyk.springframework.lostandfoundsystem.enums.ClaimStatus;
import hyk.springframework.lostandfoundsystem.exceptions.ResourceNotFoundException;
import hyk.springframework.lostandfoundsystem.repositories.ClaimRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class ClaimServiceImpl implements ClaimService {

    private final ClaimRepository claimRepository;

    @Override
    @Transactional
    public Claim createClaim(LostFoundItem item, User claimant, String questionsAndAnswers) {
        // Check if user already claimed this item
        if (claimRepository.existsByItemAndClaimant(item, claimant)) {
            throw new RuntimeException("You have already claimed this item");
        }

        // Check if item already has an approved claim
        long approvedClaimsCount = claimRepository.countByItemAndStatus(item, ClaimStatus.APPROVED);
        if (approvedClaimsCount > 0) {
            throw new RuntimeException(
                    "This item has already been claimed and approved. No further claims are accepted.");
        }

        Claim claim = Claim.builder()
                .item(item)
                .claimant(claimant)
                .status(ClaimStatus.PENDING)
                .questionsAndAnswers(questionsAndAnswers)
                .build();

        Claim saved = claimRepository.save(claim);
        log.info("Claim created: {} by user {} for item {}", saved.getId(), claimant.getUsername(), item.getId());
        return saved;
    }

    @Override
    public Claim getClaimById(UUID claimId) {
        return claimRepository.findById(claimId)
                .orElseThrow(() -> new ResourceNotFoundException("Claim not found with id: " + claimId));
    }

    @Override
    public List<Claim> getClaimsByItem(UUID itemId) {
        return claimRepository.findByItemId(itemId);
    }

    @Override
    public List<Claim> getClaimsByClaimant(User claimant) {
        return claimRepository.findByClaimantId(claimant.getId());
    }

    @Override
    public List<Claim> getAllClaims() {
        return claimRepository.findAllByOrderByCreatedAtDesc();
    }

    @Override
    @Transactional
    public Claim updateClaimStatus(UUID claimId, ClaimStatus status, String adminNotes, String reviewedBy) {
        Claim claim = getClaimById(claimId);

        // If approving this claim, check if another claim for the same item is already
        // approved
        if (status == ClaimStatus.APPROVED) {
            LostFoundItem item = claim.getItem();
            long approvedClaimsCount = claimRepository.countByItemAndStatus(item, ClaimStatus.APPROVED);

            if (approvedClaimsCount > 0) {
                throw new RuntimeException(
                        "Cannot approve this claim: Another user's claim is already approved for this item");
            }
        }

        claim.setStatus(status);
        claim.setAdminNotes(adminNotes);
        claim.setReviewedBy(reviewedBy);
        claim.setReviewedAt(Timestamp.from(Instant.now()));

        Claim updated = claimRepository.save(claim);
        log.info("Claim {} status updated to {} by {}", claimId, status, reviewedBy);
        return updated;
    }

    @Override
    public boolean hasUserClaimedItem(LostFoundItem item, User claimant) {
        return claimRepository.existsByItemAndClaimant(item, claimant);
    }
}
