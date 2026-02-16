package hyk.springframework.lostandfoundsystem.domain;

import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.*;

import javax.persistence.*;
import java.time.LocalDateTime;

/**
 * Entity to store item embeddings for ML matching
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "item_embedding")
public class ItemEmbedding extends BaseEntity {

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "item_id", unique = true)
    @JsonIgnore
    private LostFoundItem item;

    @Lob
    @Column(name = "text_embedding", columnDefinition = "TEXT")
    private String textEmbedding; // JSON array of floats

    @Lob
    @Column(name = "image_embedding", columnDefinition = "TEXT")
    private String imageEmbedding; // JSON array of floats

    @Column(name = "has_image")
    private Boolean hasImage = false;

    @Column(name = "is_registered_with_ml")
    private Boolean isRegisteredWithMl = false;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
