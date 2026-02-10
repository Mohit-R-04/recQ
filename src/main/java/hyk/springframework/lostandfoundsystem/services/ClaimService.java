package hyk.springframework.lostandfoundsystem.services;

import hyk.springframework.lostandfoundsystem.domain.Claim;
import hyk.springframework.lostandfoundsystem.domain.LostFoundItem;
import hyk.springframework.lostandfoundsystem.domain.security.User;
import hyk.springframework.lostandfoundsystem.enums.ClaimStatus;

import java.util.List;
import java.util.UUID;

public interface ClaimService {

    Claim createClaim(LostFoundItem item, User claimant, String questionsAndAnswers);

    Claim getClaimById(UUID claimId);

    List<Claim> getClaimsByItem(UUID itemId);

    List<Claim> getClaimsByClaimant(User claimant);

    List<Claim> getAllClaims();

    Claim updateClaimStatus(UUID claimId, ClaimStatus status, String adminNotes, String reviewedBy);

    boolean hasUserClaimedItem(LostFoundItem item, User claimant);
}
