import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_provider.dart';
import '../models/lost_found_item.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import 'claim_item_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  LostFoundItem? _item;
  bool _isLoading = true;
  bool _hasClaimed = false;
  bool _checkingClaim = true;
  final _commentController = TextEditingController();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _checkClaimStatus() async {
    if (_item == null) return;

    // Only verify claim status for FOUND items
    if (_item!.type != 'FOUND') {
      setState(() => _checkingClaim = false);
      return;
    }

    try {
      final hasClaimed = await _apiService.hasUserClaimedItem(widget.itemId);
      if (mounted) {
        setState(() {
          _hasClaimed = hasClaimed;
          _checkingClaim = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _checkingClaim = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadItem() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final item = await provider.getItemById(widget.itemId);

    if (mounted) {
      setState(() {
        _item = item;
        _isLoading = false;
      });
      _checkClaimStatus();
    }
  }

  void _onClaimPressed() async {
    if (_item == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClaimItemScreen(
          itemId: _item!.id!,
          itemTitle: _item!.title!,
          itemCategory: _item!.category ?? 'OTHERS',
        ),
      ),
    );

    if (result == true) {
      _checkClaimStatus(); // Refresh status
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    final success = await provider.addComment(
      widget.itemId,
      _commentController.text,
    );

    if (success) {
      _commentController.clear();
      _loadItem(); // Reload to get updated comments
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to add comment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final success = await provider.deleteItem(widget.itemId);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Failed to delete item'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Details')),
        body: const Center(child: Text('Item not found')),
      );
    }

    final provider = Provider.of<AppProvider>(context);
    final canEdit = provider.currentUser?.username == _item!.createdBy ||
        provider.currentUser?.isAdmin == true;

    // 🔍 DEBUG PRINTS — REMOVE AFTER TESTING
    print('ITEM TYPE: ${_item!.type}');
    print('CREATED BY: ${_item!.createdBy}');
    print('CURRENT USER: ${provider.currentUser?.username}');
    print('HAS CLAIMED: $_hasClaimed');
    print('CHECKING CLAIM: $_checkingClaim');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        actions: canEdit
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteItem,
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (_item!.imageUrl != null)
              CachedNetworkImage(
                imageUrl: ApiConfig.imageUrl(_item!.imageUrl!),
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, size: 80),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type and Category badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _item!.type == 'LOST'
                              ? Colors.red[100]
                              : Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _item!.type,
                          style: TextStyle(
                            color: _item!.type == 'LOST'
                                ? Colors.red[900]
                                : Colors.green[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _item!.category,
                          style: TextStyle(color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    _item!.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (_item!.description.trim().isNotEmpty) ...[
                    Text(
                      _item!.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                  ] else
                    const SizedBox(height: 8),

                  // Details
                  _buildDetailRow(
                    Icons.location_on,
                    'Location',
                    _item!.lostFoundLocation,
                  ),
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Date',
                    _item!.lostFoundDate,
                  ),
                  if (_item!.collectionLocation != null)
                    _buildDetailRow(
                      Icons.place,
                      'Collection Location',
                      _item!.collectionLocation!,
                    ),

                  const Divider(height: 32),

                  // Reporter Info
                  if (_item!.reporterName.trim().isNotEmpty ||
                      _item!.reporterEmail.trim().isNotEmpty ||
                      _item!.reporterPhoneNo.trim().isNotEmpty) ...[
                    const Text(
                      'Reporter Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_item!.reporterName.trim().isNotEmpty)
                      _buildDetailRow(
                        Icons.person,
                        'Name',
                        _item!.reporterName,
                      ),
                    if (_item!.reporterEmail.trim().isNotEmpty)
                      _buildDetailRow(
                        Icons.email,
                        'Email',
                        _item!.reporterEmail,
                      ),
                    if (_item!.reporterPhoneNo.trim().isNotEmpty)
                      _buildDetailRow(
                        Icons.phone,
                        'Phone',
                        _item!.reporterPhoneNo,
                      ),
                    const Divider(height: 32),
                  ],

                  // Comments Section
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_item!.comments != null && _item!.comments!.isNotEmpty)
                    ..._item!.comments!.map((comment) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment.commentText,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'By ${comment.createdBy ?? "Unknown"}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ))
                  else
                    Text(
                      'No comments yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),

                  const SizedBox(height: 16),

                  // Add Comment
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addComment,
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Claim Section
            if (_item!.type != 'FOUND')
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Text(
                  'Claims are only available for items marked as found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else if (provider.currentUser?.username == _item!.createdBy)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'You reported this item as found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: _checkingClaim
                      ? const Center(child: CircularProgressIndicator())
                      : _hasClaimed
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'You have claimed this item',
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: _onClaimPressed,
                              icon: const Icon(Icons.back_hand),
                              label: const Text('Claim This Item'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C47FF),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                            ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
