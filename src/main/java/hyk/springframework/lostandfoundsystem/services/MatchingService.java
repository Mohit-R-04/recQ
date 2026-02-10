package hyk.springframework.lostandfoundsystem.services;

import hyk.springframework.lostandfoundsystem.domain.ItemMatch;
import hyk.springframework.lostandfoundsystem.domain.LostFoundItem;
import hyk.springframework.lostandfoundsystem.domain.security.User;

import java.util.List;
import java.util.UUID;

public interface MatchingService {

    /**
     * Process a newly created item and find potential matches
     * 
     * @param item The newly created lost/found item
     * @return List of matches found
     */
    List<ItemMatch> processNewItem(LostFoundItem item);

    /**
     * Get all matches for a specific item
     * 
     * @param itemId The item ID
     * @return List of matches
     */
    List<ItemMatch> getMatchesForItem(UUID itemId);

    /**
     * Get all pending matches for a user
     * 
     * @param user The user
     * @return List of pending matches
     */
    List<ItemMatch> getPendingMatchesForUser(User user);

    /**
     * Get all matches for a user (both confirmed and pending)
     * 
     * @param user The user
     * @return List of all matches
     */
    List<ItemMatch> getAllMatchesForUser(User user);

    /**
     * Confirm a match (user confirms it's their item)
     * 
     * @param matchId The match ID
     * @param user    The user confirming
     * @return The confirmed match
     */
    ItemMatch confirmMatch(UUID matchId, User user);

    /**
     * Dismiss a match (user says it's not their item)
     * 
     * @param matchId The match ID
     * @param user    The user dismissing
     * @return The dismissed match
     */
    ItemMatch dismissMatch(UUID matchId, User user);

    /**
     * Get match by ID
     * 
     * @param matchId The match ID
     * @return The match
     */
    ItemMatch getMatchById(UUID matchId);

    /**
     * Count pending matches for a user
     * 
     * @param user The user
     * @return Count of pending matches
     */
    Long countPendingMatches(User user);

    /**
     * Trigger matching for all items (batch process)
     * 
     * @return Number of new matches found
     */
    int runBatchMatching();
}
