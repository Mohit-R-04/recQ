package hyk.springframework.lostandfoundsystem.domain;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import hyk.springframework.lostandfoundsystem.domain.security.User;
import hyk.springframework.lostandfoundsystem.enums.ClaimStatus;
import lombok.*;

import javax.persistence.*;
import java.sql.Timestamp;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.GenericGenerator;
import org.hibernate.annotations.Type;
import org.hibernate.annotations.UpdateTimestamp;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "claims")
public class Claim {

    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Type(type = "org.hibernate.type.UUIDCharType")
    @Column(length = 36, columnDefinition = "varchar", updatable = false, nullable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "item_id", nullable = false)
    @JsonIgnoreProperties({ "comments", "user" })
    private LostFoundItem item;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "claimant_id", nullable = false)
    @JsonIgnoreProperties({ "lostFoundItems", "roles", "authorities", "password", "confirmedPassword" })
    private User claimant;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private ClaimStatus status = ClaimStatus.PENDING;

    // Store questions as JSON string: [{"question":"...","answer":"..."},...]
    @Column(columnDefinition = "CLOB")
    private String questionsAndAnswers;

    // Admin notes for approval/rejection reason
    @Column(length = 500)
    private String adminNotes;

    // Which admin reviewed this claim
    private String reviewedBy;

    @CreationTimestamp
    @Column(updatable = false)
    private Timestamp createdAt;

    @UpdateTimestamp
    private Timestamp updatedAt;

    private Timestamp reviewedAt;
}
