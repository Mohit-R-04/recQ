package hyk.springframework.lostandfoundsystem.validation;

import lombok.extern.slf4j.Slf4j;

import javax.validation.ConstraintValidator;
import javax.validation.ConstraintValidatorContext;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Slf4j
public class PhoneNumberValidator implements ConstraintValidator<ValidPhoneNumber, String> {

    /*
     * +919123456789
     * 919123456789
     * 09123456789
     * 9123456789
     */
    private static final String PHONE_NUMBER_PATTERN = "^(\\+91|91|0)?[6-9]\\d{9}$";
    private static final Pattern PATTERN = Pattern.compile(PHONE_NUMBER_PATTERN);

    @Override
    public boolean isValid(final String phoneNumber, final ConstraintValidatorContext context) {
        log.debug("Validate phone number");
        return (validatePhoneNumber(phoneNumber));
    }

    private boolean validatePhoneNumber(final String phoneNumber) {
        Matcher matcher = PATTERN.matcher(phoneNumber);
        return matcher.matches();
    }
}
