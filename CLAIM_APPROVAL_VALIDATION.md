# Multi-User Claim Approval Validation

## Overview

Implemented a safeguard to ensure that only **one user's claim can be approved per FOUND item**. This prevents multiple users from claiming the same item and having their claims approved.

## Implementation Details

### Backend Changes

#### File: `src/main/java/hyk/springframework/lostandfoundsystem/services/ClaimServiceImpl.java`

Modified the `updateClaimStatus()` method to validate before approving a claim:

```java
@Override
@Transactional
public Claim updateClaimStatus(UUID claimId, ClaimStatus status, String adminNotes, String reviewedBy) {
    Claim claim = getClaimById(claimId);

    // If approving this claim, check if another claim for the same item is already approved
    if (status == ClaimStatus.APPROVED) {
        LostFoundItem item = claim.getItem();
        long approvedClaimsCount = claimRepository.countByItemAndStatus(item, ClaimStatus.APPROVED);

        if (approvedClaimsCount > 0) {
            throw new RuntimeException("Cannot approve this claim: Another user's claim is already approved for this item");
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
```

### How It Works

1. **When Admin Tries to Approve a Claim:**
   - The backend checks if there is already an APPROVED claim for the same item
   - If another user's claim is already approved, the operation is rejected with error message
   - If no approved claims exist, the claim is approved successfully

2. **Database Query:**
   - Uses `claimRepository.countByItemAndStatus(item, ClaimStatus.APPROVED)`
   - This query is already available in ClaimRepository interface

3. **Error Response to Frontend:**
   - Returns HTTP 400 (Bad Request) with error message:
     ```
     "Cannot approve this claim: Another user's claim is already approved for this item"
     ```
   - Frontend shows this error message in a red SnackBar

### Frontend Behavior

The `AdminClaimsScreen` already has proper error handling:

1. When admin clicks "Approve" button:
   - Calls `_apiService.reviewClaim(claim.id, 'APPROVED', adminNotes)`
2. If backend returns `success: false`:
   - Shows error message in SnackBar
   - Bottom sheet remains open so admin can review other claims
   - Admin can reject this claim or try approving another claim

3. If approval succeeds:
   - Shows "Claim updated to APPROVED" message
   - Refreshes claims list automatically

## Database Queries Used

```sql
SELECT COUNT(*) FROM claim WHERE item_id = ? AND status = 'APPROVED'
```

## Testing Scenarios

### Scenario 1: First Approval (Should Succeed)

1. User A creates a claim for FOUND item
2. Admin approves User A's claim
3. Status changes to APPROVED ✓

### Scenario 2: Second Approval (Should Fail)

1. User A's claim is already APPROVED
2. User B creates a claim for the same FOUND item
3. Admin tries to approve User B's claim
4. System rejects with error message ✗
5. Admin can still REJECT User B's claim instead

### Scenario 3: Different Item (Should Succeed)

1. User A has approved claim for Item X
2. User B has pending claim for Item Y (different item)
3. Admin can approve User B's claim for Item Y ✓

## Status Transitions

### Before Approval Safeguard

- Multiple APPROVED claims possible per item ❌

### After Approval Safeguard

- Only 1 APPROVED claim per item ✓
- Other claims can be: PENDING, UNDER_REVIEW, REJECTED, COLLECTED
- Admin must REJECT other claims to prevent multiple approvals

## Benefits

1. **Data Integrity:** Prevents duplicate claim approvals for the same item
2. **Clear Business Logic:** Only one person can receive a found item
3. **Admin Feedback:** Clear error messages explain why approval failed
4. **No Auto-Rejection:** Admin must explicitly review and reject other claims (maintains control)

## Future Enhancements (Optional)

If needed in future, could add:

1. **Auto-Rejection:** Automatically reject other claims when one is approved
2. **Conflict Resolution UI:** Admin interface to choose between competing claims
3. **Priority Scoring:** Show admins which claim is most likely valid based on Q&A answers
4. **Status Notifications:** Notify rejected claimants why their claim wasn't approved

## Code Changes Summary

- ✓ Modified: `ClaimServiceImpl.updateClaimStatus()`
- ✓ Tested: Maven build successful
- ✓ No migrations needed: Uses existing ClaimRepository method
- ✓ Frontend compatible: Already has error handling
- ✓ Backward compatible: Doesn't affect other claim operations
