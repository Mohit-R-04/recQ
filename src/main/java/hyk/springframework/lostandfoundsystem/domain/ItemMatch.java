package hyk.springframework.lostandfoundsystem.domain;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import hyk.springframework.lostandfoundsystem.domain.security.User;
import lombok.*;

import javax.persistence.*;
import java.time.LocalDateTime;

/**
 * Entity to store match results between lost and found items
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "item_match")
public class ItemMatch extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lost_item_id")
    @JsonIgnoreProperties({ "comments", "user" })
    private LostFoundItem lostItem;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "found_item_id")
    @JsonIgnoreProperties({ "comments", "user" })
    private LostFoundItem foundItem;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lost_user_id")
    @JsonIgnoreProperties({ "lostFoundItems", "roles", "authorities", "password", "confirmedPassword" })
    private User lostItemUser;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "found_user_id")
    @JsonIgnoreProperties({ "lostFoundItems", "roles", "authorities", "password", "confirmedPassword" })
    private User foundItemUser;

    @Column(name = "confidence_score")
    private Double confidenceScore;

    @Column(name = "image_similarity")
    private Double imageSimilarity;

    @Column(name = "text_similarity")
    private Double textSimilarity;

    @Column(name = "category_match")
    private Double categoryMatch;

    @Column(name = "match_level")
    private String matchLevel; // HIGH, MEDIUM, LOW

    @Column(name = "is_confirmed")
    private Boolean isConfirmed = false;

    @Column(name = "is_dismissed")
    private Boolean isDismissed = false;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "confirmed_at")
    private LocalDateTime confirmedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
