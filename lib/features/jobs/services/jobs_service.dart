import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_model.dart';
import '../models/job_application_model.dart';

class JobsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // جلب الوظائف المفعلة (للعرض في الرئيسية)
  Future<List<JobModel>> getActiveJobs({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('jobs')
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('expiresAt')
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => JobModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting active jobs: $e');
      return [];
    }
  }

  // جلب الوظائف المميزة
  Future<List<JobModel>> getFeaturedJobs({int limit = 5}) async {
    try {
      final querySnapshot = await _firestore
          .collection('jobs')
          .where('isActive', isEqualTo: true)
          .where('isFeatured', isEqualTo: true)
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => JobModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting featured jobs: $e');
      return [];
    }
  }

  // جلب جميع الوظائف (للأدمن)
  Future<List<JobModel>> getAllJobs() async {
    try {
      final querySnapshot = await _firestore
          .collection('jobs')
          .orderBy('publishedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => JobModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting all jobs: $e');
      return [];
    }
  }

  // البحث في الوظائف
  Future<List<JobModel>> searchJobs({
    String? query,
    String? category,
    String? location,
    String? jobType,
    double? minSalary,
    double? maxSalary,
  }) async {
    try {
      Query jobsQuery = _firestore
          .collection('jobs')
          .where('isActive', isEqualTo: true);

      if (category != null && category.isNotEmpty) {
        jobsQuery = jobsQuery.where('category', isEqualTo: category);
      }

      if (location != null && location.isNotEmpty) {
        jobsQuery = jobsQuery.where('location', isEqualTo: location);
      }

      if (jobType != null && jobType.isNotEmpty) {
        jobsQuery = jobsQuery.where('jobType', isEqualTo: jobType);
      }

      final querySnapshot = await jobsQuery
          .orderBy('publishedAt', descending: true)
          .get();

      List<JobModel> jobs = querySnapshot.docs
          .map((doc) => JobModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();

      // تصفية إضافية للراتب والبحث النصي
      if (query != null && query.isNotEmpty) {
        jobs = jobs.where((job) {
          return job.title.toLowerCase().contains(query.toLowerCase()) ||
              job.description.toLowerCase().contains(query.toLowerCase()) ||
              job.companyName.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }

      if (minSalary != null) {
        jobs = jobs.where((job) => 
            job.salaryMin != null && job.salaryMin! >= minSalary).toList();
      }

      if (maxSalary != null) {
        jobs = jobs.where((job) => 
            job.salaryMax != null && job.salaryMax! <= maxSalary).toList();
      }

      return jobs;
    } catch (e) {
      print('Error searching jobs: $e');
      return [];
    }
  }

  // جلب وظيفة واحدة
  Future<JobModel?> getJobById(String jobId) async {
    try {
      final doc = await _firestore.collection('jobs').doc(jobId).get();
      if (doc.exists) {
        return JobModel.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting job: $e');
      return null;
    }
  }

  // إنشاء وظيفة جديدة (للتجار)
  Future<String?> createJob(JobModel job) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final jobData = job.toJson();
      jobData.remove('id'); // إزالة الID لأن Firestore سيعطي واحد جديد

      final docRef = await _firestore.collection('jobs').add(jobData);
      return docRef.id;
    } catch (e) {
      print('Error creating job: $e');
      return null;
    }
  }

  // تحديث وظيفة
  Future<bool> updateJob(String jobId, JobModel job) async {
    try {
      final jobData = job.toJson();
      jobData.remove('id');

      await _firestore.collection('jobs').doc(jobId).update(jobData);
      return true;
    } catch (e) {
      print('Error updating job: $e');
      return false;
    }
  }

  // حذف وظيفة
  Future<bool> deleteJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).delete();
      
      // حذف جميع الطلبات المرتبطة بالوظيفة
      final applications = await _firestore
          .collection('job_applications')
          .where('jobId', isEqualTo: jobId)
          .get();
      
      for (final doc in applications.docs) {
        await doc.reference.delete();
      }
      
      return true;
    } catch (e) {
      print('Error deleting job: $e');
      return false;
    }
  }

  // تفعيل/إلغاء تفعيل وظيفة
  Future<bool> toggleJobStatus(String jobId, bool isActive) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'isActive': isActive,
      });
      return true;
    } catch (e) {
      print('Error toggling job status: $e');
      return false;
    }
  }

  // تقديم طلب وظيفة
  Future<String?> applyToJob(JobApplicationModel application) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // التحقق من عدم تقديم طلب سابق لنفس الوظيفة
      final existingApplication = await _firestore
          .collection('job_applications')
          .where('jobId', isEqualTo: application.jobId)
          .where('applicantId', isEqualTo: application.applicantId)
          .get();

      if (existingApplication.docs.isNotEmpty) {
        throw Exception('لقد قدمت طلباً لهذه الوظيفة من قبل');
      }

      final applicationData = application.toJson();
      applicationData.remove('id');

      final docRef = await _firestore.collection('job_applications').add(applicationData);

      // زيادة عدد المتقدمين للوظيفة
      await _firestore.collection('jobs').doc(application.jobId).update({
        'applicationsCount': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      print('Error applying to job: $e');
      return null;
    }
  }

  // جلب طلبات الوظائف للمستخدم
  Future<List<JobApplicationModel>> getUserApplications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('job_applications')
          .where('applicantId', isEqualTo: userId)
          .orderBy('appliedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => JobApplicationModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting user applications: $e');
      return [];
    }
  }

  // جلب طلبات الوظائف لوظيفة معينة (للناشر/أدمن)
  Future<List<JobApplicationModel>> getJobApplications(String jobId) async {
    try {
      final querySnapshot = await _firestore
          .collection('job_applications')
          .where('jobId', isEqualTo: jobId)
          .orderBy('appliedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => JobApplicationModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting job applications: $e');
      return [];
    }
  }

  // تحديث حالة طلب وظيفة
  Future<bool> updateApplicationStatus(
    String applicationId, 
    ApplicationStatus status,
    {String? employerNotes}
  ) async {
    try {
      final updateData = {
        'status': status.toString(),
        'statusUpdatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (employerNotes != null) {
        updateData['employerNotes'] = employerNotes;
      }

      await _firestore
          .collection('job_applications')
          .doc(applicationId)
          .update(updateData);

      return true;
    } catch (e) {
      print('Error updating application status: $e');
      return false;
    }
  }

  // جلب الوظائف للتاجر
  Future<List<JobModel>> getMerchantJobs(String merchantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('jobs')
          .where('publisherId', isEqualTo: merchantId)
          .orderBy('publishedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => JobModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting merchant jobs: $e');
      return [];
    }
  }

  // إحصائيات للأدمن
  Future<Map<String, int>> getJobsStatistics() async {
    try {
      final allJobs = await _firestore.collection('jobs').get();
      final activeJobs = await _firestore
          .collection('jobs')
          .where('isActive', isEqualTo: true)
          .get();
      final featuredJobs = await _firestore
          .collection('jobs')
          .where('isFeatured', isEqualTo: true)
          .get();
      final applications = await _firestore.collection('job_applications').get();

      return {
        'totalJobs': allJobs.docs.length,
        'activeJobs': activeJobs.docs.length,
        'featuredJobs': featuredJobs.docs.length,
        'totalApplications': applications.docs.length,
      };
    } catch (e) {
      print('Error getting jobs statistics: $e');
      return {
        'totalJobs': 0,
        'activeJobs': 0,
        'featuredJobs': 0,
        'totalApplications': 0,
      };
    }
  }
}
