import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/item_match.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final ApiService _apiService = ApiService();
  ItemMatch? _match;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadMatch();
  }

  Future<void> _loadMatch() async {
    setState(() => _isLoading = true);
    try {
      final match = await _apiService.getMatchById(widget.matchId);
      setState(() {
        _match = match;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading match: $e')),
        );
      }
    }
  }

  Future<void> _confirmMatch() async {
    setState(() => _isProcessing = true);

    final result = await _apiService.confirmMatch(widget.matchId);

    setState(() => _isProcessing = false);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Match confirmed!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMatch();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to confirm match'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _dismissMatch() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dismiss Match?'),
        content: const Text(
          'Are you sure this is not your item? You can\'t undo this action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    final result = await _apiService.dismissMatch(widget.matchId);

    setState(() => _isProcessing = false);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match dismissed')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to dismiss match'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _contactReporter(String? email, String? phone) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Contact Reporter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (email != null && email.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: Text(email),
                subtitle: const Text('Send email'),
                onTap: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse('mailto:$email');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            if (phone != null && phone.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: Text(phone),
                subtitle: const Text('Make a call'),
                onTap: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse('tel:$phone');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _match == null
              ? const Center(child: Text('Match not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Match confidence card
                      _buildConfidenceCard(),
                      const SizedBox(height: 20),

                      // Score breakdown
                      _buildScoreBreakdown(),
                      const SizedBox(height: 20),

                      // Lost item details
                      _buildItemCard('Lost Item', _match!.lostItem, Colors.red),
                      const SizedBox(height: 16),

                      // Found item details
                      _buildItemCard(
                          'Found Item', _match!.foundItem, Colors.green),
                      const SizedBox(height: 24),

                      // Action buttons
                      if (!_match!.isConfirmed && !_match!.isDismissed)
                        _buildActionButtons(),

                      if (_match!.isConfirmed) _buildConfirmedBanner(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildConfidenceCard() {
    final match = _match!;
    Color matchColor;
    String matchDescription;

    switch (match.matchLevel) {
      case 'HIGH':
        matchColor = Colors.green;
        matchDescription = 'This is a highly likely match!';
        break;
      case 'MEDIUM':
        matchColor = Colors.orange;
        matchDescription = 'This could be a potential match.';
        break;
      default:
        matchColor = Colors.grey;
        matchDescription = 'This might be a possible match.';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [matchColor.withOpacity(0.1), matchColor.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(
              match.matchLevel == 'HIGH'
                  ? Icons.verified
                  : Icons.compare_arrows,
              size: 50,
              color: matchColor,
            ),
            const SizedBox(height: 12),
            Text(
              match.confidencePercentage,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: matchColor,
              ),
            ),
            Text(
              'Match Confidence',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              matchDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBreakdown() {
    final match = _match!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Score Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildScoreBar(
                'Image Similarity', match.imageSimilarity, Colors.blue),
            const SizedBox(height: 12),
            _buildScoreBar(
                'Text Similarity', match.textSimilarity, Colors.purple),
            const SizedBox(height: 12),
            _buildScoreBar(
                'Category Match', match.categoryMatch, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBar(String label, double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text(
              '${score.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(String label, MatchItem? item, Color labelColor) {
    if (item == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: labelColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: labelColor,
                fontSize: 16,
              ),
            ),
          ),

          // Image
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            ClipRRect(
              child: CachedNetworkImage(
                imageUrl: ApiConfig.imageUrl(item.imageUrl!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_not_supported,
                          size: 50, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text('Image not available',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            )
          else
            Container(
              height: 150,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.description != null &&
                    item.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.description!,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
                const SizedBox(height: 12),
                _buildDetailRow(
                    Icons.category, 'Category', item.category ?? 'Unknown'),
                _buildDetailRow(Icons.calendar_today, 'Date',
                    item.lostFoundDate ?? 'Unknown'),
                _buildDetailRow(Icons.location_on, 'Location',
                    item.lostFoundLocation ?? 'Unknown'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _confirmMatch,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle),
            label: Text(_isProcessing ? 'Processing...' : 'Confirm Match'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isProcessing ? null : _dismissMatch,
            icon: const Icon(Icons.close),
            label: const Text('Not My Item'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmedBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Match Confirmed!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can now contact the other party to arrange item recovery.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
