package hyk.springframework.lostandfoundsystem.repositories;

import hyk.springframework.lostandfoundsystem.domain.ItemMatch;
import hyk.springframework.lostandfoundsystem.domain.LostFoundItem;
import hyk.springframework.lostandfoundsystem.domain.security.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ItemMatchRepository extends JpaRepository<ItemMatch, UUID> {

    // Find matches for a lost item
    List<ItemMatch> findByLostItemOrderByConfidenceScoreDesc(LostFoundItem lostItem);

    // Find matches for a found item
    List<ItemMatch> findByFoundItemOrderByConfidenceScoreDesc(LostFoundItem foundItem);

    // Find matches for a user (both lost and found)
    @Query("SELECT m FROM ItemMatch m WHERE m.lostItemUser = :user OR m.foundItemUser = :user ORDER BY m.createdAt DESC")
    List<ItemMatch> findByUser(@Param("user") User user);

    // Find matches for a user's lost items
    List<ItemMatch> findByLostItemUserOrderByCreatedAtDesc(User user);

    // Find matches for a user's found items
    List<ItemMatch> findByFoundItemUserOrderByCreatedAtDesc(User user);

    // Find unconfirmed matches for a user
    @Query("SELECT m FROM ItemMatch m WHERE (m.lostItemUser = :user OR m.foundItemUser = :user) AND m.isConfirmed = false AND m.isDismissed = false ORDER BY m.confidenceScore DESC")
    List<ItemMatch> findPendingMatchesByUser(@Param("user") User user);

    // Find match between specific lost and found items
    Optional<ItemMatch> findByLostItemAndFoundItem(LostFoundItem lostItem, LostFoundItem foundItem);

    // Find high confidence matches
    @Query("SELECT m FROM ItemMatch m WHERE m.confidenceScore >= :threshold AND m.isConfirmed = false AND m.isDismissed = false ORDER BY m.confidenceScore DESC")
    List<ItemMatch> findHighConfidenceMatches(@Param("threshold") Double threshold);

    // Count unread matches for a user
    @Query("SELECT COUNT(m) FROM ItemMatch m WHERE (m.lostItemUser = :user OR m.foundItemUser = :user) AND m.isConfirmed = false AND m.isDismissed = false")
    Long countPendingMatchesByUser(@Param("user") User user);

    // Delete matches when an item is deleted
    void deleteByLostItem(LostFoundItem lostItem);

    void deleteByFoundItem(LostFoundItem foundItem);
}
