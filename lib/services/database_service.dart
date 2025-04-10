import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fasumku/models/facility.dart';
import 'package:fasumku/models/comment.dart';
import 'package:fasumku/models/facility_status_history.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;

  // USER METHODS

  // Get current user ID dari SharedPreferences (perbaikan untuk manual auth)
  Future<int> getCurrentUserId() async {
    // Coba ambil dari SharedPreferences dulu
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId != null && userId.isNotEmpty) {
      return int.parse(userId);
    }

    // Jika tidak ada di SharedPreferences, coba dari Supabase Auth (fallback)
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Get user ID from profiles table
    final response = await _supabase
        .from('users')
        .select('id')
        .eq('auth_id', user.id)
        .single();

    return response['id'];
  }

  // Cek status login
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  // Simpan data user setelah login manual
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    // Simpan ID dan status login
    await prefs.setString('user_id', userData['id'].toString());
    await prefs.setBool('is_logged_in', true);

    // Simpan data user lainnya
    if (userData['phone'] != null) {
      await prefs.setString('user_phone', userData['phone']);
    }
    if (userData['name'] != null) {
      await prefs.setString('user_name', userData['name']);
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Coba logout dari supabase juga jika sedang login
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // Ignore errors, we're primarily using manual auth
    }
  }

  // Get user name by ID
  Future<String?> getUserName(int userId) async {
    final response = await _supabase
        .from('users')
        .select('name')
        .eq('id', userId)
        .single();

    return response['name'];
  }

  // FACILITY METHODS

  // Create a new facility
  Future<int> createFacility(Facility facility) async {
    final response = await _supabase
        .from('facilities')
        .insert(facility.toMap())
        .select('id')
        .single();

    return response['id'];
  }

  // Get facility by ID
  Future<Facility> getFacilityById(int id) async {
    final response = await _supabase
        .from('facilities')
        .select()
        .eq('id', id)
        .single();

    return Facility.fromJson(response);
  }

  // Update facility
  Future<void> updateFacility(Facility facility) async {
    if (facility.id == null) {
      throw Exception('Cannot update a facility without an ID');
    }

    await _supabase
        .from('facilities')
        .update(facility.toMap())
        .eq('id', facility.id.toString());
  }

  // Update facility status
  Future<void> updateFacilityStatus(int facilityId, String newStatus, String? note) async {
    await _supabase
        .from('facilities')
        .update({
      'status': newStatus,
      'status_note': note,
    })
        .eq('id', facilityId);
  }

  // Delete facility
  Future<void> deleteFacility(int facilityId) async {
    await _supabase
        .from('facilities')
        .delete()
        .eq('id', facilityId);
  }

  // Get all facilities
  Future<List<Facility>> getAllFacilities() async {
    final response = await _supabase
        .from('facilities')
        .select()
        .order('report_date', ascending: false);

    return response.map<Facility>((item) => Facility.fromMap(item)).toList();
  }

  // Get facilities by category
  Future<List<Facility>> getFacilitiesByCategory(String category) async {
    final response = await _supabase
        .from('facilities')
        .select()
        .eq('category', category)
        .order('report_date', ascending: false);

    return response.map<Facility>((item) => Facility.fromMap(item)).toList();
  }

  // Get facilities by status
  Future<List<Facility>> getFacilitiesByStatus(String status) async {
    final response = await _supabase
        .from('facilities')
        .select()
        .eq('status', status)
        .order('report_date', ascending: false);

    return response.map<Facility>((item) => Facility.fromMap(item)).toList();
  }

  // COMMENT METHODS

  // Add a comment
  Future<int> addComment(Comment comment) async {
    final response = await _supabase
        .from('comments')
        .insert(comment.toJson())
        .select('id')
        .single();

    return response['id'];
  }

  // Get comments by facility ID
  Future<List<Comment>> getCommentsByFacilityId(int facilityId) async {
    // Join with users table to get user names
    final response = await _supabase
        .from('comments')
        .select('''
          *,
          users:user_id (name)
        ''')
        .eq('facility_id', facilityId)
        .order('created_at', ascending: false);

    return response.map<Comment>((item) {
      // Create a modified map with user_name added
      final Map<String, dynamic> commentMap = {
        ...item,
        'user_name': item['users'] != null ? item['users']['name'] : null,
      };
      return Comment.fromJson(commentMap);
    }).toList();
  }

  // Delete comment
  Future<void> deleteComment(int commentId) async {
    await _supabase
        .from('comments')
        .delete()
        .eq('id', commentId);
  }

  // STATUS HISTORY METHODS

  // Add status history
  Future<int> addStatusHistory(FacilityStatusHistory history) async {
    final response = await _supabase
        .from('facility_status_history')
        .insert(history.toJson())
        .select('id')
        .single();

    return response['id'];
  }

  // Get status history by facility ID
  Future<List<FacilityStatusHistory>> getStatusHistoryByFacilityId(int facilityId) async {
    // Join with users table to get user names
    final response = await _supabase
        .from('facility_status_history')
        .select('''
          *,
          users:changed_by (name)
        ''')
        .eq('facility_id', facilityId)
        .order('changed_at', ascending: false);

    return response.map<FacilityStatusHistory>((item) {
      // Create a modified map with user_name added
      final Map<String, dynamic> historyMap = {
        ...item,
        'user_name': item['users'] != null ? item['users']['name'] : null,
      };
      return FacilityStatusHistory.fromJson(historyMap);
    }).toList();
  }
}