package hyk.springframework.lostandfoundsystem.services;

import hyk.springframework.lostandfoundsystem.domain.ItemMatch;
import hyk.springframework.lostandfoundsystem.domain.LostFoundItem;
import hyk.springframework.lostandfoundsystem.domain.Notification;
import hyk.springframework.lostandfoundsystem.domain.security.User;
import hyk.springframework.lostandfoundsystem.repositories.NotificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationServiceImpl implements NotificationService {

    private final NotificationRepository notificationRepository;

    @Override
    @Transactional
    public void createMatchNotification(User user, ItemMatch match, boolean isLostItemOwner) {
        String title;
        String message;

        if (isLostItemOwner) {
            title = "Potential Match Found!";
            message = String.format(
                    "A similar item has been found. %.1f%% match confidence. " +
                            "Item: %s",
                    match.getConfidenceScore(),
                    match.getFoundItem().getTitle());
        } else {
            title = "Your Found Item Matches a Lost Report";
            message = String.format(
                    "Your found item matches a reported lost item. %.1f%% match confidence. " +
                            "Lost item: %s",
                    match.getConfidenceScore(),
                    match.getLostItem().getTitle());
        }

        Notification notification = Notification.builder()
                .user(user)
                .title(title)
                .message(message)
                .notificationType("MATCH_FOUND")
                .relatedMatch(match)
                .relatedItem(isLostItemOwner ? match.getFoundItem() : match.getLostItem())
                .isRead(false)
                .build();

        notificationRepository.save(notification);
        log.info("Created match notification for user {}", user.getUsername());
    }

    @Override
    @Transactional
    public void createMatchConfirmedNotification(User user, ItemMatch match) {
        String title = "Match Confirmed!";
        String message = String.format(
                "Great news! The match between '%s' and '%s' has been confirmed. " +
                        "Please contact the other party to arrange item recovery.",
                match.getLostItem().getTitle(),
                match.getFoundItem().getTitle());

        Notification notification = Notification.builder()
                .user(user)
                .title(title)
                .message(message)
                .notificationType("MATCH_CONFIRMED")
                .relatedMatch(match)
                .isRead(false)
                .build();

        notificationRepository.save(notification);
        log.info("Created match confirmed notification for user {}", user.getUsername());
    }

    @Override
    @Transactional
    public void createCommentNotification(User user, LostFoundItem item, String commenterName) {
        String title = "New Comment on Your Item";
        String message = String.format(
                "%s commented on your item: %s",
                commenterName,
                item.getTitle());

        Notification notification = Notification.builder()
                .user(user)
                .title(title)
                .message(message)
                .notificationType("ITEM_COMMENT")
                .relatedItem(item)
                .isRead(false)
                .build();

        notificationRepository.save(notification);
        log.info("Created comment notification for user {}", user.getUsername());
    }

    @Override
    public List<Notification> getNotificationsForUser(User user) {
        return notificationRepository.findByUserOrderByCreatedAtDesc(user);
    }

    @Override
    public List<Notification> getUnreadNotifications(User user) {
        return notificationRepository.findByUserAndIsReadFalseOrderByCreatedAtDesc(user);
    }

    @Override
    @Transactional
    public Notification markAsRead(UUID notificationId, User user) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found: " + notificationId));

        // Verify ownership
        if (!notification.getUser().equals(user)) {
            throw new RuntimeException("User not authorized to access this notification");
        }

        notification.setIsRead(true);
        notification.setReadAt(LocalDateTime.now());
        return notificationRepository.save(notification);
    }

    @Override
    @Transactional
    public void markAllAsRead(User user) {
        notificationRepository.markAllAsRead(user);
        log.info("Marked all notifications as read for user {}", user.getUsername());
    }

    @Override
    public Long countUnreadNotifications(User user) {
        return notificationRepository.countByUserAndIsReadFalse(user);
    }

    @Override
    @Transactional
    public void deleteNotification(UUID notificationId, User user) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found: " + notificationId));

        // Verify ownership
        if (!notification.getUser().equals(user)) {
            throw new RuntimeException("User not authorized to delete this notification");
        }

        notificationRepository.delete(notification);
        log.info("Deleted notification {} for user {}", notificationId, user.getUsername());
    }
}
