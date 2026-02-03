package hyk.springframework.lostandfoundsystem.repositories.security;

import hyk.springframework.lostandfoundsystem.domain.security.Authority;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 */
public interface AuthorityRepository extends JpaRepository<Authority, Integer> {
}
