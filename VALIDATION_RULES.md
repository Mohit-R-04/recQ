# Lost & Found System - Validation Rules

## User Registration Validation

### Frontend & Backend Validation Rules

All validation rules are now synchronized between the Flutter frontend and Spring Boot backend to prevent registration errors.

---

## Field Requirements

### 1. **Full Name**
- **Minimum**: 5 characters
- **Maximum**: 50 characters
- **Required**: Yes
- **Example**: "John Doe" ✅, "Cat" ❌ (too short)

### 2. **Username**
- **Minimum**: 5 characters
- **Maximum**: 30 characters
- **Required**: Yes
- **Example**: "john_doe" ✅, "cat" ❌ (too short)

### 3. **Email**
- **Format**: Valid email address
- **Pattern**: `name@domain.com`
- **Required**: Yes
- **Example**: "user@example.com" ✅, "invalid-email" ❌

### 4. **Phone Number**
- **Format**: Indian phone number
- **Pattern**: `^(\+91|91|0)?[6-9]\d{9}$`
- **Required**: Yes
- **Valid Formats**:
  - `+919123456789` ✅
  - `919123456789` ✅
  - `09123456789` ✅
  - `9123456789` ✅
- **Invalid Examples**:
  - `5123456789` ❌ (must start with 6-9)
  - `91234567` ❌ (too short)
  - `abc1234567` ❌ (contains letters)

### 5. **Password**
- **Minimum**: 6 characters
- **Required**: Yes
- **Example**: "password123" ✅, "pass" ❌ (too short)

### 6. **Confirm Password**
- **Must Match**: Password field
- **Required**: Yes

---

## Backend Validation Annotations

The backend uses the following validation annotations:

```java
@Entity
public class User {
    @Size(min = 5, max = 30)
    private String username;
    
    @Size(min = 5, max = 50)
    private String fullName;
    
    @ValidPhoneNumber
    private String phoneNumber;
    
    @ValidEmail
    private String email;
}
```

---

## Common Registration Errors

### 1. **"Could not commit JPA transaction"**
**Cause**: Validation constraint violation
**Solution**: Ensure all fields meet the minimum/maximum length requirements

### 2. **"Username must be at least 5 characters"**
**Cause**: Username is too short
**Solution**: Enter a username with 5-30 characters

### 3. **"Full name must be at least 5 characters"**
**Cause**: Full name is too short
**Solution**: Enter a full name with 5-50 characters

### 4. **"Enter valid Indian phone number"**
**Cause**: Phone number doesn't match the required pattern
**Solution**: Use format like +919123456789 or 9123456789

### 5. **"Passwords do not match"**
**Cause**: Password and Confirm Password fields don't match
**Solution**: Ensure both password fields have identical values

---

## Testing Registration

### Valid Test Data

```json
{
  "fullName": "Test User",
  "username": "testuser",
  "email": "test@example.com",
  "phoneNumber": "9486806172",
  "password": "password123"
}
```

### Invalid Test Data (Will Fail)

```json
{
  "fullName": "Cat",           // ❌ Too short (min 5)
  "username": "cat",           // ❌ Too short (min 5)
  "email": "invalid-email",    // ❌ Invalid format
  "phoneNumber": "123",        // ❌ Invalid format
  "password": "pass"           // ❌ Too short (min 6)
}
```

---

## Custom Validators

### PhoneNumberValidator
- **Location**: `hyk.springframework.lostandfoundsystem.validation.PhoneNumberValidator`
- **Pattern**: `^(\+91|91|0)?[6-9]\d{9}$`
- **Description**: Validates Indian phone numbers

### EmailValidator
- **Location**: `hyk.springframework.lostandfoundsystem.validation.EmailValidator`
- **Description**: Validates email format

---

## Frontend Validation (Flutter)

The Flutter app provides real-time validation feedback:

1. **Helper Text**: Shows requirements under each field
2. **Error Messages**: Displays specific validation errors
3. **Visual Feedback**: Red borders for invalid fields
4. **Submit Prevention**: Disables submit button until all fields are valid

---

## Troubleshooting

### Registration Still Failing?

1. **Check Backend Logs**:
   ```bash
   tail -f backend.log
   ```

2. **Look for Constraint Violations**:
   ```
   ConstraintViolationException: Validation failed for classes [User]
   ```

3. **Verify Field Values**:
   - Full Name: 5-50 characters
   - Username: 5-30 characters
   - Phone: Valid Indian format
   - Email: Valid email format
   - Password: At least 6 characters

4. **Clear Form and Retry**:
   - Refresh the page
   - Re-enter all values
   - Ensure no extra spaces

---

## API Response Examples

### Success Response
```json
{
  "success": true,
  "message": "User registered successfully"
}
```

### Validation Error Response
```json
{
  "success": false,
  "message": "Registration failed: Could not commit JPA transaction; nested exception is javax.persistence.RollbackException: Error while committing the transaction"
}
```

---

## Notes

- All validation is performed on both frontend (for UX) and backend (for security)
- Frontend validation prevents unnecessary API calls
- Backend validation ensures data integrity
- Validation rules are defined in the `User` entity class
- Custom validators are in the `validation` package
