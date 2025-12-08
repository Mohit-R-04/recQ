package hyk.springframework.lostandfoundsystem.bootstrap;

import hyk.springframework.lostandfoundsystem.domain.Address;
import hyk.springframework.lostandfoundsystem.domain.LostFoundItem;
import hyk.springframework.lostandfoundsystem.domain.security.Authority;
import hyk.springframework.lostandfoundsystem.domain.security.Role;
import hyk.springframework.lostandfoundsystem.domain.security.User;
import hyk.springframework.lostandfoundsystem.enums.Category;

import hyk.springframework.lostandfoundsystem.enums.Type;
import hyk.springframework.lostandfoundsystem.repositories.LostFoundItemRepository;
import hyk.springframework.lostandfoundsystem.repositories.security.AuthorityRepository;
import hyk.springframework.lostandfoundsystem.repositories.security.RoleRepository;
import hyk.springframework.lostandfoundsystem.repositories.security.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Slf4j
@Component
@RequiredArgsConstructor
public class DataLoader implements CommandLineRunner {

        private final LostFoundItemRepository lostFoundItemRepository;
        private final AuthorityRepository authorityRepository;
        private final RoleRepository roleRepository;
        private final UserRepository userRepository;
        private final PasswordEncoder passwordEncoder;

        @Override
        public void run(String... args) throws Exception {
                loadData();
        }

        private void loadData() {
                if (roleRepository.count() > 0) {
                        log.info("Data already exists. Skipping data loader.");
                        return;
                }

                // Create lost/found item authority for admin
                Authority createAdmin = authorityRepository
                                .save(Authority.builder().permission("CREATE_ADMIN").build());
                Authority readAdmin = authorityRepository.save(Authority.builder().permission("READ_ADMIN").build());
                Authority updateAdmin = authorityRepository
                                .save(Authority.builder().permission("UPDATE_ADMIN").build());
                Authority deleteAdmin = authorityRepository
                                .save(Authority.builder().permission("DELETE_ADMIN").build());

                Authority createUser = authorityRepository.save(Authority.builder().permission("CREATE_USER").build());
                Authority readUser = authorityRepository.save(Authority.builder().permission("READ_USER").build());
                Authority updateuser = authorityRepository.save(Authority.builder().permission("UPDATE_USER").build());
                Authority deleteUser = authorityRepository.save(Authority.builder().permission("DELETE_USER").build());

                // Create admin and user role
                Role adminRole = roleRepository.save(Role.builder().name("ADMIN").build());
                Role userRole = roleRepository.save(Role.builder().name("USER").build());

                adminRole.setAuthorities(new HashSet<>(Set.of(createAdmin, readAdmin, updateAdmin, deleteAdmin)));
                userRole.setAuthorities(new HashSet<>(Set.of(createUser, readUser, updateuser, deleteUser)));

                roleRepository.saveAll(Arrays.asList(adminRole, userRole));
                log.debug("Role Data loaded. Total Count: " + roleRepository.count());
                log.debug("Authority Data loaded. Total Count: " + authorityRepository.count());

                // Create admin user
                User admin = userRepository.save(
                                User.builder()
                                                .username("admin")
                                                .password(passwordEncoder.encode("Admin11@"))
                                                .confirmedPassword("Admin11@")
                                                .role(adminRole)
                                                .fullName("Admin")
                                                .phoneNumber("9231456789")
                                                .email("hykadmin@gmail.com")
                                                .address(Address.builder().city("Mudon").state("MON")
                                                                .street("Aung Thiri Street").build())
                                                .build());

                userRepository.save(admin);

                log.debug("Lost/Found Data Loaded. Total: " + lostFoundItemRepository.count());
                log.debug("User Data Loaded: " + userRepository.count());
                // lostFoundItemRepository.save(item3);
                // lostFoundItemRepository.save(item4);
                // lostFoundItemRepository.save(item5);
                // lostFoundItemRepository.save(item6);
        }
}
