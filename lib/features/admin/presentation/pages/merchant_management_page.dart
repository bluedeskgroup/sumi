import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';
import '../../models/admin_model.dart';
import '../../../merchant/models/merchant_model.dart';
import 'merchant_detail_page.dart';

class MerchantManagementPage extends StatefulWidget {
  const MerchantManagementPage({super.key});

  @override
  State<MerchantManagementPage> createState() => _MerchantManagementPageState();
}

class _MerchantManagementPageState extends State<MerchantManagementPage>
    with TickerProviderStateMixin {
  final _adminService = AdminService.instance;
  late TabController _tabController;
  
  MerchantStatus _selectedStatus = MerchantStatus.pending;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _selectedStatus = MerchantStatus.pending;
              break;
            case 1:
              _selectedStatus = MerchantStatus.approved;
              break;
            case 2:
              _selectedStatus = MerchantStatus.rejected;
              break;
            case 3:
              _selectedStatus = MerchantStatus.suspended;
              break;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('إدارة التجار'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: _buildSearchAndTabs(),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMerchantsList(MerchantStatus.pending),
                _buildMerchantsList(MerchantStatus.approved),
                _buildMerchantsList(MerchantStatus.rejected),
                _buildMerchantsList(MerchantStatus.suspended),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSearchAndTabs() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'البحث عن التجار...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF667EEA),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF667EEA),
            tabs: const [
              Tab(text: 'في الانتظار'),
              Tab(text: 'مقبول'),
              Tab(text: 'مرفوض'),
              Tab(text: 'معلق'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantsList(MerchantStatus status) {
    return StreamBuilder<List<MerchantModel>>(
      stream: _adminService.getMerchantRequests(status: status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('خطأ في جلب البيانات: ${snapshot.error}'),
          );
        }

        List<MerchantModel> merchants = snapshot.data ?? [];

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          merchants = merchants.where((merchant) {
            return merchant.businessName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   merchant.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   merchant.email.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }

        if (merchants.isEmpty) {
          return _buildEmptyState(status);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: merchants.length,
          itemBuilder: (context, index) {
            return _buildMerchantCard(merchants[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(MerchantStatus status) {
    String message;
    IconData icon;
    
    switch (status) {
      case MerchantStatus.pending:
        message = 'لا توجد طلبات في الانتظار';
        icon = Icons.inbox;
        break;
      case MerchantStatus.approved:
        message = 'لا يوجد تجار مقبولين';
        icon = Icons.verified;
        break;
      case MerchantStatus.rejected:
        message = 'لا يوجد تجار مرفوضين';
        icon = Icons.cancel;
        break;
      case MerchantStatus.suspended:
        message = 'لا يوجد تجار معلقين';
        icon = Icons.pause_circle;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantCard(MerchantModel merchant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MerchantDetailPage(merchant: merchant),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF667EEA),
                    backgroundImage: merchant.profileImageUrl.isNotEmpty
                        ? NetworkImage(merchant.profileImageUrl)
                        : null,
                    child: merchant.profileImageUrl.isEmpty
                        ? Text(
                            merchant.businessName.isNotEmpty
                                ? merchant.businessName[0].toUpperCase()
                                : 'T',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                merchant.businessName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            _buildStatusBadge(merchant.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          merchant.fullName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.email, size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                merchant.email,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              merchant.phoneNumber,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              merchant.city,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'تاريخ التقديم: ${_formatDate(merchant.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  if (merchant.status == MerchantStatus.pending)
                    Row(
                      children: [
                        _buildActionButton(
                          'رفض',
                          Icons.close,
                          Colors.red,
                          () => _handleReject(merchant),
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          'قبول',
                          Icons.check,
                          Colors.green,
                          () => _handleApprove(merchant),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MerchantStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case MerchantStatus.pending:
        color = Colors.orange;
        text = 'في الانتظار';
        break;
      case MerchantStatus.approved:
        color = Colors.green;
        text = 'مقبول';
        break;
      case MerchantStatus.rejected:
        color = Colors.red;
        text = 'مرفوض';
        break;
      case MerchantStatus.suspended:
        color = Colors.grey;
        text = 'معلق';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(80, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  Future<void> _handleApprove(MerchantModel merchant) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _ApprovalDialog(merchant: merchant),
    );

    if (result != null) {
      try {
        await _adminService.approveMerchantRequest(merchant.id, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم قبول طلب التاجر بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في قبول الطلب: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleReject(MerchantModel merchant) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _RejectionDialog(merchant: merchant),
    );

    if (result != null) {
      try {
        await _adminService.rejectMerchantRequest(merchant.id, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم رفض طلب التاجر'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في رفض الطلب: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Approval Dialog
class _ApprovalDialog extends StatefulWidget {
  final MerchantModel merchant;

  const _ApprovalDialog({required this.merchant});

  @override
  State<_ApprovalDialog> createState() => __ApprovalDialogState();
}

class __ApprovalDialogState extends State<_ApprovalDialog> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('الموافقة على طلب التاجر'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('هل تريد الموافقة على طلب التاجر "${widget.merchant.businessName}"؟'),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'ملاحظات (اختيارية)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _notesController.text),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('موافق'),
        ),
      ],
    );
  }
}

// Rejection Dialog
class _RejectionDialog extends StatefulWidget {
  final MerchantModel merchant;

  const _RejectionDialog({required this.merchant});

  @override
  State<_RejectionDialog> createState() => __RejectionDialogState();
}

class __RejectionDialogState extends State<_RejectionDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('رفض طلب التاجر'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('هل تريد رفض طلب التاجر "${widget.merchant.businessName}"؟'),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'سبب الرفض *',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_reasonController.text.trim().isNotEmpty) {
              Navigator.pop(context, _reasonController.text);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('رفض'),
        ),
      ],
    );
  }
}
