class ItemMatch {
  final String? id;
  final double confidenceScore;
  final double imageSimilarity;
  final double textSimilarity;
  final double categoryMatch;
  final String matchLevel;
  final bool isConfirmed;
  final bool isDismissed;
  final String? createdAt;
  final String? confirmedAt;
  final MatchItem? lostItem;
  final MatchItem? foundItem;

  ItemMatch({
    this.id,
    required this.confidenceScore,
    required this.imageSimilarity,
    required this.textSimilarity,
    required this.categoryMatch,
    required this.matchLevel,
    this.isConfirmed = false,
    this.isDismissed = false,
    this.createdAt,
    this.confirmedAt,
    this.lostItem,
    this.foundItem,
  });

  factory ItemMatch.fromJson(Map<String, dynamic> json) {
    return ItemMatch(
      id: json['id']?.toString(),
      confidenceScore: (json['confidenceScore'] ?? 0).toDouble(),
      imageSimilarity: (json['imageSimilarity'] ?? 0).toDouble(),
      textSimilarity: (json['textSimilarity'] ?? 0).toDouble(),
      categoryMatch: (json['categoryMatch'] ?? 0).toDouble(),
      matchLevel: json['matchLevel'] ?? 'LOW',
      isConfirmed: json['isConfirmed'] ?? false,
      isDismissed: json['isDismissed'] ?? false,
      createdAt: json['createdAt'],
      confirmedAt: json['confirmedAt'],
      lostItem: json['lostItem'] != null
          ? MatchItem.fromJson(json['lostItem'])
          : null,
      foundItem: json['foundItem'] != null
          ? MatchItem.fromJson(json['foundItem'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'confidenceScore': confidenceScore,
      'imageSimilarity': imageSimilarity,
      'textSimilarity': textSimilarity,
      'categoryMatch': categoryMatch,
      'matchLevel': matchLevel,
      'isConfirmed': isConfirmed,
      'isDismissed': isDismissed,
      if (createdAt != null) 'createdAt': createdAt,
      if (confirmedAt != null) 'confirmedAt': confirmedAt,
    };
  }

  String get matchLevelText {
    switch (matchLevel) {
      case 'HIGH':
        return 'High Confidence';
      case 'MEDIUM':
        return 'Medium Confidence';
      default:
        return 'Low Confidence';
    }
  }

  String get confidencePercentage => '${confidenceScore.toStringAsFixed(1)}%';
}

class MatchItem {
  final String? id;
  final String title;
  final String? description;
  final String? category;
  final String? imageUrl;
  final String? lostFoundDate;
  final String? lostFoundLocation;
  final String? reporterName;
  final String? reporterEmail;
  final String? reporterPhoneNo;

  MatchItem({
    this.id,
    required this.title,
    this.description,
    this.category,
    this.imageUrl,
    this.lostFoundDate,
    this.lostFoundLocation,
    this.reporterName,
    this.reporterEmail,
    this.reporterPhoneNo,
  });

  factory MatchItem.fromJson(Map<String, dynamic> json) {
    return MatchItem(
      id: json['id']?.toString(),
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category']?.toString(),
      imageUrl: json['imageUrl'],
      lostFoundDate: json['lostFoundDate']?.toString(),
      lostFoundLocation: json['lostFoundLocation'],
      reporterName: json['reporterName'],
      reporterEmail: json['reporterEmail'],
      reporterPhoneNo: json['reporterPhoneNo'],
    );
  }
}
