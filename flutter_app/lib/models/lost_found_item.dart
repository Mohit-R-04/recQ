class LostFoundItem {
  final String? id;
  final String type; // LOST or FOUND
  final String title;
  final String lostFoundDate;
  final String lostFoundLocation;
  final String description;
  final String reporterName;
  final String reporterEmail;
  final String reporterPhoneNo;
  final String category;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String? collectionLocation;
  final String? createdBy;
  final String? modifiedBy;
  final bool isCollected;
  final List<Comment>? comments;

  LostFoundItem({
    this.id,
    required this.type,
    required this.title,
    required this.lostFoundDate,
    required this.lostFoundLocation,
    required this.description,
    required this.reporterName,
    required this.reporterEmail,
    required this.reporterPhoneNo,
    required this.category,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.collectionLocation,
    this.createdBy,
    this.modifiedBy,
    this.isCollected = false,
    this.comments,
  });

  factory LostFoundItem.fromJson(Map<String, dynamic> json) {
    return LostFoundItem(
      id: json['id']?.toString(),
      type: json['type'] ?? 'LOST',
      title: json['title'] ?? '',
      lostFoundDate: json['lostFoundDate'] ?? '',
      lostFoundLocation: json['lostFoundLocation'] ?? '',
      description: json['description'] ?? '',
      reporterName: json['reporterName'] ?? '',
      reporterEmail: json['reporterEmail'] ?? '',
      reporterPhoneNo: json['reporterPhoneNo'] ?? '',
      category: json['category'] ?? 'OTHERS', // Fixed to match backend enum
      imageUrl: json['imageUrl'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      collectionLocation: json['collectionLocation'],
      createdBy: json['createdBy'],
      modifiedBy: json['modifiedBy'],
      isCollected: json['isCollected'] == true,
      comments: json['comments'] != null
          ? (json['comments'] as List).map((c) => Comment.fromJson(c)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'title': title,
      'lostFoundDate': lostFoundDate,
      'lostFoundLocation': lostFoundLocation,
      'description': description,
      'reporterName': reporterName,
      'reporterEmail': reporterEmail,
      'reporterPhoneNo': reporterPhoneNo,
      'category': category,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (collectionLocation != null) 'collectionLocation': collectionLocation,
    };
  }
}

class Comment {
  final String? id;
  final String commentText;
  final String? createdBy;
  final String? createdDate;

  Comment({
    this.id,
    required this.commentText,
    this.createdBy,
    this.createdDate,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id']?.toString(),
      commentText: json['commentText'] ?? '',
      createdBy: json['createdBy'],
      createdDate: json['createdDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'commentText': commentText,
      if (createdBy != null) 'createdBy': createdBy,
      if (createdDate != null) 'createdDate': createdDate,
    };
  }
}
