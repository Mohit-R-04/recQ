package hyk.springframework.lostandfoundsystem.services;

import hyk.springframework.lostandfoundsystem.domain.LostFoundItem;
import hyk.springframework.lostandfoundsystem.domain.ItemMatch;
import hyk.springframework.lostandfoundsystem.enums.Type;
import hyk.springframework.lostandfoundsystem.exceptions.ResourceNotFoundException;
import hyk.springframework.lostandfoundsystem.repositories.ClaimRepository;
import hyk.springframework.lostandfoundsystem.repositories.ItemEmbeddingRepository;
import hyk.springframework.lostandfoundsystem.repositories.ItemMatchRepository;
import hyk.springframework.lostandfoundsystem.repositories.LostFoundItemRepository;
import hyk.springframework.lostandfoundsystem.repositories.NotificationRepository;
import hyk.springframework.lostandfoundsystem.util.LoginUserUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

/**
 */
@RequiredArgsConstructor
@Service
@Slf4j
public class LostFoundItemServiceImpl implements LostFoundItemService {

    private final LostFoundItemRepository lostFoundItemRepository;
    private final ItemMatchRepository itemMatchRepository;
    private final NotificationRepository notificationRepository;
    private final ClaimRepository claimRepository;
    private final ItemEmbeddingRepository itemEmbeddingRepository;

    @Override
    public List<LostFoundItem> findAllItems() {
        log.debug("Service Layer - Find all lost/found items");
        return lostFoundItemRepository.findAll();
    }

    @Override
    public List<LostFoundItem> findAllItemsByUserId(Integer userId) {
        log.debug("Service Layer - Find lost/found items by user ID: " + userId);
        return lostFoundItemRepository.findAllByUserId(userId);
    }

    @Override
    public LostFoundItem findItemById(UUID itemId) {
        log.debug("Service Layer - Find lost/found items by item ID: " + itemId);
        return lostFoundItemRepository.findById(itemId).orElseThrow(
                () -> new ResourceNotFoundException("No Lost/Found Item for Requested ID !"));
    }

    @Override
    public LostFoundItem saveItem(LostFoundItem lostFoundItem) {
        log.debug("Service Layer - Save lost/found item with ID: " + lostFoundItem.getId());
        lostFoundItem.setModifiedBy(LoginUserUtil.getLoginUser().getUsername());
        return lostFoundItemRepository.save(lostFoundItem);
    }

    @Override
    @Transactional
    public void deleteItemById(UUID itemId) {
        LostFoundItem item = findItemById(itemId);
        log.debug("Service Layer - Delete lost/found items by item ID: " + itemId);

        List<ItemMatch> matches = new ArrayList<>();
        matches.addAll(itemMatchRepository.findByLostItemOrderByConfidenceScoreDesc(item));
        matches.addAll(itemMatchRepository.findByFoundItemOrderByConfidenceScoreDesc(item));

        Set<UUID> seenMatchIds = new HashSet<>();
        List<ItemMatch> uniqueMatches = new ArrayList<>();
        for (ItemMatch match : matches) {
            if (match.getId() != null && seenMatchIds.add(match.getId())) {
                uniqueMatches.add(match);
            }
        }

        notificationRepository.deleteByRelatedItem(item);
        if (!uniqueMatches.isEmpty()) {
            notificationRepository.deleteByRelatedMatchIn(uniqueMatches);
        }

        itemMatchRepository.deleteByLostItem(item);
        itemMatchRepository.deleteByFoundItem(item);

        claimRepository.deleteByItem(item);
        itemEmbeddingRepository.deleteByItem(item);

        lostFoundItemRepository.delete(item);
    }

    @Override
    public Long countItemByType(Type type) {
        log.debug("Count lost/found items");
        return lostFoundItemRepository.countLostFoundItemByType(type);
    }

    @Override
    public void addComment(UUID itemId, String commentText, String authorName) {
        log.debug("Service Layer - Add comment to item ID: " + itemId);
        LostFoundItem item = findItemById(itemId);
        hyk.springframework.lostandfoundsystem.domain.Comment comment = hyk.springframework.lostandfoundsystem.domain.Comment
                .builder()
                .text(commentText)
                .authorName(authorName)
                .lostFoundItem(item)
                .user(LoginUserUtil.getLoginUser())
                .build();

        item.getComments().add(comment);
        lostFoundItemRepository.save(item);
    }
}
