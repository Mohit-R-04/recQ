package hyk.springframework.lostandfoundsystem.enums;

public enum ClaimStatus {
    PENDING, // User submitted claim, waiting for admin review
    UNDER_REVIEW, // Admin is reviewing the claim
    APPROVED, // Admin approved the claim
    REJECTED, // Admin rejected the claim
    READY_TO_COLLECT, // Item is ready for the claimant to collect
    COLLECTED // Item has been collected by the claimant
}
