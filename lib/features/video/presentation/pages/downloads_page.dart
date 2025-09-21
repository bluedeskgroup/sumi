import 'package:flutter/material.dart';
import 'package:sumi/features/video/services/video_download_service.dart';
import 'package:shimmer/shimmer.dart';

/// صفحة إدارة التحميلات
class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage>
    with SingleTickerProviderStateMixin {
  final VideoDownloadService _downloadService = VideoDownloadService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _downloadService.addListener(_onDownloadServiceUpdate);
    _initializeService();
  }

  @override
  void dispose() {
    _downloadService.removeListener(_onDownloadServiceUpdate);
    _tabController.dispose();
    super.dispose();
  }

  void _onDownloadServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _initializeService() async {
    try {
      await _downloadService.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تهيئة خدمة التحميل: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('التحميلات'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: _showStorageInfo,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_completed',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('مسح المكتملة'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pause_all',
                child: Row(
                  children: [
                    Icon(Icons.pause_circle),
                    SizedBox(width: 8),
                    Text('إيقاف الكل'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cleanup',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services),
                    SizedBox(width: 8),
                    Text('تنظيف قديم'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              text: 'الكل (${_downloadService.allDownloads.length})',
            ),
            Tab(
              text: 'جاري التحميل (${_downloadService.activeDownloads.length})',
            ),
            Tab(
              text: 'مكتمل (${_downloadService.completedDownloads.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllDownloads(),
          _buildActiveDownloads(),
          _buildCompletedDownloads(),
        ],
      ),
    );
  }

  Widget _buildAllDownloads() {
    final downloads = _downloadService.allDownloads;
    
    if (downloads.isEmpty) {
      return _buildEmptyState(
        icon: Icons.download_outlined,
        title: 'لا توجد تحميلات',
        subtitle: 'ستظهر تحميلاتك هنا',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        return _buildDownloadCard(downloads[index]);
      },
    );
  }

  Widget _buildActiveDownloads() {
    final downloads = _downloadService.activeDownloads;
    
    if (downloads.isEmpty) {
      return _buildEmptyState(
        icon: Icons.downloading,
        title: 'لا توجد تحميلات نشطة',
        subtitle: 'ابدأ تحميل فيديو لتراه هنا',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        return _buildDownloadCard(downloads[index]);
      },
    );
  }

  Widget _buildCompletedDownloads() {
    final downloads = _downloadService.completedDownloads;
    
    if (downloads.isEmpty) {
      return _buildEmptyState(
        icon: Icons.download_done,
        title: 'لا توجد تحميلات مكتملة',
        subtitle: 'انتظر حتى تكتمل التحميلات',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        return _buildDownloadCard(downloads[index]);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadCard(DownloadInfo download) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // صورة مصغرة
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildThumbnailWidget(download),
                  ),
                ),
                const SizedBox(width: 12),
                // معلومات الفيديو
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        download.videoTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(download.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(download.status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            download.qualityLabel,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            download.formattedFileSize,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // أزرار التحكم
                _buildControlButtons(download),
              ],
            ),
            const SizedBox(height: 12),
            // شريط التقدم
            _buildProgressSection(download),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(DownloadInfo download) {
    switch (download.status) {
      case DownloadStatus.downloading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.pause, color: Colors.orange),
              onPressed: () => _downloadService.pauseDownload(download.id),
              tooltip: 'إيقاف مؤقت',
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _downloadService.cancelDownload(download.id),
              tooltip: 'إلغاء',
            ),
          ],
        );
      case DownloadStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.green),
              onPressed: () => _downloadService.resumeDownload(download.id),
              tooltip: 'استئناف',
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _downloadService.cancelDownload(download.id),
              tooltip: 'إلغاء',
            ),
          ],
        );
      case DownloadStatus.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.blue),
              onPressed: () => _playVideo(download),
              tooltip: 'تشغيل',
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.green),
              onPressed: () => _shareVideo(download),
              tooltip: 'مشاركة',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteDownload(download),
              tooltip: 'حذف',
            ),
          ],
        );
      case DownloadStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue),
              onPressed: () => _retryDownload(download),
              tooltip: 'إعادة المحاولة',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteDownload(download),
              tooltip: 'حذف',
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProgressSection(DownloadInfo download) {
    if (download.status == DownloadStatus.downloading) {
      return Column(
        children: [
          LinearProgressIndicator(
            value: download.progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(download.progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_formatBytes(download.downloadedBytes)} / ${download.formattedFileSize}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                download.remainingTime,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      );
    } else if (download.status == DownloadStatus.failed) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red[600], size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                download.errorMessage ?? 'خطأ غير معروف',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
        return 'في الانتظار';
      case DownloadStatus.downloading:
        return 'جاري التحميل';
      case DownloadStatus.paused:
        return 'متوقف';
      case DownloadStatus.completed:
        return 'مكتمل';
      case DownloadStatus.failed:
        return 'فشل';
      case DownloadStatus.cancelled:
        return 'ملغى';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes ب';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} ك.ب';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} م.ب';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ج.ب';
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear_completed':
        _clearCompletedDownloads();
        break;
      case 'pause_all':
        _pauseAllDownloads();
        break;
      case 'cleanup':
        _cleanupOldDownloads();
        break;
    }
  }

  void _clearCompletedDownloads() async {
    final completedDownloads = _downloadService.completedDownloads;
    for (final download in completedDownloads) {
      await _downloadService.deleteDownload(download.id);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم مسح التحميلات المكتملة')),
    );
  }

  void _pauseAllDownloads() async {
    final activeDownloads = _downloadService.activeDownloads;
    for (final download in activeDownloads) {
      await _downloadService.pauseDownload(download.id);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إيقاف جميع التحميلات')),
    );
  }

  void _cleanupOldDownloads() async {
    await _downloadService.cleanupOldDownloads();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تنظيف التحميلات القديمة')),
    );
  }

  void _showStorageInfo() async {
    final totalSize = await _downloadService.getTotalDownloadSize();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معلومات التخزين'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إجمالي التحميلات: ${_downloadService.allDownloads.length}'),
            Text('التحميلات النشطة: ${_downloadService.activeDownloads.length}'),
            Text('التحميلات المكتملة: ${_downloadService.completedDownloads.length}'),
            const SizedBox(height: 8),
            Text('المساحة المستخدمة: ${_formatBytes(totalSize)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _playVideo(DownloadInfo download) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم فتح مشغل الفيديو')),
    );
  }

  void _shareVideo(DownloadInfo download) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('مشاركة الفيديو')),
    );
  }

  void _deleteDownload(DownloadInfo download) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التحميل'),
        content: Text('هل تريد حذف "${download.videoTitle}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadService.deleteDownload(download.id);
            },
            child: const Text('حذف'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _retryDownload(DownloadInfo download) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('إعادة محاولة التحميل')),
    );
  }

  Widget _buildThumbnailWidget(DownloadInfo download) {
    // التحقق من أن thumbnailUrl صالح وليس ملف فيديو
    final url = download.thumbnailUrl;
    
    // إذا كان URL فارغ أو يحتوي على امتداد فيديو، عرض أيقونة
    if (url.isEmpty || 
        url.endsWith('.mp4') || 
        url.endsWith('.avi') || 
        url.endsWith('.mov') || 
        url.endsWith('.mkv')) {
      return Container(
        color: Colors.grey[400],
        child: const Icon(
          Icons.video_library,
          color: Colors.white,
          size: 24,
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        return progress == null
            ? child
            : Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(color: Colors.white),
              );
      },
      errorBuilder: (context, error, stack) {
        print('خطأ في تحميل الصورة المصغرة: $error');
        return Container(
          color: Colors.grey[400],
          child: const Icon(
            Icons.video_library,
            color: Colors.white,
            size: 24,
          ),
        );
      },
    );
  }
}
