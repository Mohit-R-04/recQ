package hyk.springframework.lostandfoundsystem.services;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import hyk.springframework.lostandfoundsystem.domain.*;
import hyk.springframework.lostandfoundsystem.domain.security.User;
import hyk.springframework.lostandfoundsystem.enums.Type;
import hyk.springframework.lostandfoundsystem.repositories.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class MatchingServiceImpl implements MatchingService {

    private final LostFoundItemRepository itemRepository;
    private final ItemMatchRepository matchRepository;
    private final ItemEmbeddingRepository embeddingRepository;
    private final NotificationService notificationService;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${ml.service.url:http://localhost:5000}")
    private String mlServiceUrl;

    @Value("${matching.threshold:0.6}")
    private Double matchingThreshold;

    @Override
    @Transactional
    public List<ItemMatch> processNewItem(LostFoundItem item) {
        List<ItemMatch> newMatches = new ArrayList<>();

        try {
            // Step 1: Generate embeddings for the new item
            generateAndStoreEmbeddings(item);

            // Step 2: Register with ML service
            registerItemWithMlService(item);

            // Step 3: Find matches
            List<Map<String, Object>> mlMatches = findMatchesFromMlService(item);

            // Step 4: Create match records and notifications
            for (Map<String, Object> mlMatch : mlMatches) {
                ItemMatch match = createMatchFromMlResult(item, mlMatch);
                if (match != null) {
                    newMatches.add(match);

                    // Send notifications to both users
                    if (item.getType() == Type.LOST) {
                        // Notify the lost item owner
                        notificationService.createMatchNotification(
                                match.getLostItemUser(), match, true);
                        // Notify the found item owner
                        notificationService.createMatchNotification(
                                match.getFoundItemUser(), match, false);
                    } else {
                        // Notify the found item owner
                        notificationService.createMatchNotification(
                                match.getFoundItemUser(), match, false);
                        // Notify the lost item owner
                        notificationService.createMatchNotification(
                                match.getLostItemUser(), match, true);
                    }
                }
            }

            log.info("Found {} matches for item {}", newMatches.size(), item.getId());

        } catch (Exception e) {
            log.error("Error processing new item for matching: {}", e.getMessage(), e);
        }

        return newMatches;
    }

    private void generateAndStoreEmbeddings(LostFoundItem item) {
        try {
            String url = mlServiceUrl + "/embeddings/item";

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            // Build form data
            org.springframework.util.LinkedMultiValueMap<String, Object> body = new org.springframework.util.LinkedMultiValueMap<>();
            body.add("itemId", item.getId().toString());
            body.add("itemType", item.getType().name());
            body.add("title", item.getTitle());
            body.add("description", item.getDescription() != null ? item.getDescription() : "");
            body.add("category", item.getCategory().name());
            body.add("userId", item.getUser() != null ? item.getUser().getId().toString() : "");

            String imageUrl = item.getImageUrl();
            if (imageUrl != null && !imageUrl.trim().isEmpty()) {
                String trimmed = imageUrl.trim();
                try {
                    if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
                        byte[] bytes = restTemplate.getForObject(trimmed, byte[].class);
                        if (bytes != null && bytes.length > 0) {
                            ByteArrayResource resource = new ByteArrayResource(bytes) {
                                @Override
                                public String getFilename() {
                                    return "item.jpg";
                                }
                            };
                            body.add("image", resource);
                        }
                    } else {
                        String relative = trimmed.startsWith("/") ? trimmed.substring(1) : trimmed;
                        Path path = Paths.get("src/main/resources/static").resolve(relative).normalize();
                        if (Files.exists(path) && Files.isRegularFile(path)) {
                            body.add("image", new FileSystemResource(path.toFile()));
                        } else {
                            log.warn("Image file not found for item {} at {}", item.getId(), path);
                        }
                    }
                } catch (Exception e) {
                    log.warn("Failed to attach image for item {} (imageUrl={}): {}", item.getId(), trimmed, e.getMessage());
                }
            }

            HttpEntity<org.springframework.util.LinkedMultiValueMap<String, Object>> request = new HttpEntity<>(body,
                    headers);

            ResponseEntity<String> response = restTemplate.postForEntity(url, request, String.class);

            if (response.getStatusCode() == HttpStatus.OK) {
                JsonNode jsonResponse = objectMapper.readTree(response.getBody());

                if (jsonResponse.get("success").asBoolean()) {
                    ItemEmbedding embedding = ItemEmbedding.builder()
                            .item(item)
                            .textEmbedding(jsonResponse.get("textEmbedding").toString())
                            .imageEmbedding(
                                    jsonResponse.has("imageEmbedding") && !jsonResponse.get("imageEmbedding").isNull()
                                            ? jsonResponse.get("imageEmbedding").toString()
                                            : null)
                            .hasImage(jsonResponse.get("hasImage").asBoolean())
                            .isRegisteredWithMl(false)
                            .build();

                    embeddingRepository.save(embedding);
                    log.info("Stored embeddings for item {}", item.getId());
                }
            }
        } catch (Exception e) {
            log.error("Error generating embeddings: {}", e.getMessage(), e);
        }
    }

    private void registerItemWithMlService(LostFoundItem item) {
        try {
            Optional<ItemEmbedding> embeddingOpt = embeddingRepository.findByItem(item);
            if (embeddingOpt.isEmpty()) {
                log.warn("No embeddings found for item {}", item.getId());
                return;
            }

            ItemEmbedding embedding = embeddingOpt.get();

            String url = mlServiceUrl + "/matching/register";

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> body = new HashMap<>();
            body.put("itemId", item.getId().toString());
            body.put("itemType", item.getType().name());
            body.put("title", item.getTitle());
            body.put("description", item.getDescription());
            body.put("category", item.getCategory().name());
            body.put("userId", item.getUser() != null ? item.getUser().getId().toString() : "");
            body.put("textEmbedding", objectMapper.readTree(embedding.getTextEmbedding()));
            if (embedding.getHasImage() && embedding.getImageEmbedding() != null) {
                body.put("imageEmbedding", objectMapper.readTree(embedding.getImageEmbedding()));
                body.put("hasImage", true);
            } else {
                body.put("hasImage", false);
            }

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);

            ResponseEntity<String> response = restTemplate.postForEntity(url, request, String.class);

            if (response.getStatusCode() == HttpStatus.OK) {
                embedding.setIsRegisteredWithMl(true);
                embeddingRepository.save(embedding);
                log.info("Registered item {} with ML service", item.getId());
            }
        } catch (Exception e) {
            log.error("Error registering with ML service: {}", e.getMessage(), e);
        }
    }

    private void registerAllItemsWithMlService() {
        try {
            List<ItemEmbedding> embeddings = embeddingRepository.findAll();
            for (ItemEmbedding embedding : embeddings) {
                LostFoundItem item = embedding.getItem();
                if (item != null) {
                    registerItemWithMlService(item);
                }
            }
        } catch (Exception e) {
            log.error("Error registering all items with ML service: {}", e.getMessage(), e);
        }
    }

    private List<Map<String, Object>> findMatchesFromMlService(LostFoundItem item) {
        List<Map<String, Object>> matches = new ArrayList<>();

        try {
            String url = mlServiceUrl + "/matching/find";

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> body = new HashMap<>();
            body.put("itemId", item.getId().toString());
            body.put("topK", 3);

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);

            ResponseEntity<String> response = restTemplate.postForEntity(url, request, String.class);

            if (response.getStatusCode() == HttpStatus.NOT_FOUND) {
                registerAllItemsWithMlService();
                response = restTemplate.postForEntity(url, request, String.class);
            }

            if (response.getStatusCode() == HttpStatus.OK) {
                JsonNode jsonResponse = objectMapper.readTree(response.getBody());

                if (jsonResponse.get("success").asBoolean()) {
                    JsonNode matchesNode = jsonResponse.get("matches");
                    if (matchesNode != null && matchesNode.isArray()) {
                        for (JsonNode matchNode : matchesNode) {
                            Map<String, Object> matchData = new HashMap<>();
                            matchData.put("lostItemId", matchNode.get("lostItemId").asText());
                            matchData.put("foundItemId", matchNode.get("foundItemId").asText());
                            matchData.put("confidenceScore", matchNode.get("confidenceScore").asDouble());
                            matchData.put("imageSimilarity", matchNode.get("imageSimilarity").asDouble());
                            matchData.put("textSimilarity", matchNode.get("textSimilarity").asDouble());
                            matchData.put("categoryMatch", matchNode.get("categoryMatch").asDouble());
                            matchData.put("matchLevel", matchNode.get("matchLevel").asText());
                            matches.add(matchData);
                        }
                    }
                } else if (jsonResponse.has("message") && jsonResponse.get("message").asText("").contains("not found")) {
                    registerAllItemsWithMlService();
                    ResponseEntity<String> retryResponse = restTemplate.postForEntity(url, request, String.class);
                    if (retryResponse.getStatusCode() == HttpStatus.OK) {
                        JsonNode retryJson = objectMapper.readTree(retryResponse.getBody());
                        if (retryJson.get("success").asBoolean()) {
                            JsonNode matchesNode = retryJson.get("matches");
                            if (matchesNode != null && matchesNode.isArray()) {
                                for (JsonNode matchNode : matchesNode) {
                                    Map<String, Object> matchData = new HashMap<>();
                                    matchData.put("lostItemId", matchNode.get("lostItemId").asText());
                                    matchData.put("foundItemId", matchNode.get("foundItemId").asText());
                                    matchData.put("confidenceScore", matchNode.get("confidenceScore").asDouble());
                                    matchData.put("imageSimilarity", matchNode.get("imageSimilarity").asDouble());
                                    matchData.put("textSimilarity", matchNode.get("textSimilarity").asDouble());
                                    matchData.put("categoryMatch", matchNode.get("categoryMatch").asDouble());
                                    matchData.put("matchLevel", matchNode.get("matchLevel").asText());
                                    matches.add(matchData);
                                }
                            }
                        }
                    }
                }
            } else if (response.getStatusCode() != HttpStatus.OK) {
                log.warn("ML service /matching/find returned status {} for item {}", response.getStatusCode(), item.getId());
            }
        } catch (Exception e) {
            log.error("Error finding matches from ML service: {}", e.getMessage(), e);
        }

        return matches;
    }

    private ItemMatch createMatchFromMlResult(LostFoundItem newItem, Map<String, Object> mlMatch) {
        try {
            String lostItemId = (String) mlMatch.get("lostItemId");
            String foundItemId = (String) mlMatch.get("foundItemId");

            LostFoundItem lostItem = itemRepository.findById(UUID.fromString(lostItemId)).orElse(null);
            LostFoundItem foundItem = itemRepository.findById(UUID.fromString(foundItemId)).orElse(null);

            if (lostItem == null || foundItem == null) {
                log.warn("Could not find items for match: lost={}, found={}", lostItemId, foundItemId);
                return null;
            }

            // Check if match already exists
            Optional<ItemMatch> existingMatch = matchRepository.findByLostItemAndFoundItem(lostItem, foundItem);
            if (existingMatch.isPresent()) {
                log.info("Match already exists between {} and {}", lostItemId, foundItemId);
                return existingMatch.get();
            }

            ItemMatch match = ItemMatch.builder()
                    .lostItem(lostItem)
                    .foundItem(foundItem)
                    .lostItemUser(lostItem.getUser())
                    .foundItemUser(foundItem.getUser())
                    .confidenceScore((Double) mlMatch.get("confidenceScore"))
                    .imageSimilarity((Double) mlMatch.get("imageSimilarity"))
                    .textSimilarity((Double) mlMatch.get("textSimilarity"))
                    .categoryMatch((Double) mlMatch.get("categoryMatch"))
                    .matchLevel((String) mlMatch.get("matchLevel"))
                    .isConfirmed(false)
                    .isDismissed(false)
                    .build();

            return matchRepository.save(match);

        } catch (Exception e) {
            log.error("Error creating match from ML result: {}", e.getMessage(), e);
            return null;
        }
    }

    @Override
    public List<ItemMatch> getMatchesForItem(UUID itemId) {
        LostFoundItem item = itemRepository.findById(itemId)
                .orElseThrow(() -> new RuntimeException("Item not found: " + itemId));

        if (item.getType() == Type.LOST) {
            return matchRepository.findByLostItemOrderByConfidenceScoreDesc(item);
        } else {
            return matchRepository.findByFoundItemOrderByConfidenceScoreDesc(item);
        }
    }

    @Override
    public List<ItemMatch> getPendingMatchesForUser(User user) {
        return matchRepository.findPendingMatchesByUser(user);
    }

    @Override
    public List<ItemMatch> getAllMatchesForUser(User user) {
        return matchRepository.findByUser(user);
    }

    @Override
    @Transactional
    public ItemMatch confirmMatch(UUID matchId, User user) {
        ItemMatch match = matchRepository.findById(matchId)
                .orElseThrow(() -> new RuntimeException("Match not found: " + matchId));

        // Verify user is part of this match (compare by username since user objects may
        // differ)
        String username = user.getUsername();
        boolean isLostItemOwner = match.getLostItemUser() != null &&
                match.getLostItemUser().getUsername().equals(username);
        boolean isFoundItemOwner = match.getFoundItemUser() != null &&
                match.getFoundItemUser().getUsername().equals(username);

        if (!isLostItemOwner && !isFoundItemOwner) {
            throw new RuntimeException("User not authorized to confirm this match");
        }

        match.setIsConfirmed(true);
        match.setConfirmedAt(LocalDateTime.now());
        ItemMatch savedMatch = matchRepository.save(match);

        // Notify the other user
        User otherUser = isLostItemOwner
                ? match.getFoundItemUser()
                : match.getLostItemUser();
        if (otherUser != null) {
            notificationService.createMatchConfirmedNotification(otherUser, savedMatch);
        }

        return savedMatch;
    }

    @Override
    @Transactional
    public ItemMatch dismissMatch(UUID matchId, User user) {
        ItemMatch match = matchRepository.findById(matchId)
                .orElseThrow(() -> new RuntimeException("Match not found: " + matchId));

        // Verify user is part of this match (compare by username since user objects may
        // differ)
        String username = user.getUsername();
        boolean isLostItemOwner = match.getLostItemUser() != null &&
                match.getLostItemUser().getUsername().equals(username);
        boolean isFoundItemOwner = match.getFoundItemUser() != null &&
                match.getFoundItemUser().getUsername().equals(username);

        if (!isLostItemOwner && !isFoundItemOwner) {
            throw new RuntimeException("User not authorized to dismiss this match");
        }

        match.setIsDismissed(true);
        return matchRepository.save(match);
    }

    @Override
    public ItemMatch getMatchById(UUID matchId) {
        return matchRepository.findById(matchId)
                .orElseThrow(() -> new RuntimeException("Match not found: " + matchId));
    }

    @Override
    public Long countPendingMatches(User user) {
        return matchRepository.countPendingMatchesByUser(user);
    }

    @Override
    @Transactional
    public int runBatchMatching() {
        log.info("Starting batch matching process...");
        int newMatchCount = 0;

        try {
            // Get all items that need to be registered
            List<ItemEmbedding> unregistered = embeddingRepository.findByIsRegisteredWithMlFalse();
            for (ItemEmbedding embedding : unregistered) {
                registerItemWithMlService(embedding.getItem());
            }

            // Get all matches from ML service
            String url = mlServiceUrl + "/matching/all?threshold=" + matchingThreshold;
            ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);

            if (response.getStatusCode() == HttpStatus.OK) {
                JsonNode jsonResponse = objectMapper.readTree(response.getBody());

                if (jsonResponse.get("success").asBoolean()) {
                    JsonNode matchesNode = jsonResponse.get("matches");
                    if (matchesNode != null && matchesNode.isArray()) {
                        for (JsonNode matchNode : matchesNode) {
                            Map<String, Object> matchData = new HashMap<>();
                            matchData.put("lostItemId", matchNode.get("lostItemId").asText());
                            matchData.put("foundItemId", matchNode.get("foundItemId").asText());
                            matchData.put("confidenceScore", matchNode.get("confidenceScore").asDouble());
                            matchData.put("imageSimilarity", matchNode.get("imageSimilarity").asDouble());
                            matchData.put("textSimilarity", matchNode.get("textSimilarity").asDouble());
                            matchData.put("categoryMatch", matchNode.get("categoryMatch").asDouble());
                            matchData.put("matchLevel", matchNode.get("matchLevel").asText());

                            // Try to create match (will skip if already exists)
                            ItemMatch match = createMatchFromMlResult(null, matchData);
                            if (match != null) {
                                newMatchCount++;
                            }
                        }
                    }
                }
            }

            log.info("Batch matching completed. Found {} new matches", newMatchCount);

        } catch (Exception e) {
            log.error("Error in batch matching: {}", e.getMessage(), e);
        }

        return newMatchCount;
    }
}
