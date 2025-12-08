package hyk.springframework.lostandfoundsystem.domain;

import hyk.springframework.lostandfoundsystem.domain.security.User;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import javax.persistence.*;
import javax.validation.constraints.NotEmpty;
import java.time.LocalDateTime;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
public class Comment extends BaseEntity {

    @NotEmpty
    @Column(columnDefinition = "TEXT")
    private String text;

    @CreationTimestamp
    private LocalDateTime createdAt;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;

    private String authorName; // In case we want to display name without fetching user or for anonymous
                               // (though user likely required)

    @ManyToOne
    @JoinColumn(name = "lost_found_item_id")
    private LostFoundItem lostFoundItem;
}
