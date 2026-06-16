import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('========== LOGIN DEBUG ==========');
      print('URL: $baseUrl/users/login.php');
      print('Email: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/login.php'),
        body: {'email': email, 'password': password},
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );
      
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed Data: $data');
        
        if (data['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          
          dynamic userIdRaw = data['user']['user_id'];
          int userId;
          if (userIdRaw is int) {
            userId = userIdRaw;
          } else if (userIdRaw is String) {
            userId = int.parse(userIdRaw);
          } else {
            userId = int.parse(userIdRaw.toString());
          }
          
          await prefs.setInt('user_id', userId);
          await prefs.setString('role', data['user']['role'].toString());
          await prefs.setString('email', data['user']['email'].toString());
          await prefs.setString('name', data['user']['name'].toString());
          
          print('Session saved - UserId: $userId, Role: ${data['user']['role']}');
        }
        print('================================');
        return data;
      }
      print('Non-200 status code: ${response.statusCode}');
      print('================================');
      return {'success': false, 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      print('Login Exception: $e');
      print('================================');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return null;
    return {
      'user_id': userId,
      'role': prefs.getString('role'),
      'email': prefs.getString('email'),
      'name': prefs.getString('name'),
    };
  }

  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stats/dashboard_stats.php'));
      print('Dashboard stats response: ${response.body}');
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      return {'success': false, 'stats': {'total_students': 0, 'total_teachers': 0, 'total_classes': 0, 'total_subjects': 0}};
    } catch (e) {
      print('Dashboard stats error: $e');
      return {'success': false, 'stats': {'total_students': 0, 'total_teachers': 0, 'total_classes': 0, 'total_subjects': 0}};
    }
  }

  static Future<Map<String, dynamic>> getUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/get_users.php'));
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('Get users error: $e');
      return {'success': false, 'users': []};
    }
  }

  static Future<Map<String, dynamic>> getUserDetails(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/get_user_details.php?user_id=$userId'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Get user details error: $e');
      return {'success': false, 'user': null};
    }
  }

  static Future<Map<String, dynamic>> addUser(String name, String email, String password, String role, int schoolId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/add_user.php'),
        body: {
          'full_name': name,
          'email': email,
          'password': password,
          'role': role,
          'school_id': schoolId.toString(),
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Add user error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> addTeacher(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/add_teacher.php'),
        body: {
          'full_name': data['full_name'],
          'email': data['email'],
          'password': data['password'],
          'staff_no': data['staff_no'] ?? '',
          'phone': data['phone'] ?? '',
          'gender': data['gender'] ?? '',
          'address': data['address'] ?? '',
          'nationality': data['nationality'] ?? '',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Add teacher error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> addStudentFull(
    String fullName,
    String email,
    String password,
    String gender,
    String nationality,
    String parentContact,
    String admissionNo,
    int? classId,
    dynamic photo,
  ) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/add_student_full.php'));
      request.fields['full_name'] = fullName;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['gender'] = gender;
      request.fields['nationality'] = nationality;
      request.fields['parent_contact'] = parentContact;
      request.fields['admission_no'] = admissionNo;
      request.fields['class_id'] = classId?.toString() ?? '';
      
      if (photo != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
      }
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      print('Add student response: $responseData');
      return jsonDecode(responseData);
    } catch (e) {
      print('Add student full error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getClasses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/classes/get_classes.php'));
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('Get classes error: $e');
      return {'success': false, 'classes': []};
    }
  }

  static Future<Map<String, dynamic>> getClassesForSchool(int schoolId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/classes/get_classes.php'),
        body: {'school_id': schoolId.toString()},
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Get classes for school error: $e');
      return {'success': false, 'classes': []};
    }
  }

  static Future<Map<String, dynamic>> addClassToSchool(String className, String stream, String classCode, int schoolId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/classes/add_class.php'),
        body: {
          'class_name': className,
          'stream': stream,
          'class_code': classCode,
          'school_id': schoolId.toString(),
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Add class error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> addClass(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/classes/add_class.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Add class JSON error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSubjects() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/subjects/get_subjects.php'));
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('Get subjects error: $e');
      return {'success': false, 'subjects': []};
    }
  }

  static Future<Map<String, dynamic>> addNewSubject(String code, String name, String desc) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/subjects/add_subject.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'subject_code': code, 'subject_name': name}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Add subject error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/subjects/get_subjects.php'));
      print('Test connection - Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Test connection - Error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> addStudentFullWeb(
    String fullName,
    String email,
    String password,
    String gender,
    String nationality,
    String parentContact,
    String admissionNo,
    int? classId,
    String? imageBase64,
    String? imageName,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/add_student_web.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'gender': gender,
          'nationality': nationality,
          'parent_contact': parentContact,
          'admission_no': admissionNo,
          'class_id': classId,
          'photo_base64': imageBase64,
          'photo_name': imageName,
        }),
      );
      print('Add student response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('Add student web error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> addUserWithPhoto(
    String fullName,
    String email,
    String password,
    String role,
    int schoolId,
    String? photoBase64,
    String? photoName,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/add_user_with_photo.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'role': role,
          'school_id': schoolId,
          'photo_base64': photoBase64,
          'photo_name': photoName,
        }),
      );
      print('Add user with photo response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('Add user with photo error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getStudentsByClass(int classId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/classes/get_students_by_class.php?class_id=$classId'));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'students': []};
    }
  }

  static Future<Map<String, dynamic>> saveAttendance(int classId, String date, String session, Map<int, String> attendance) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordedBy = prefs.getInt('user_id') ?? 1;
      
      Map<String, String> stringAttendance = {};
      attendance.forEach((key, value) {
        stringAttendance[key.toString()] = value;
      });
      
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/save_attendance.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'class_id': classId,
          'attendance_date': date,
          'attendance_session': session,
          'recorded_by': recordedBy,
          'attendance': stringAttendance,
        }),
      );
      print('Save attendance response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('Save attendance error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> saveMarks(int classId, int subjectId, String examType, int term, Map<int, double> marks) async {
    try {
      Map<String, double> stringMarks = {};
      marks.forEach((key, value) {
        stringMarks[key.toString()] = value;
      });
      
      final response = await http.post(
        Uri.parse('$baseUrl/proxy_save_marks.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'class_id': classId,
          'subject_id': subjectId,
          'exam_type': examType,
          'term': term,
          'academic_year': DateTime.now().year,
          'total_marks': 100,
          'marks': stringMarks,
        }),
      );
      print('Save marks response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('Save marks error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getStudentDetails(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/get_student_details.php?user_id=$userId'));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'student': null};
    }
  }

  static Future<Map<String, dynamic>> getStudentAttendance(int studentId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/attendance/get_student_attendance.php?student_id=$studentId'));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'attendance': []};
    }
  }

  static Future<Map<String, dynamic>> getStudentResults(int studentId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/marks/get_student_results.php?student_id=$studentId'));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'results': []};
    }
  }

  static Future<Map<String, dynamic>> getAttendanceList(int classId, String date) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/attendance/get_attendance_list.php?class_id=$classId&date=$date'));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'attendance': []};
    }
  }

  static Future<Map<String, dynamic>> getFinalResults(int classId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/marks/get_final_results.php?class_id=$classId'));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'results': []};
    }
  }

  static Future<Map<String, dynamic>> changePassword(String email, String oldPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change_password.php'),
        body: {
          'email': email,
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
      print('Change password response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('Change password error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAllAttendance(int classId, String date) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/attendance/get_all_attendance.php?class_id=$classId&date=$date'));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'attendance': []};
    }
  }

  static Future<Map<String, dynamic>> getResultsByClass(int classId, int? subjectId, int term) async {
    try {
      String url = '$baseUrl/marks/get_results_by_class.php?class_id=$classId&term=$term';
      if (subjectId != null) {
        url += '&subject_id=$subjectId';
      }
      final response = await http.get(Uri.parse(url));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'results': []};
    }
  }

  static Future<Map<String, dynamic>> sendNotification(String title, String message, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/send.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'message': message,
          'role': role,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getClassReport(int classId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reports/class_report.php?class_id=$classId'));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'students': []};
    }
  }

  static Future<Map<String, dynamic>> assignTeacherToSubject(int teacherId, int subjectId, int classId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/assignments/assign_teacher.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'teacher_id': teacherId,
          'subject_id': subjectId,
          'class_id': classId,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getTeacherAssignments() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/assignments/get_assignments.php'));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'assignments': []};
    }
  }

  static Future<Map<String, dynamic>> removeTeacherAssignment(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/assignments/remove_assignment.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> enrollStudent(int studentId, int classId, String academicYear) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enrollments/enroll.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': studentId,
          'class_id': classId,
          'academic_year': academicYear,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getEnrollments() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/enrollments/get_enrollments.php'));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'enrollments': []};
    }
  }

  static Future<Map<String, dynamic>> removeEnrollment(int enrollmentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enrollments/remove_enrollment.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'enrollment_id': enrollmentId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getTeacherClasses(int teacherId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/classes/get_teacher_classes.php?teacher_id=$teacherId'));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'classes': []};
    }
  }

  static Future<Map<String, dynamic>> deleteSubject(int subjectId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/subjects/delete_subject.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'subject_id': subjectId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteClass(int classId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/classes/delete_class.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'class_id': classId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> editUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/edit_user.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/delete_user.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAttendanceRecords({int? teacherId, int? classId, String? date}) async {
    try {
      String url = '$baseUrl/attendance/get_attendance_records.php?';
      List<String> params = [];
      if (teacherId != null) params.add('teacher_id=$teacherId');
      if (classId != null) params.add('class_id=$classId');
      if (date != null && date.isNotEmpty) params.add('date=$date');
      url += params.join('&');
      
      final response = await http.get(Uri.parse(url));
      return jsonDecode(response.body);
    } catch (e) {
      print('Get attendance records error: $e');
      return {'success': false, 'attendance': []};
    }
  }

  static Future<Map<String, dynamic>> getTeacherAttendanceStats(int teacherId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/attendance/get_teacher_attendance_stats.php?teacher_id=$teacherId'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Get teacher attendance stats error: $e');
      return {'success': false, 'stats': []};
    }
  }

  static Future<Map<String, dynamic>> getTeacherSubjects(int teacherId) async {
    try {
      print('Getting subjects for teacher ID: $teacherId');
      final url = '$baseUrl/subjects/get_teacher_subjects.php?teacher_id=$teacherId';
      print('Request URL: $url');
      final response = await http.get(Uri.parse(url));
      print('Subjects response status: ${response.statusCode}');
      print('Subjects response body: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('Get teacher subjects error: $e');
      return {'success': false, 'subjects': []};
    }
  }

  static Future<Map<String, dynamic>> getTeacherMarks(int teacherId, {int? classId, int? subjectId, int term = 1}) async {
    try {
      String url = '$baseUrl/marks/get_teacher_marks.php?teacher_id=$teacherId&term=$term';
      if (classId != null) {
        url += '&class_id=$classId';
      }
      if (subjectId != null) {
        url += '&subject_id=$subjectId';
      }
      final response = await http.get(Uri.parse(url));
      return jsonDecode(response.body);
    } catch (e) {
      print('Get teacher marks error: $e');
      return {'success': false, 'marks': []};
    }
  }

  static Future<Map<String, dynamic>> getStudentsWithWarningsAdmin({int? classId, int threshold = 8}) async {
    try {
      String url = '$baseUrl/attendance/get_students_for_warning.php?threshold=$threshold';
      if (classId != null) {
        url += '&class_id=$classId';
      }
      final response = await http.get(Uri.parse(url));
      return jsonDecode(response.body);
    } catch (e) {
      print('Get students for warning error: $e');
      return {'success': false, 'students': []};
    }
  }

  static Future<Map<String, dynamic>> sendWarningAdmin({required int studentId, required String message, required String warningType}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminId = prefs.getInt('user_id') ?? 1;
      
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/send_warning_admin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': studentId,
          'admin_id': adminId,
          'message': message,
          'warning_type': warningType,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Send warning admin error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getStudentCalculatedResults(int studentId, int term) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/marks/calculate_results.php?student_id=$studentId&term=$term'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Get student calculated results error: $e');
      return {'success': false, 'results': []};
    }
  }

  // Grading System Methods
  static Future<Map<String, dynamic>> getGradingSystem() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/grading/get_grades.php'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Get grading system error: $e');
      return {'success': false, 'grades': []};
    }
  }

  static Future<Map<String, dynamic>> addGrade(String gradeName, double minScore, double maxScore, String remarks) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/grading/add_grade.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grade_name': gradeName,
          'min_score': minScore,
          'max_score': maxScore,
          'remarks': remarks,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Add grade error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteGrade(int gradeId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/grading/delete_grade.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'grade_id': gradeId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Delete grade error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}








