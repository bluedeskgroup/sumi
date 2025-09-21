import 'package:flutter/material.dart';
import 'package:sumi/features/video/services/video_download_service.dart';
import 'package:sumi/features/community/models/post_model.dart';

/// حوار اختيار جودة التحميل
class DownloadQualityDialog extends StatefulWidget {
  final Post post;
  final Function(String downloadId) onDownloadStarted;

  const DownloadQualityDialog({
    super.key,
    required this.post,
    required this.onDownloadStarted,
  });

  @override
  State<DownloadQualityDialog> createState() => _DownloadQualityDialogState();
}

class _DownloadQualityDialogState extends State<DownloadQualityDialog> {
  final VideoDownloadService _downloadService = VideoDownloadService();
  double _selectedQuality = 1.0;
  bool _isStartingDownload = false;

  final List<QualityOption> _qualityOptions = [
    QualityOption(
      quality: 0.5,
      label: '480p',
      description: 'جودة عادية - حجم أصغر',
      estimatedSize: '50-80 م.ب',
      icon: Icons.sd,
      color: Colors.orange,
    ),
    QualityOption(
      quality: 1.0,
      label: '720p',
      description: 'جودة عالية - متوازن',
      estimatedSize: '100-150 م.ب',
      icon: Icons.hd,
      color: Colors.blue,
    ),
    QualityOption(
      quality: 1.5,
      label: '1080p',
      description: 'جودة فائقة - حجم أكبر',
      estimatedSize: '200-300 م.ب',
      icon: Icons.hd,
      color: Colors.green,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildVideoInfo(),
            const SizedBox(height: 20),
            _buildQualityOptions(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.download,
            color: Colors.blue[600],
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'تحميل الفيديو',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildVideoInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 60,
              height: 45,
              color: Colors.grey[300],
              child: _buildThumbnailWidget(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.content,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      widget.post.userName,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.post.videoDurationSeconds != null)
                      Text(
                        widget.post.formattedDuration,
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
        ],
      ),
    );
  }

  Widget _buildQualityOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختر جودة التحميل:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._qualityOptions.map((option) => _buildQualityOption(option)),
      ],
    );
  }

  Widget _buildQualityOption(QualityOption option) {
    final isSelected = _selectedQuality == option.quality;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedQuality = option.quality;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? option.color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? option.color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<double>(
              value: option.quality,
              groupValue: _selectedQuality,
              onChanged: (value) {
                setState(() {
                  _selectedQuality = value!;
                });
              },
              activeColor: option.color,
            ),
            Icon(
              option.icon,
              color: isSelected ? option.color : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        option.label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelected ? option.color : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (option.quality == 1.0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'مُوصى',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    option.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'حجم تقديري: ${option.estimatedSize}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isStartingDownload ? null : () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isStartingDownload ? null : _startDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: _isStartingDownload
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('بدء التحميل'),
          ),
        ),
      ],
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _isStartingDownload = true;
    });

    try {
      final downloadId = await _downloadService.startDownload(
        post: widget.post,
        quality: _selectedQuality,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onDownloadStarted(downloadId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('بدأ تحميل "${widget.post.content}"'),
            action: SnackBarAction(
              label: 'عرض',
              onPressed: () {
                Navigator.pushNamed(context, '/downloads');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isStartingDownload = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في بدء التحميل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildThumbnailWidget() {
    // استخدام أيقونة فيديو بدلاً من محاولة تحميل صورة قد تكون معطوبة
    return Container(
      color: Colors.grey[400],
      child: const Icon(
        Icons.video_library,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

/// خيار جودة التحميل
class QualityOption {
  final double quality;
  final String label;
  final String description;
  final String estimatedSize;
  final IconData icon;
  final Color color;

  QualityOption({
    required this.quality,
    required this.label,
    required this.description,
    required this.estimatedSize,
    required this.icon,
    required this.color,
  });
}

/// عرض حوار اختيار جودة التحميل
Future<void> showDownloadQualityDialog({
  required BuildContext context,
  required Post post,
  required Function(String downloadId) onDownloadStarted,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => DownloadQualityDialog(
      post: post,
      onDownloadStarted: onDownloadStarted,
    ),
  );
}
