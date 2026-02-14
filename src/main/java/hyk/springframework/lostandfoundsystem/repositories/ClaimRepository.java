package hyk.springframework.lostandfoundsystem.repositories;

import hyk.springframework.lostandfoundsystem.domain.Claim;
import hyk.springframework.lostandfoundsystem.domain.LostFoundItem;
import hyk.springframework.lostandfoundsystem.domain.security.User;
import hyk.springframework.lostandfoundsystem.enums.ClaimStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ClaimRepository extends JpaRepository<Claim, UUID> {

    List<Claim> findByItem(LostFoundItem item);

    List<Claim> findByItemId(UUID itemId);

    List<Claim> findByClaimant(User claimant);

    List<Claim> findByClaimantId(Integer claimantId);

    List<Claim> findByStatus(ClaimStatus status);

    List<Claim> findByItemAndClaimant(LostFoundItem item, User claimant);

    Long countByItemAndStatus(LostFoundItem item, ClaimStatus status);

    Long countByItemAndStatusAndIdNot(LostFoundItem item, ClaimStatus status, UUID id);

    List<Claim> findByItemAndIdNot(LostFoundItem item, UUID id);

    List<Claim> findAllByOrderByCreatedAtDesc();

    boolean existsByItemAndClaimant(LostFoundItem item, User claimant);

    void deleteByItem(LostFoundItem item);
}
