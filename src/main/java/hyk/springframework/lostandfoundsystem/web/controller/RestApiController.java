package hyk.springframework.lostandfoundsystem.web.controller;

import hyk.springframework.lostandfoundsystem.domain.LostFoundItem;
import hyk.springframework.lostandfoundsystem.domain.security.Role;
import hyk.springframework.lostandfoundsystem.domain.security.User;
import hyk.springframework.lostandfoundsystem.services.LostFoundItemService;
import hyk.springframework.lostandfoundsystem.services.UserService;
import hyk.springframework.lostandfoundsystem.util.LoginUserUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;

/**
 * REST API Controller for Flutter frontend
 */
@Slf4j
@RequiredArgsConstructor
@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class RestApiController {

    private final LostFoundItemService lostFoundItemService;
    private final UserService userService;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final hyk.springframework.lostandfoundsystem.services.OtpService otpService;

    // ============ Authentication APIs ============

    @PostMapping("/auth/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> credentials) {
        try {
            String username = credentials.get("username");
            String password = credentials.get("password");

            // Check if user exists first
            User user = userService.findByUsername(username);
            if (user == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("message", "User does not exist. Please sign up first.");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
            }

            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(username, password));

            SecurityContextHolder.getContext().setAuthentication(authentication);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("user", getUserDto(user));
            response.put("message", "Login successful");

            return ResponseEntity.ok(response);
        } catch (org.springframework.security.authentication.BadCredentialsException e) {
            log.error("Invalid password", e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Invalid password");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
        } catch (Exception e) {
            log.error("Login failed", e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Login failed. Please try again.");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
        }
    }

    @PostMapping("/auth/register")
    public ResponseEntity<?> register(@RequestBody User user) {
        try {
            // Check if username already exists
            if (userService.findByUsername(user.getUsername()) != null) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("message", "Username already exists");
                return ResponseEntity.badRequest().body(response);
            }

            // Check if email already exists
            if (userService.findByEmail(user.getEmail()) != null) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("message", "Email already registered");
                return ResponseEntity.badRequest().body(response);
            }

            user.setPassword(passwordEncoder.encode(user.getPassword()));
            User savedUser = userService.saveUser(user);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("user", getUserDto(savedUser));
            response.put("message", "Registration successful");

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Registration failed", e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Registration failed: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @GetMapping("/auth/me")
    public ResponseEntity<?> getCurrentUser() {
        try {
            User user = LoginUserUtil.getLoginUser();
            return ResponseEntity.ok(getUserDto(user));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(null);
        }
    }

    @PostMapping("/auth/logout")
    public ResponseEntity<?> logout() {
        SecurityContextHolder.clearContext();
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Logout successful");
        return ResponseEntity.ok(response);
    }

    // ============ OTP Authentication APIs ============

    @PostMapping("/auth/send-otp")
    public ResponseEntity<?> sendOtp(@RequestBody Map<String, String> request) {
        try {
            String email = request.get("email");

            if (email == null || email.trim().isEmpty()) {
                return ResponseEntity.badRequest().body(
                        Map.of("success", false, "message", "Email is required"));
            }

            // Check if user exists
            User user = userService.findByEmail(email);
            if (user == null) {
                return ResponseEntity.badRequest().body(
                        Map.of("success", false, "message", "No account found with this email"));
            }

            otpService.generateAndSendOtp(email);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "OTP sent to your email",
                    "email", email));
        } catch (RuntimeException e) {
            log.error("Failed to send OTP", e);
            return ResponseEntity.badRequest().body(
                    Map.of("success", false, "message", e.getMessage()));
        } catch (Exception e) {
            log.error("Failed to send OTP", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                    Map.of("success", false, "message", "Failed to send OTP"));
        }
    }

    @PostMapping("/auth/verify-otp")
    public ResponseEntity<?> verifyOtpAndLogin(@RequestBody Map<String, String> request) {
        try {
            String email = request.get("email");
            String otp = request.get("otp");

            if (email == null || otp == null) {
                return ResponseEntity.badRequest().body(
                        Map.of("success", false, "message", "Email and OTP are required"));
            }

            boolean verified = otpService.verifyOtp(email, otp);

            if (!verified) {
                return ResponseEntity.badRequest().body(
                        Map.of("success", false, "message", "Invalid or expired OTP"));
            }

            // Get user and create session
            User user = userService.findByEmail(email);
            if (user == null) {
                return ResponseEntity.badRequest().body(
                        Map.of("success", false, "message", "User not found"));
            }

            // Create authentication token
            Authentication authentication = new UsernamePasswordAuthenticationToken(
                    user.getUsername(), null, user.getAuthorities());
            SecurityContextHolder.getContext().setAuthentication(authentication);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("user", getUserDto(user));
            response.put("message", "Login successful");

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("OTP verification failed", e);
            return ResponseEntity.badRequest().body(
                    Map.of("success", false, "message", "Verification failed"));
        }
    }

    @GetMapping("/auth/can-resend-otp")
    public ResponseEntity<?> canResendOtp(@RequestParam String email) {
        try {
            long secondsRemaining = otpService.getSecondsUntilCanResend(email);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "canResend", secondsRemaining == 0,
                    "secondsRemaining", secondsRemaining));
        } catch (Exception e) {
            log.error("Failed to check resend status", e);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "canResend", true,
                    "secondsRemaining", 0));
        }
    }

    @PostMapping("/auth/reset-password")
    public ResponseEntity<?> resetPassword(@RequestBody Map<String, String> request) {
        try {
            String email = request.get("email");
            String otp = request.get("otp");
            String newPassword = request.get("newPassword");

            if (email == null || otp == null || newPassword == null) {
                return ResponseEntity.badRequest().body(
                        Map.of("success", false, "message", "Email, OTP, and new password are required"));
            }

            // Verify OTP first
            boolean verified = otpService.verifyOtp(email, otp);

            if (!verified) {
                return ResponseEntity.badRequest().body(
                        Map.of("success", false, "message", "Invalid or expired OTP"));
            }

            // Find user by email
            User user = userService.findByEmail(email);
            if (user == null) {
                return ResponseEntity.badRequest().body(
                        Map.of("success", false, "message", "User not found"));
            }

            // Update password
            user.setPassword(passwordEncoder.encode(newPassword));
            userService.saveUser(user);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Password reset successful"));
        } catch (Exception e) {
            log.error("Password reset failed", e);
            return ResponseEntity.badRequest().body(
                    Map.of("success", false, "message", "Password reset failed"));
        }
    }

    // ============ Lost/Found Item APIs ============

    @GetMapping("/items")
    public ResponseEntity<List<LostFoundItem>> getAllItems() {
        return ResponseEntity.ok(lostFoundItemService.findAllItems());
    }

    @GetMapping("/items/user/{userId}")
    public ResponseEntity<List<LostFoundItem>> getItemsByUserId(@PathVariable Integer userId) {
        return ResponseEntity.ok(lostFoundItemService.findAllItemsByUserId(userId));
    }

    @GetMapping("/items/{itemId}")
    public ResponseEntity<?> getItemById(@PathVariable UUID itemId) {
        try {
            LostFoundItem item = lostFoundItemService.findItemById(itemId);
            return ResponseEntity.ok(item);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Item not found");
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping("/items")
    public ResponseEntity<?> createItem(@RequestBody LostFoundItem lostFoundItem) {
        try {
            // Get the current user's username
            User currentUser = LoginUserUtil.getLoginUser();

            // Fetch the managed user entity from database
            User user = userService.findByUsername(currentUser.getUsername());
            if (user == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("message", "User not found");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
            }

            LostFoundItem newItem = LostFoundItem.builder()
                    .type(lostFoundItem.getType())
                    .title(lostFoundItem.getTitle())
                    .lostFoundDate(lostFoundItem.getLostFoundDate())
                    .lostFoundLocation(lostFoundItem.getLostFoundLocation())
                    .description(lostFoundItem.getDescription())
                    .reporterName(lostFoundItem.getReporterName())
                    .reporterEmail(lostFoundItem.getReporterEmail())
                    .reporterPhoneNo(lostFoundItem.getReporterPhoneNo())
                    .category(lostFoundItem.getCategory())
                    .createdBy(user.getUsername())
                    .modifiedBy(user.getUsername())
                    .user(user)
                    .imageUrl(lostFoundItem.getImageUrl())
                    .latitude(lostFoundItem.getLatitude())
                    .longitude(lostFoundItem.getLongitude())
                    .collectionLocation(lostFoundItem.getCollectionLocation())
                    .build();

            LostFoundItem savedItem = lostFoundItemService.saveItem(newItem);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("item", savedItem);
            response.put("message", "Item created successfully");

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Failed to create item", e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to create item: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @PostMapping("/items/upload")
    public ResponseEntity<?> uploadImage(@RequestParam("file") MultipartFile file) {
        try {
            if (file.isEmpty()) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("message", "File is empty");
                return ResponseEntity.badRequest().body(response);
            }

            String folder = "src/main/resources/static/uploads/";
            byte[] bytes = file.getBytes();
            String filename = System.currentTimeMillis() + "_" + file.getOriginalFilename();
            Path path = Paths.get(folder + filename);
            Files.write(path, bytes);

            String imageUrl = "/uploads/" + filename;

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("imageUrl", imageUrl);
            response.put("message", "Image uploaded successfully");

            return ResponseEntity.ok(response);
        } catch (IOException e) {
            log.error("Failed to upload image", e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to upload image");
            return ResponseEntity.badRequest().body(response);
        }
    }

    @PutMapping("/items/{itemId}")
    public ResponseEntity<?> updateItem(@PathVariable UUID itemId, @RequestBody LostFoundItem lostFoundItem) {
        try {
            LostFoundItem existingItem = lostFoundItemService.findItemById(itemId);
            checkPermission(existingItem);

            lostFoundItem.setId(itemId);
            lostFoundItem.setModifiedBy(LoginUserUtil.getLoginUser().getUsername());
            LostFoundItem savedItem = lostFoundItemService.saveItem(lostFoundItem);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("item", savedItem);
            response.put("message", "Item updated successfully");

            return ResponseEntity.ok(response);
        } catch (AccessDeniedException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Access denied");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response);
        } catch (Exception e) {
            log.error("Failed to update item", e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to update item: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @DeleteMapping("/items/{itemId}")
    public ResponseEntity<?> deleteItem(@PathVariable UUID itemId) {
        try {
            LostFoundItem item = lostFoundItemService.findItemById(itemId);
            checkPermission(item);
            lostFoundItemService.deleteItemById(itemId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Item deleted successfully");

            return ResponseEntity.ok(response);
        } catch (AccessDeniedException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Access denied");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response);
        } catch (Exception e) {
            log.error("Failed to delete item", e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to delete item: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @PostMapping("/items/{itemId}/comments")
    public ResponseEntity<?> addComment(@PathVariable UUID itemId, @RequestBody Map<String, String> commentData) {
        try {
            String commentText = commentData.get("commentText");
            User user = LoginUserUtil.getLoginUser();
            lostFoundItemService.addComment(itemId, commentText, user.getUsername());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Comment added successfully");

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Failed to add comment", e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to add comment: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    // ============ Helper Methods ============

    private void checkPermission(LostFoundItem lostFoundItem) {
        if (!LoginUserUtil.isAdmin() &&
                !lostFoundItem.getUser().getId().equals(LoginUserUtil.getLoginUser().getId())) {
            throw new AccessDeniedException("You don't have permission to perform this operation");
        }
    }

    private Map<String, Object> getUserDto(User user) {
        Map<String, Object> userDto = new HashMap<>();
        userDto.put("id", user.getId());
        userDto.put("username", user.getUsername());
        userDto.put("fullName", user.getFullName());
        userDto.put("email", user.getEmail());
        userDto.put("phoneNumber", user.getPhoneNumber());

        // Extract role names to avoid circular reference
        List<String> roleNames = user.getRoles().stream()
                .map(Role::getName)
                .collect(java.util.stream.Collectors.toList());
        userDto.put("roles", roleNames);

        return userDto;
    }
}
