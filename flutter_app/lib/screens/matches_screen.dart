import 'package:flutter/material.dart';
import '../models/item_match.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'match_detail_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  List<ItemMatch> _pendingMatches = [];
  List<ItemMatch> _allMatches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    try {
      final pending = await _apiService.getPendingMatches();
      final all = await _apiService.getAllMatches();
      setState(() {
        _pendingMatches = pending;
        _allMatches = all;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading matches: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (_pendingMatches.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingMatches.length}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            const Tab(text: 'All Matches'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMatchList(_pendingMatches, isPending: true),
                _buildMatchList(_allMatches, isPending: false),
              ],
            ),
    );
  }

  Widget _buildMatchList(List<ItemMatch> matches, {required bool isPending}) {
    if (matches.isEmpty) {
      return _buildEmptyState(isPending);
    }

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          return _buildMatchCard(matches[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isPending) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPending ? Icons.search_off : Icons.compare_arrows,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isPending ? 'No pending matches' : 'No matches yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPending
                ? 'All matches have been reviewed'
                : 'Report items to find potential matches',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(ItemMatch match) {
    final lostItem = match.lostItem;
    final foundItem = match.foundItem;

    Color matchColor;
    IconData matchIcon;

    switch (match.matchLevel) {
      case 'HIGH':
        matchColor = Colors.green;
        matchIcon = Icons.verified;
        break;
      case 'MEDIUM':
        matchColor = Colors.orange;
        matchIcon = Icons.thumb_up;
        break;
      default:
        matchColor = Colors.grey;
        matchIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MatchDetailScreen(matchId: match.id!),
            ),
          ).then((_) => _loadMatches());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Match confidence header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: matchColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(matchIcon, color: matchColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${match.confidencePercentage} Match',
                      style: TextStyle(
                        color: matchColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Items comparison
              Row(
                children: [
                  // Lost item
                  Expanded(
                    child: _buildItemPreview(
                      'LOST',
                      lostItem?.title ?? 'Unknown',
                      lostItem?.imageUrl,
                      Colors.red,
                    ),
                  ),

                  // Match indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.compare_arrows,
                      color: Colors.grey,
                      size: 30,
                    ),
                  ),

                  // Found item
                  Expanded(
                    child: _buildItemPreview(
                      'FOUND',
                      foundItem?.title ?? 'Unknown',
                      foundItem?.imageUrl,
                      Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Score details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildScoreChip('Image', match.imageSimilarity, Icons.image),
                  _buildScoreChip(
                      'Text', match.textSimilarity, Icons.description),
                  _buildScoreChip(
                      'Category', match.categoryMatch, Icons.category),
                ],
              ),

              // Status indicators
              if (match.isConfirmed || match.isDismissed)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: match.isConfirmed
                          ? Colors.green[50]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      match.isConfirmed ? '✓ Confirmed' : 'Dismissed',
                      style: TextStyle(
                        color: match.isConfirmed
                            ? Colors.green[700]
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemPreview(
      String type, String title, String? imageUrl, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            type,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl != null
              ? Image.network(
                  '${ApiConfig.baseUrl}$imageUrl',
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                )
              : _buildPlaceholder(),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 80,
      width: 80,
      color: Colors.grey[200],
      child: Icon(Icons.image, color: Colors.grey[400], size: 40),
    );
  }

  Widget _buildScoreChip(String label, double score, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          '${score.toStringAsFixed(0)}%',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}
