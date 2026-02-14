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

        // Block new claims only after the item has been handed to an owner
        long collectedClaimsCount = claimRepository.countByItemAndStatus(item, ClaimStatus.COLLECTED);
        if (collectedClaimsCount > 0) {
            Timestamp reviewedAt = Timestamp.from(Instant.now());
            Claim claim = Claim.builder()
                    .item(item)
                    .claimant(claimant)
                    .status(ClaimStatus.REJECTED)
                    .questionsAndAnswers(questionsAndAnswers)
                    .adminNotes("Rejected because the item was already given to an owner.")
                    .reviewedBy("SYSTEM")
                    .reviewedAt(reviewedAt)
                    .build();

            Claim saved = claimRepository.save(claim);
            log.info("Claim auto-rejected: {} by user {} for item {}", saved.getId(), claimant.getUsername(), item.getId());
            return saved;
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

        LostFoundItem item = claim.getItem();

        if (status != ClaimStatus.COLLECTED) {
            long alreadyCollected = claimRepository.countByItemAndStatus(item, ClaimStatus.COLLECTED);
            if (alreadyCollected > 0) {
                if (claim.getStatus() != ClaimStatus.REJECTED && claim.getStatus() != ClaimStatus.COLLECTED) {
                    Timestamp reviewedAt = Timestamp.from(Instant.now());
                    claim.setStatus(ClaimStatus.REJECTED);
                    if (claim.getAdminNotes() == null || claim.getAdminNotes().isBlank()) {
                        claim.setAdminNotes("Rejected because the item was given to another claimant.");
                    }
                    claim.setReviewedBy(reviewedBy);
                    claim.setReviewedAt(reviewedAt);
                    Claim updated = claimRepository.save(claim);
                    log.info("Claim {} auto-rejected because item already given (requested status: {})", claimId, status);
                    return updated;
                }
                return claim;
            }
        } else {
            long otherCollected = claimRepository.countByItemAndStatusAndIdNot(item, ClaimStatus.COLLECTED, claimId);
            if (otherCollected > 0) {
                throw new RuntimeException("Cannot mark as collected: Item is already marked as collected for this item");
            }
        }

        // If approving this claim, check if another claim for the same item is already
        // approved
        if (status == ClaimStatus.APPROVED) {
            long approvedClaimsCount = claimRepository.countByItemAndStatusAndIdNot(item, ClaimStatus.APPROVED, claimId);

            if (approvedClaimsCount > 0) {
                throw new RuntimeException(
                        "Cannot approve this claim: Another user's claim is already approved for this item");
            }
        }

        claim.setStatus(status);
        claim.setAdminNotes(adminNotes);
        claim.setReviewedBy(reviewedBy);
        Timestamp reviewedAt = Timestamp.from(Instant.now());
        claim.setReviewedAt(reviewedAt);

        Claim updated = claimRepository.save(claim);
        log.info("Claim {} status updated to {} by {}", claimId, status, reviewedBy);

        if (status == ClaimStatus.COLLECTED) {
            List<Claim> otherClaims = claimRepository.findByItemAndIdNot(item, claimId);
            for (Claim other : otherClaims) {
                if (other.getStatus() == ClaimStatus.COLLECTED || other.getStatus() == ClaimStatus.REJECTED) {
                    continue;
                }
                other.setStatus(ClaimStatus.REJECTED);
                if (other.getAdminNotes() == null || other.getAdminNotes().isBlank()) {
                    other.setAdminNotes("Rejected because the item was given to another claimant.");
                }
                other.setReviewedBy(reviewedBy);
                other.setReviewedAt(reviewedAt);
            }
            claimRepository.saveAll(otherClaims);
        }

        return updated;
    }

    @Override
    public boolean hasUserClaimedItem(LostFoundItem item, User claimant) {
        return claimRepository.existsByItemAndClaimant(item, claimant);
    }
}
