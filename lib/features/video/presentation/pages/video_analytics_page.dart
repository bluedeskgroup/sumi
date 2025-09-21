import 'package:flutter/material.dart';
import 'package:sumi/features/video/models/video_analytics_model.dart';
import 'package:sumi/features/video/services/video_analytics_service.dart';
import 'package:sumi/features/community/models/post_model.dart';

/// صفحة عرض إحصائيات الفيديو التفصيلية
class VideoAnalyticsPage extends StatefulWidget {
  final Post post;

  const VideoAnalyticsPage({super.key, required this.post});

  @override
  State<VideoAnalyticsPage> createState() => _VideoAnalyticsPageState();
}

class _VideoAnalyticsPageState extends State<VideoAnalyticsPage>
    with SingleTickerProviderStateMixin {
  final VideoAnalyticsService _analyticsService = VideoAnalyticsService();
  late TabController _tabController;
  
  VideoAnalytics? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await _analyticsService.getVideoAnalytics(widget.post.id);
      if (mounted) {
        setState(() {
          _analytics = analytics;
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('إحصائيات الفيديو'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'نظرة عامة'),
            Tab(text: 'المشاهدات'),
            Tab(text: 'التفاعل'),
            Tab(text: 'الجمهور'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
              ? _buildNoDataView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildViewsTab(),
                    _buildEngagementTab(),
                    _buildAudienceTab(),
                  ],
                ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد إحصائيات متاحة',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر الإحصائيات عند بدء المشاهدات',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVideoInfoCard(),
          const SizedBox(height: 16),
          _buildQuickStatsRow(),
          const SizedBox(height: 16),
          _buildPerformanceCard(),
          const SizedBox(height: 16),
          _buildRecommendationsCard(),
        ],
      ),
    );
  }

  Widget _buildVideoInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 60,
                color: Colors.grey[300],
                child: widget.post.mediaUrls.isNotEmpty
                    ? Image.network(
                        'https://picsum.photos/seed/${widget.post.id}/80/60',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => 
                            const Icon(Icons.video_library),
                      )
                    : const Icon(Icons.video_library),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.content,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'منذ ${_getTimeSinceUpload()}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getPerformanceColor(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _analytics?.performanceGrade ?? 'غير محدد',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('المشاهدات', '${_analytics?.totalViews ?? 0}', Icons.visibility)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('الإكمال', '${_analytics?.totalCompletions ?? 0}', Icons.check_circle)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('التقييم', widget.post.formattedRating, Icons.star)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الأداء',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            _buildPerformanceItem(
              'معدل الإكمال',
              '${((_analytics?.completionRate ?? 0.0) * 100).toStringAsFixed(1)}%',
              _analytics?.completionRate ?? 0.0,
            ),
            const SizedBox(height: 12),
            _buildPerformanceItem(
              'معدل التفاعل',
              '${_analytics?.engagementRate.toStringAsFixed(1) ?? '0.0'}%',
              (_analytics?.engagementRate ?? 0.0) / 100,
            ),
            const SizedBox(height: 12),
            _buildPerformanceItem(
              'متوسط وقت المشاهدة',
              _formatDuration(_analytics?.averageWatchTime ?? Duration.zero),
              _calculateWatchTimeProgress(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(String title, String value, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
        ),
      ],
    );
  }

  Widget _buildRecommendationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'توصيات للتحسين',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            ..._getRecommendations().map((recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(recommendation)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildViewsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildViewsOverviewCard(),
          const SizedBox(height: 16),
          _buildDropOffAnalysisCard(),
        ],
      ),
    );
  }

  Widget _buildViewsOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تحليل المشاهدات',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'إجمالي المشاهدات',
                    '${_analytics?.totalViews ?? 0}',
                    Icons.visibility,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'مشاهدين فريدين',
                    '${_analytics?.uniqueViewers ?? 0}',
                    Icons.person,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'إجمالي وقت المشاهدة',
                    _formatDuration(_analytics?.totalWatchTime ?? Duration.zero),
                    Icons.access_time,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'متوسط وقت المشاهدة',
                    _formatDuration(_analytics?.averageWatchTime ?? Duration.zero),
                    Icons.timer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropOffAnalysisCard() {
    final dropOffPoints = _analytics?.dropOffPoints ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نقاط ترك المشاهدة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (dropOffPoints.isEmpty)
              const Center(
                child: Text('لا توجد بيانات كافية'),
              )
            else
              ...dropOffPoints.entries.map((entry) {
                final timeInSeconds = entry.key;
                final count = entry.value;
                final timeFormatted = _formatSeconds(timeInSeconds);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('عند $timeFormatted'),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count ترك',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildEngagementOverviewCard(),
          const SizedBox(height: 16),
          _buildInteractionCard(),
        ],
      ),
    );
  }

  Widget _buildEngagementOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'التفاعل والمشاركة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'الإعجابات',
                    '${widget.post.likes.length}',
                    Icons.thumb_up,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'التعليقات',
                    '${widget.post.commentCount}',
                    Icons.comment,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'التقييمات',
                    '${widget.post.totalRatings}',
                    Icons.star,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'مرات الإكمال',
                    '${widget.post.completionCount}',
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معدلات التفاعل',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            _buildInteractionRate(
              'معدل الإعجاب',
              widget.post.likes.length,
              widget.post.viewCount,
            ),
            const SizedBox(height: 12),
            _buildInteractionRate(
              'معدل التعليق',
              widget.post.commentCount,
              widget.post.viewCount,
            ),
            const SizedBox(height: 12),
            _buildInteractionRate(
              'معدل الإكمال',
              widget.post.completionCount,
              widget.post.viewCount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionRate(String title, int interactions, int views) {
    final rate = views > 0 ? (interactions / views) * 100 : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(
              '${rate.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (rate / 100).clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(rate / 100)),
        ),
      ],
    );
  }

  Widget _buildAudienceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAudienceOverviewCard(),
          const SizedBox(height: 16),
          _buildBestTimeCard(),
        ],
      ),
    );
  }

  Widget _buildAudienceOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات الجمهور',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            _buildAudienceItem(
              'أكثر المناطق مشاهدة',
              _analytics?.topGeography ?? 'غير محدد',
              Icons.location_on,
            ),
            const SizedBox(height: 12),
            _buildAudienceItem(
              'أكثر الأجهزة استخداماً',
              _analytics?.topDevice ?? 'غير محدد',
              Icons.devices,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestTimeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أفضل أوقات النشر',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            _buildAudienceItem(
              'أفضل وقت للنشر',
              _analytics?.bestPublishTime ?? 'غير محدد',
              Icons.schedule,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudienceItem(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getTimeSinceUpload() {
    final now = DateTime.now();
    final difference = now.difference(widget.post.createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة';
    } else {
      return '${difference.inMinutes} دقيقة';
    }
  }

  Color _getPerformanceColor() {
    final grade = _analytics?.performanceGrade ?? 'ضعيف';
    switch (grade) {
      case 'ممتاز':
        return Colors.green;
      case 'جيد جداً':
        return Colors.blue;
      case 'جيد':
        return Colors.orange;
      case 'مقبول':
        return Colors.amber;
      default:
        return Colors.red;
    }
  }

  Color _getProgressColor(double value) {
    if (value >= 0.8) return Colors.green;
    if (value >= 0.6) return Colors.blue;
    if (value >= 0.4) return Colors.orange;
    return Colors.red;
  }

  double _calculateWatchTimeProgress() {
    if (widget.post.videoDurationSeconds == null || widget.post.videoDurationSeconds == 0) {
      return 0.0;
    }
    
    final averageSeconds = _analytics?.averageWatchTime.inSeconds ?? 0;
    return averageSeconds / widget.post.videoDurationSeconds!;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  List<String> _getRecommendations() {
    final recommendations = <String>[];
    
    if (_analytics != null) {
      if (_analytics!.completionRate < 0.3) {
        recommendations.add('معدل الإكمال منخفض - حاول جعل المحتوى أكثر جاذبية');
      }
      
      if (_analytics!.engagementRate < 5) {
        recommendations.add('معدل التفاعل منخفض - شجع المشاهدين على الإعجاب والتعليق');
      }
      
      if (_analytics!.averageWatchTime.inSeconds < (widget.post.videoDurationSeconds ?? 0) * 0.5) {
        recommendations.add('متوسط وقت المشاهدة قصير - حسن من جودة المقدمة');
      }
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('أداء جيد! استمر في إنتاج محتوى عالي الجودة');
    }
    
    return recommendations;
  }
}
