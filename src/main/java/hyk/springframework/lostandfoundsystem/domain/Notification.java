package hyk.springframework.lostandfoundsystem.domain;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import hyk.springframework.lostandfoundsystem.domain.security.User;
import lombok.*;

import javax.persistence.*;
import java.time.LocalDateTime;

/**
 * Entity to store user notifications
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "notification")
public class Notification extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    @JsonIgnoreProperties({ "lostFoundItems", "roles", "authorities", "password", "confirmedPassword" })
    private User user;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "message", length = 500)
    private String message;

    @Column(name = "notification_type")
    private String notificationType; // MATCH_FOUND, MATCH_CONFIRMED, ITEM_COMMENT, etc.

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "match_id")
    @JsonIgnoreProperties({ "lostItem", "foundItem", "lostItemUser", "foundItemUser" })
    private ItemMatch relatedMatch;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "item_id")
    @JsonIgnoreProperties({ "comments", "user" })
    private LostFoundItem relatedItem;

    @Column(name = "is_read")
    private Boolean isRead = false;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "read_at")
    private LocalDateTime readAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        isRead = false;
    }
}
