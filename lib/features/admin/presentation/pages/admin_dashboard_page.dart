import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/admin_model.dart';
import 'merchant_management_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _adminService = AdminService.instance;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardTab(),
    const MerchantManagementPage(),
    const UsersTab(),
    const SettingsTab(),
  ];

  final List<NavigationRailDestination> _destinations = [
    const NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('لوحة التحكم'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.store_outlined),
      selectedIcon: Icon(Icons.store),
      label: Text('التجار'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: Text('المستخدمين'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('الإعدادات'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkAdminAuth();
    _loadDashboardStats();
  }

  Future<void> _checkAdminAuth() async {
    // التحقق من حالة تسجيل دخول الأدمن
    if (!_adminService.isLoggedIn) {
      // إذا لم يكن مسجل دخول، توجيه لصفحة تسجيل الدخول
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/admin-login');
        }
      });
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      final stats = await _adminService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    // إظهار تأكيد قبل تسجيل الخروج
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد تسجيل الخروج'),
        content: const Text('هل أنت متأكد من أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _adminService.logoutAdmin();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/admin-login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: const Color(0xFF1F2937),
            selectedIconTheme: const IconThemeData(color: Color(0xFF667EEA)),
            unselectedIconTheme: const IconThemeData(color: Colors.grey),
            selectedLabelTextStyle: const TextStyle(color: Color(0xFF667EEA)),
            unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
            destinations: _destinations,
            leading: _buildUserProfile(),
            trailing: _buildLogoutButton(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    final admin = _adminService.currentAdmin;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF667EEA),
            child: Text(
              (admin?.fullName != null && admin!.fullName.isNotEmpty) 
                  ? admin.fullName.substring(0, 1).toUpperCase() 
                  : 'A',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            admin?.fullName ?? 'أدمن',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            admin?.role.toString().split('.').last ?? '',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: IconButton(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout, color: Colors.red),
        tooltip: 'تسجيل الخروج',
      ),
    );
  }
}

// Dashboard Tab
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final _adminService = AdminService.instance;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _adminService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('لوحة التحكم الرئيسية'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(),
                  const SizedBox(height: 24),
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildRecentActivity(),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    final admin = _adminService.currentAdmin;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحباً، ${admin?.fullName ?? 'أدمن'}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'أهلاً بك في لوحة تحكم تطبيق سومي',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                'آخر تسجيل دخول: ${_formatDate(admin?.lastLoginAt)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final merchants = _stats['merchants'] ?? {};
    final users = _stats['users'] ?? {};
    final products = _stats['products'] ?? {};
    final orders = _stats['orders'] ?? {};

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          title: 'طلبات التجار المعلقة',
          value: '${merchants['pending'] ?? 0}',
          icon: Icons.pending_actions,
          color: Colors.orange,
          subtitle: 'في انتظار المراجعة',
        ),
        _buildStatCard(
          title: 'التجار المقبولين',
          value: '${merchants['approved'] ?? 0}',
          icon: Icons.verified,
          color: Colors.green,
          subtitle: 'تاجر نشط',
        ),
        _buildStatCard(
          title: 'إجمالي المستخدمين',
          value: '${users['total'] ?? 0}',
          icon: Icons.people,
          color: Colors.blue,
          subtitle: 'مستخدم مسجل',
        ),
        _buildStatCard(
          title: 'إجمالي المنتجات',
          value: '${products['total'] ?? 0}',
          icon: Icons.inventory,
          color: Colors.purple,
          subtitle: 'منتج متاح',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'جديد',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الإجراءات السريعة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'مراجعة طلبات التجار',
                subtitle: '${_stats['merchants']?['pending'] ?? 0} طلب في الانتظار',
                icon: Icons.rate_review,
                color: Colors.orange,
                onTap: () {
                  // Navigate to merchant requests
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'إدارة المستخدمين',
                subtitle: 'عرض وإدارة حسابات المستخدمين',
                icon: Icons.manage_accounts,
                color: Colors.blue,
                onTap: () {
                  // Navigate to users management
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'الإعدادات العامة',
                subtitle: 'تكوين إعدادات التطبيق',
                icon: Icons.settings,
                color: Colors.grey,
                onTap: () {
                  // Navigate to settings
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'النشاط الأخير',
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
          child: const Center(
            child: Text(
              'سيتم عرض النشاط الأخير هنا',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'غير محدد';
    try {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'غير محدد';
    }
  }
}

// Placeholder tabs
class UsersTab extends StatelessWidget {
  const UsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Center(
        child: Text(
          'إدارة المستخدمين - قريباً',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFDF2F8),
      body: Center(
        child: Text(
          'الإعدادات - قريباً',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}
