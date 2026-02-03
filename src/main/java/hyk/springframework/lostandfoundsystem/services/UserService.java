package hyk.springframework.lostandfoundsystem.services;

import hyk.springframework.lostandfoundsystem.domain.security.User;

import java.util.List;

/**
 **/
public interface UserService {
    List<User> findAllUsers();

    User findUserById(Integer id);

    User findByUsername(String username);

    User findByEmail(String email);

    boolean isUsernameAlreadyExisted(String username, Integer userId);

    boolean isEmailAlreadyExisted(String email, Integer userId);

    User saveUser(User User);

    void deleteUser(Integer id);
}
