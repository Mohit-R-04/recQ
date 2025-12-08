package hyk.springframework.lostandfoundsystem.domain;

import hyk.springframework.lostandfoundsystem.domain.security.User;
import hyk.springframework.lostandfoundsystem.enums.Category;
import hyk.springframework.lostandfoundsystem.enums.Type;
import hyk.springframework.lostandfoundsystem.validation.ValidEmail;
import hyk.springframework.lostandfoundsystem.validation.ValidPhoneNumber;
import lombok.*;
import org.springframework.format.annotation.DateTimeFormat;

import javax.persistence.*;
import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.PastOrPresent;
import javax.validation.constraints.Size;
import java.time.LocalDate;

/**
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
// @AttributeOverride(name = "id", column = @Column(name =
// "lost_found_item_id"))
public class LostFoundItem extends BaseEntity {
    @Enumerated(EnumType.STRING)
    private Type type;

    @NotEmpty
    @Size(min = 5, max = 150)
    private String title;

    @NotNull
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    @PastOrPresent
    private LocalDate lostFoundDate;

    @NotEmpty
    @Size(min = 5, max = 150)
    private String lostFoundLocation;

    @Size(max = 255)
    private String description;

    @NotEmpty
    @Size(min = 5, max = 50)
    private String reporterName;

    @NotEmpty
    @ValidEmail
    private String reporterEmail;

    @NotEmpty
    @ValidPhoneNumber
    private String reporterPhoneNo;

    @Enumerated(EnumType.STRING)
    private Category category;

    @Column(updatable = false)
    private String createdBy;

    private String modifiedBy;

    @ManyToOne
    private User user;

    private String imageUrl;

    @OneToMany(mappedBy = "lostFoundItem", cascade = CascadeType.ALL)
    private java.util.List<Comment> comments = new java.util.ArrayList<>();

    private Double latitude;
    private Double longitude;
    private String collectionLocation;
}