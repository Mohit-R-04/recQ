package hyk.springframework.lostandfoundsystem.repositories;

import hyk.springframework.lostandfoundsystem.domain.ItemEmbedding;
import hyk.springframework.lostandfoundsystem.domain.LostFoundItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ItemEmbeddingRepository extends JpaRepository<ItemEmbedding, UUID> {

    // Find embedding by item
    Optional<ItemEmbedding> findByItem(LostFoundItem item);

    // Find all embeddings that are registered with ML service
    List<ItemEmbedding> findByIsRegisteredWithMlTrue();

    // Find all embeddings that need to be registered
    List<ItemEmbedding> findByIsRegisteredWithMlFalse();

    // Find embeddings with images
    List<ItemEmbedding> findByHasImageTrue();

    // Delete embedding when item is deleted
    void deleteByItem(LostFoundItem item);

    // Check if item has embedding
    boolean existsByItem(LostFoundItem item);
}
