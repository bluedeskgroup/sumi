import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';
import '../../../merchant/models/merchant_model.dart';

class MerchantDetailPage extends StatefulWidget {
  final MerchantModel merchant;

  const MerchantDetailPage({super.key, required this.merchant});

  @override
  State<MerchantDetailPage> createState() => _MerchantDetailPageState();
}

class _MerchantDetailPageState extends State<MerchantDetailPage> {
  final _adminService = AdminService.instance;
  late MerchantModel _merchant;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _merchant = widget.merchant;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_merchant.businessName),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        actions: [
          if (_merchant.status == MerchantStatus.pending) ...[
            IconButton(
              onPressed: () => _handleReject(),
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'رفض',
            ),
            IconButton(
              onPressed: () => _handleApprove(),
              icon: const Icon(Icons.check, color: Colors.green),
              tooltip: 'قبول',
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildInfoGrid(),
                  const SizedBox(height: 24),
                  _buildDocumentsSection(),
                  const SizedBox(height: 24),
                  _buildActionHistory(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile Image
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF667EEA),
                backgroundImage: _merchant.profileImageUrl.isNotEmpty
                    ? NetworkImage(_merchant.profileImageUrl)
                    : null,
                child: _merchant.profileImageUrl.isEmpty
                    ? Text(
                        _merchant.businessName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 20),
              // Basic Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _merchant.businessName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        _buildStatusBadge(_merchant.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _merchant.fullName,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Text(
                          'تاريخ التقديم: ${_formatDate(_merchant.createdAt)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (_merchant.reviewedAt != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text(
                            'تاريخ المراجعة: ${_formatDate(_merchant.reviewedAt!)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_merchant.businessDescription.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'وصف النشاط التجاري:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _merchant.businessDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildInfoCard('البريد الإلكتروني', _merchant.email, Icons.email),
        _buildInfoCard('رقم الهاتف', _merchant.phoneNumber, Icons.phone),
        _buildInfoCard('المدينة', _merchant.city, Icons.location_on),
        _buildInfoCard('نوع النشاط', _getBusinessTypeText(_merchant.businessType), Icons.business),
        _buildInfoCard('اسم البنك', _merchant.bankName, Icons.account_balance),
        _buildInfoCard('رقم الآيبان', _merchant.iban, Icons.credit_card),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF667EEA)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value.isNotEmpty ? value : 'غير محدد',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المستندات المرفقة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (_merchant.businessLicenseUrl.isNotEmpty)
              Expanded(
                child: _buildDocumentCard(
                  'السجل التجاري',
                  _merchant.businessLicenseUrl,
                  Icons.business_center,
                ),
              ),
            if (_merchant.businessLicenseUrl.isNotEmpty && _merchant.nationalIdImageUrl.isNotEmpty)
              const SizedBox(width: 16),
            if (_merchant.nationalIdImageUrl.isNotEmpty)
              Expanded(
                child: _buildDocumentCard(
                  'الهوية الوطنية',
                  _merchant.nationalIdImageUrl,
                  Icons.credit_card,
                ),
              ),
          ],
        ),
        if (_merchant.businessLicenseUrl.isEmpty && _merchant.nationalIdImageUrl.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.description, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'لا توجد مستندات مرفقة',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentCard(String title, String url, IconData icon) {
    return InkWell(
      onTap: () => _viewDocument(url, title),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: const Color(0xFF667EEA)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'اضغط للعرض',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionHistory() {
    if (_merchant.adminNotes == null && _merchant.statusReason == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'سجل الإجراءات',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_merchant.adminNotes != null) ...[
                const Text(
                  'ملاحظات الأدمن:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _merchant.adminNotes!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
              if (_merchant.statusReason != null) ...[
                if (_merchant.adminNotes != null) const SizedBox(height: 16),
                const Text(
                  'سبب القرار:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _merchant.statusReason!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
              if (_merchant.reviewedBy != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'تمت المراجعة بواسطة: ${_merchant.reviewedBy}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(MerchantStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case MerchantStatus.pending:
        color = Colors.orange;
        text = 'في الانتظار';
        icon = Icons.pending;
        break;
      case MerchantStatus.approved:
        color = Colors.green;
        text = 'مقبول';
        icon = Icons.check_circle;
        break;
      case MerchantStatus.rejected:
        color = Colors.red;
        text = 'مرفوض';
        icon = Icons.cancel;
        break;
      case MerchantStatus.suspended:
        color = Colors.grey;
        text = 'معلق';
        icon = Icons.pause_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _viewDocument(String url, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text('خطأ في تحميل الصورة'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleApprove() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _ApprovalDialog(merchant: _merchant),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _adminService.approveMerchantRequest(_merchant.id, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم قبول طلب التاجر بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
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
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleReject() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _RejectionDialog(merchant: _merchant),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _adminService.rejectMerchantRequest(_merchant.id, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم رفض طلب التاجر'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
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
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getBusinessTypeText(BusinessType type) {
    switch (type) {
      case BusinessType.retail:
        return 'بيع بالتجزئة';
      case BusinessType.wholesale:
        return 'بيع بالجملة';
      case BusinessType.services:
        return 'خدمات';
      case BusinessType.restaurant:
        return 'مطعم';
      case BusinessType.fashion:
        return 'أزياء';
      case BusinessType.electronics:
        return 'إلكترونيات';
      case BusinessType.health:
        return 'صحة وجمال';
      case BusinessType.home:
        return 'منزل وحديقة';
      case BusinessType.sports:
        return 'رياضة';
      case BusinessType.education:
        return 'تعليم';
      case BusinessType.other:
        return 'أخرى';
    }
  }
}

// Approval Dialog (same as in merchant_management_page.dart)
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

// Rejection Dialog (same as in merchant_management_page.dart)
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
