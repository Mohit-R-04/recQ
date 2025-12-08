package hyk.springframework.lostandfoundsystem.validation;

import hyk.springframework.lostandfoundsystem.domain.security.User;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.validation.Errors;
import org.springframework.validation.Validator;

@Slf4j
@Component
public class PasswordMatchingValidator implements Validator {
    @Override
    public boolean supports(Class<?> clazz) {
        return User.class.equals(clazz);
    }

    @Override
    public void validate(Object target, Errors errors) {
        log.debug("Check password matching");
        User user = (User) target;
        if (!user.getPassword().equals(user.getConfirmedPassword())) {
            log.debug("Validate user input from view layer - Password mismatch");
            errors.rejectValue("confirmedPassword", "password.mismatch");
        }
    }
}
