package hyk.springframework.lostandfoundsystem.domain;

import lombok.*;

import javax.persistence.Embeddable;

/**
 **/
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Embeddable
public class Address {
    private String state;

    private String city;

    private String street;
}
