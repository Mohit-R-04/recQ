"""
Matching Engine for Lost and Found System
Compares lost and found items using multi-modal similarity
"""
import numpy as np
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass
from embedding_service import (
    get_text_embedding,
    get_image_embedding,
    cosine_similarity,
    calculate_category_match,
    list_to_embedding,
    embedding_to_list,
    IMAGE_EMBEDDING_DIM,
    TEXT_EMBEDDING_DIM
)

# ======================================================
# CONFIG
# ======================================================
# Weights for confidence score calculation
IMAGE_WEIGHT = 0.5
TEXT_WEIGHT = 0.3
CATEGORY_WEIGHT = 0.2

# Matching thresholds
MATCH_THRESHOLD = 0.6      # Minimum confidence to be considered a match
HIGH_MATCH_THRESHOLD = 0.8  # High confidence match
TOP_K_MATCHES = 3           # Number of top matches to return

# ======================================================
# DATA CLASSES
# ======================================================

@dataclass
class ItemEmbeddings:
    """Embeddings for a lost/found item"""
    item_id: str
    item_type: str  # 'LOST' or 'FOUND'
    category: str
    text_embedding: np.ndarray
    image_embedding: Optional[np.ndarray]
    has_image: bool
    title: str
    description: str
    user_id: str
    
    def to_dict(self) -> dict:
        """Convert to dictionary for JSON serialization"""
        return {
            'itemId': self.item_id,
            'itemType': self.item_type,
            'category': self.category,
            'textEmbedding': embedding_to_list(self.text_embedding),
            'imageEmbedding': embedding_to_list(self.image_embedding) if self.has_image else None,
            'hasImage': self.has_image,
            'title': self.title,
            'description': self.description,
            'userId': self.user_id
        }
    
    @staticmethod
    def from_dict(data: dict) -> 'ItemEmbeddings':
        """Create from dictionary"""
        return ItemEmbeddings(
            item_id=data['itemId'],
            item_type=data['itemType'],
            category=data['category'],
            text_embedding=list_to_embedding(data['textEmbedding']),
            image_embedding=list_to_embedding(data['imageEmbedding']) if data.get('imageEmbedding') else np.zeros(IMAGE_EMBEDDING_DIM),
            has_image=data.get('hasImage', False),
            title=data.get('title', ''),
            description=data.get('description', ''),
            user_id=data.get('userId', '')
        )

@dataclass
class MatchResult:
    """Result of matching two items"""
    lost_item_id: str
    found_item_id: str
    lost_user_id: str
    found_user_id: str
    confidence_score: float
    image_similarity: float
    text_similarity: float
    category_match: float
    match_level: str  # 'HIGH', 'MEDIUM', 'LOW'
    
    def to_dict(self) -> dict:
        """Convert to dictionary for JSON serialization"""
        return {
            'lostItemId': self.lost_item_id,
            'foundItemId': self.found_item_id,
            'lostUserId': self.lost_user_id,
            'foundUserId': self.found_user_id,
            'confidenceScore': round(self.confidence_score * 100, 1),  # As percentage
            'imageSimilarity': round(self.image_similarity * 100, 1),
            'textSimilarity': round(self.text_similarity * 100, 1),
            'categoryMatch': round(self.category_match * 100, 1),
            'matchLevel': self.match_level
        }

# ======================================================
# MATCHING FUNCTIONS
# ======================================================

def calculate_match_score(
    lost_item: ItemEmbeddings,
    found_item: ItemEmbeddings
) -> MatchResult:
    """
    Calculate the match score between a lost and found item
    
    Confidence Score = 
        0.5 × Image Similarity (if both have images)
        + 0.3 × Text Similarity
        + 0.2 × Category Match
    """
    # Calculate text similarity
    text_sim = cosine_similarity(lost_item.text_embedding, found_item.text_embedding)
    
    # Calculate image similarity (only if both have images)
    if lost_item.has_image and found_item.has_image:
        image_sim = cosine_similarity(lost_item.image_embedding, found_item.image_embedding)
        # Use standard weights
        img_weight = IMAGE_WEIGHT
        text_weight = TEXT_WEIGHT
        cat_weight = CATEGORY_WEIGHT
    else:
        # No image comparison - redistribute weights
        image_sim = 0.0
        img_weight = 0.0
        text_weight = 0.6  # Increased text weight
        cat_weight = 0.4   # Increased category weight
    
    # Calculate category match
    cat_match = calculate_category_match(lost_item.category, found_item.category)
    
    # Calculate overall confidence score
    confidence = (
        img_weight * image_sim +
        text_weight * text_sim +
        cat_weight * cat_match
    )
    
    # Determine match level
    if confidence >= HIGH_MATCH_THRESHOLD:
        match_level = 'HIGH'
    elif confidence >= MATCH_THRESHOLD:
        match_level = 'MEDIUM'
    else:
        match_level = 'LOW'
    
    return MatchResult(
        lost_item_id=lost_item.item_id,
        found_item_id=found_item.item_id,
        lost_user_id=lost_item.user_id,
        found_user_id=found_item.user_id,
        confidence_score=confidence,
        image_similarity=image_sim,
        text_similarity=text_sim,
        category_match=cat_match,
        match_level=match_level
    )

def find_matches_for_item(
    new_item: ItemEmbeddings,
    existing_items: List[ItemEmbeddings],
    top_k: int = TOP_K_MATCHES
) -> List[MatchResult]:
    """
    Find potential matches for a newly reported item
    
    - If new_item is LOST, compare against FOUND items
    - If new_item is FOUND, compare against LOST items
    """
    # Filter to opposite type
    opposite_type = 'FOUND' if new_item.item_type == 'LOST' else 'LOST'
    candidates = [item for item in existing_items if item.item_type == opposite_type]
    
    if not candidates:
        return []
    
    # Calculate match scores for all candidates
    matches = []
    for candidate in candidates:
        if new_item.item_type == 'LOST':
            result = calculate_match_score(new_item, candidate)
        else:
            result = calculate_match_score(candidate, new_item)
        
        # Only include matches above threshold
        if result.confidence_score >= MATCH_THRESHOLD:
            matches.append(result)
    
    # Sort by confidence score (descending) and return top K
    matches.sort(key=lambda x: x.confidence_score, reverse=True)
    return matches[:top_k]

def batch_find_all_matches(
    items: List[ItemEmbeddings],
    top_k: int = TOP_K_MATCHES
) -> List[MatchResult]:
    """
    Find all potential matches between lost and found items
    Returns unique matches (no duplicates)
    """
    lost_items = [item for item in items if item.item_type == 'LOST']
    found_items = [item for item in items if item.item_type == 'FOUND']
    
    all_matches = []
    seen_pairs = set()
    
    for lost in lost_items:
        for found in found_items:
            # Avoid duplicates
            pair_key = (lost.item_id, found.item_id)
            if pair_key in seen_pairs:
                continue
            seen_pairs.add(pair_key)
            
            result = calculate_match_score(lost, found)
            if result.confidence_score >= MATCH_THRESHOLD:
                all_matches.append(result)
    
    # Sort by confidence and return top K per lost item
    all_matches.sort(key=lambda x: x.confidence_score, reverse=True)
    return all_matches

# ======================================================
# EMBEDDING CREATION FROM RAW DATA
# ======================================================

def create_item_embeddings(
    item_id: str,
    item_type: str,
    title: str,
    description: str,
    category: str,
    user_id: str,
    image_path: Optional[str] = None
) -> ItemEmbeddings:
    """
    Create embeddings for an item from raw data
    """
    # Combine title and description for text embedding
    combined_text = f"{title}. {description}" if description else title
    text_emb = get_text_embedding(combined_text)
    
    # Get image embedding if available
    has_image = image_path is not None and image_path != ""
    if has_image:
        image_emb = get_image_embedding(image_path)
    else:
        image_emb = np.zeros(IMAGE_EMBEDDING_DIM)
    
    return ItemEmbeddings(
        item_id=item_id,
        item_type=item_type,
        category=category,
        text_embedding=text_emb,
        image_embedding=image_emb,
        has_image=has_image,
        title=title,
        description=description,
        user_id=user_id
    )
