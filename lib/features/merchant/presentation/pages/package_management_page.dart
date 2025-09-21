import 'package:flutter/material.dart';
import '../../models/package_model.dart';
import '../../services/package_service.dart';

class PackageManagementPage extends StatefulWidget {
  final String merchantId;

  const PackageManagementPage({
    super.key,
    required this.merchantId,
  });

  @override
  State<PackageManagementPage> createState() => _PackageManagementPageState();
}

class _PackageManagementPageState extends State<PackageManagementPage> {
  final PackageService _packageService = PackageService.instance;
  List<PackageModel> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);
    
    try {
      final packages = await _packageService.getMerchantPackages(widget.merchantId);
      setState(() {
        _packages = packages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('فشل في تحميل الباقات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            'إدارة الباقات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.orange),
              onPressed: _showAddPackageDialog,
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _loadPackages,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildPackagesList(),
      ),
    );
  }

  Widget _buildPackagesList() {
    if (_packages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد باقات بعد',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على زر + لإضافة باقتك الأولى',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _packages.length,
      itemBuilder: (context, index) => _buildPackageCard(_packages[index]),
    );
  }

  Widget _buildPackageCard(PackageModel package) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    package.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildPackageStatusBadge(package.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              package.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            
            // السعر والخصم
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${package.price.toStringAsFixed(0)} ر.س',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (package.discountPercentage > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'خصم ${package.discountPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // عدد العناصر
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'يحتوي على ${package.items.length} عنصر',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // أزرار الإجراءات
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editPackage(package),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('تعديل'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _togglePackageStatus(package),
                    icon: Icon(
                      package.status == PackageStatus.active
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 18,
                    ),
                    label: Text(
                      package.status == PackageStatus.active
                          ? 'إيقاف'
                          : 'تفعيل',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: package.status == PackageStatus.active
                          ? Colors.orange
                          : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageStatusBadge(PackageStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case PackageStatus.active:
        color = Colors.green;
        text = 'نشط';
        break;
      case PackageStatus.inactive:
        color = Colors.grey;
        text = 'غير نشط';
        break;
      case PackageStatus.limited:
        color = Colors.orange;
        text = 'محدود';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showAddPackageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة باقة جديدة'),
        content: const Text('هذه الميزة قيد التطوير حالياً.\nسيتم إضافتها في التحديثات القادمة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _editPackage(PackageModel package) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ميزة تعديل الباقة قيد التطوير'),
      ),
    );
  }

  void _togglePackageStatus(PackageModel package) async {
    final newStatus = package.status == PackageStatus.active
        ? PackageStatus.inactive
        : PackageStatus.active;
    
    final success = await _packageService.updatePackageStatus(package.id, newStatus);
    
    if (success) {
      _loadPackages();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == PackageStatus.active
                ? 'تم تفعيل الباقة بنجاح'
                : 'تم إيقاف الباقة بنجاح',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showErrorSnackBar('فشل في تحديث حالة الباقة');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
