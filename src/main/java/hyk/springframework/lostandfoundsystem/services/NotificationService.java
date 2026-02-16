package hyk.springframework.lostandfoundsystem.services;

import hyk.springframework.lostandfoundsystem.domain.Notification;
import hyk.springframework.lostandfoundsystem.domain.ItemMatch;
import hyk.springframework.lostandfoundsystem.domain.LostFoundItem;
import hyk.springframework.lostandfoundsystem.domain.security.User;

import java.util.List;
import java.util.UUID;

public interface NotificationService {

    /**
     * Create a match notification for a user
     * 
     * @param user            The user to notify
     * @param match           The match that was found
     * @param isLostItemOwner Whether the user is the lost item owner
     */
    void createMatchNotification(User user, ItemMatch match, boolean isLostItemOwner);

    /**
     * Create a match confirmed notification
     * 
     * @param user  The user to notify
     * @param match The confirmed match
     */
    void createMatchConfirmedNotification(User user, ItemMatch match);

    /**
     * Create a comment notification
     * 
     * @param user          The user to notify
     * @param item          The item that was commented on
     * @param commenterName Name of the person who commented
     */
    void createCommentNotification(User user, LostFoundItem item, String commenterName);

    /**
     * Get all notifications for a user
     * 
     * @param user The user
     * @return List of notifications
     */
    List<Notification> getNotificationsForUser(User user);

    /**
     * Get unread notifications for a user
     * 
     * @param user The user
     * @return List of unread notifications
     */
    List<Notification> getUnreadNotifications(User user);

    /**
     * Mark a notification as read
     * 
     * @param notificationId The notification ID
     * @param user           The user
     * @return The updated notification
     */
    Notification markAsRead(UUID notificationId, User user);

    /**
     * Mark all notifications as read for a user
     * 
     * @param user The user
     */
    void markAllAsRead(User user);

    /**
     * Count unread notifications for a user
     * 
     * @param user The user
     * @return Count of unread notifications
     */
    Long countUnreadNotifications(User user);

    /**
     * Delete a notification
     * 
     * @param notificationId The notification ID
     * @param user           The user
     */
    void deleteNotification(UUID notificationId, User user);
}
