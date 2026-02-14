import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/claim.dart';

class AdminClaimsScreen extends StatefulWidget {
  const AdminClaimsScreen({super.key});

  @override
  State<AdminClaimsScreen> createState() => _AdminClaimsScreenState();
}

class _AdminClaimsScreenState extends State<AdminClaimsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Claim> _allClaims = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadClaims();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClaims() async {
    setState(() => _loading = true);
    try {
      final claimsData = await _apiService.getAllClaimsAdmin();
      setState(() {
        _allClaims = claimsData.map((c) => Claim.fromJson(c)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<Claim> _filterClaims(String filter) {
    switch (filter) {
      case 'PENDING':
        return _allClaims
            .where((c) => c.status == 'PENDING' || c.status == 'UNDER_REVIEW')
            .toList();
      case 'APPROVED':
        return _allClaims
            .where(
                (c) => c.status == 'APPROVED' || c.status == 'READY_TO_COLLECT')
            .toList();
      case 'REJECTED':
        return _allClaims.where((c) => c.status == 'REJECTED').toList();
      case 'COLLECTED':
        return _allClaims.where((c) => c.status == 'COLLECTED').toList();
      default:
        return _allClaims;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'UNDER_REVIEW':
        return Colors.blue;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'READY_TO_COLLECT':
        return const Color(0xFF6C47FF);
      case 'COLLECTED':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.hourglass_empty;
      case 'UNDER_REVIEW':
        return Icons.search;
      case 'APPROVED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      case 'READY_TO_COLLECT':
        return Icons.inventory_2;
      case 'COLLECTED':
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }

  bool _isItemGiven(String? itemId) {
    if (itemId == null || itemId.isEmpty) return false;
    return _allClaims.any((c) => c.item?.id == itemId && c.status == 'COLLECTED');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claims Dashboard'),
        elevation: 0,
        backgroundColor: const Color(0xFF6C47FF),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              text: 'Pending',
              icon: Badge(
                label: Text(_filterClaims('PENDING').length.toString()),
                isLabelVisible: _filterClaims('PENDING').isNotEmpty,
                child: const Icon(Icons.hourglass_empty, size: 20),
              ),
            ),
            Tab(
              text: 'Approved',
              icon: Badge(
                label: Text(_filterClaims('APPROVED').length.toString()),
                isLabelVisible: _filterClaims('APPROVED').isNotEmpty,
                child: const Icon(Icons.check_circle, size: 20),
              ),
            ),
            Tab(
              text: 'Rejected',
              icon: Badge(
                label: Text(_filterClaims('REJECTED').length.toString()),
                isLabelVisible: _filterClaims('REJECTED').isNotEmpty,
                child: const Icon(Icons.cancel, size: 20),
              ),
            ),
            Tab(
              text: 'Given',
              icon: Badge(
                label: Text(_filterClaims('COLLECTED').length.toString()),
                isLabelVisible: _filterClaims('COLLECTED').isNotEmpty,
                child: const Icon(Icons.done_all, size: 20),
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C47FF)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildClaimsList(_filterClaims('PENDING')),
                _buildClaimsList(_filterClaims('APPROVED')),
                _buildClaimsList(_filterClaims('REJECTED')),
                _buildClaimsList(_filterClaims('COLLECTED')),
              ],
            ),
    );
  }

  Widget _buildClaimsList(List<Claim> claims) {
    if (claims.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('No claims in this category',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClaims,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: claims.length,
        itemBuilder: (context, index) => _buildAdminClaimCard(claims[index]),
      ),
    );
  }

  Widget _buildAdminClaimCard(Claim claim) {
    final statusColor = _statusColor(claim.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showClaimReviewSheet(claim),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item title + status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      claim.item?.title ?? 'Unknown Item',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(claim.status),
                            size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          claim.statusDisplay,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Claimant info
              if (claim.claimant != null)
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${claim.claimant!.fullName} (@${claim.claimant!.username})',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ],
                ),

              if (claim.claimant != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(claim.claimant!.email,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(width: 16),
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(claim.claimant!.phoneNumber,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ],

              if (claim.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Submitted: ${claim.createdAt}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClaimReviewSheet(Claim claim) {
    // Parse Q&A
    List<dynamic> qaPairs = [];
    try {
      if (claim.questionsAndAnswers != null) {
        qaPairs = jsonDecode(claim.questionsAndAnswers!);
      }
    } catch (_) {}

    final notesController = TextEditingController(text: claim.adminNotes ?? '');
    final itemGiven = _isItemGiven(claim.item?.id);
    final isLockedByGiven = itemGiven && claim.status != 'COLLECTED';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Review Claim',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor(claim.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    claim.statusDisplay,
                    style: TextStyle(
                      color: _statusColor(claim.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Item info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Item Details',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    claim.item?.title ?? 'N/A',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (claim.item?.category != null)
                    Text('Category: ${claim.item!.category}',
                        style: TextStyle(color: Colors.grey[600])),
                  if (claim.item?.lostFoundLocation != null)
                    Text('Location: ${claim.item!.lostFoundLocation}',
                        style: TextStyle(color: Colors.grey[600])),
                  if (claim.item?.description != null &&
                      claim.item!.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Description (Admin Only):',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.red)),
                    Text(claim.item!.description!,
                        style: const TextStyle(fontSize: 13)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Claimant info
            if (claim.claimant != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Claimant Details',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.blue)),
                    const SizedBox(height: 8),
                    Text('Name: ${claim.claimant!.fullName}',
                        style: const TextStyle(fontSize: 14)),
                    Text('Username: @${claim.claimant!.username}',
                        style: const TextStyle(fontSize: 14)),
                    Text('Email: ${claim.claimant!.email}',
                        style: const TextStyle(fontSize: 14)),
                    Text('Phone: ${claim.claimant!.phoneNumber}',
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Q&A answers
            const Text(
              'Verification Answers:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            ...qaPairs.asMap().entries.map((entry) {
              final i = entry.key;
              final qa = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${i + 1}: ${qa['question'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF6C47FF),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'A: ${qa['answer'] ?? ''}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // Admin notes
            const Text(
              'Admin Notes:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Add notes about this claim (reason for approval/rejection)...',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            if (isLockedByGiven)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[100]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This item is already marked as given to an owner. This claim is locked and will appear under Rejected.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            if (!isLockedByGiven &&
                (claim.status == 'PENDING' || claim.status == 'UNDER_REVIEW'))
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateClaimStatus(
                          claim, 'REJECTED', notesController.text),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateClaimStatus(
                          claim, 'APPROVED', notesController.text),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            if (!isLockedByGiven && claim.status == 'APPROVED')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateClaimStatus(
                      claim, 'READY_TO_COLLECT', notesController.text),
                  icon: const Icon(Icons.inventory_2),
                  label: const Text('Mark as Ready to Collect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C47FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            if (!isLockedByGiven && claim.status == 'READY_TO_COLLECT')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateClaimStatus(
                      claim, 'COLLECTED', notesController.text),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Mark as Given to Owner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Future<void> _updateClaimStatus(
      Claim claim, String status, String adminNotes) async {
    Navigator.pop(context); // Close bottom sheet

    final result = await _apiService.reviewClaim(claim.id!, status, adminNotes);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Claim updated to $status'),
            backgroundColor: Colors.green,
          ),
        );
        _loadClaims(); // Refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update claim'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
