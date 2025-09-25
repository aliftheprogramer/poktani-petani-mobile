import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../model/user.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final String _baseUrl = 'http://localhost:3000/api';
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  void init() {
    _logger.i('🔧 Initializing API Service...');
    _logger.i('🌐 Base URL: $_baseUrl');

    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor untuk menambahkan token dan logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          _logger.d('📤 REQUEST: ${options.method} ${options.uri}');
          _logger.d('📋 Headers: ${options.headers}');
          _logger.d('📦 Data: ${options.data}');

          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            _logger.d('🔑 Token added to headers');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.i(
            '📥 RESPONSE: ${response.statusCode} ${response.requestOptions.uri}',
          );
          _logger.d('📄 Response Data: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('❌ API ERROR: ${error.type}');
          _logger.e('🔗 URL: ${error.requestOptions.uri}');
          _logger.e('📋 Method: ${error.requestOptions.method}');
          _logger.e('📦 Request Data: ${error.requestOptions.data}');
          _logger.e('📋 Request Headers: ${error.requestOptions.headers}');

          if (error.response != null) {
            _logger.e('📥 Response Status: ${error.response?.statusCode}');
            _logger.e('📄 Response Data: ${error.response?.data}');
            _logger.e('📋 Response Headers: ${error.response?.headers}');
          } else {
            _logger.e('🌐 Network Error: ${error.message}');
            _logger.e('🔗 Error Type: ${error.type}');
          }

          handler.next(error);
        },
      ),
    );

    _logger.i('✅ API Service initialized successfully');
  }

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      _logger.d('🔍 Making GET request to: $path');
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response;
    } catch (e) {
      _logger.e('❌ GET request failed: $e');
      rethrow;
    }
  }

  // POST request
  Future<Response> post(String path, {dynamic data}) async {
    try {
      _logger.d('📤 Making POST request to: $path');
      _logger.d('📦 POST data: $data');
      final response = await _dio.post(path, data: data);
      return response;
    } catch (e) {
      _logger.e('❌ POST request failed: $e');
      rethrow;
    }
  }

  // PUT request
  Future<Response> put(String path, {dynamic data}) async {
    try {
      _logger.d('📤 Making PUT request to: $path');
      final response = await _dio.put(path, data: data);
      return response;
    } catch (e) {
      _logger.e('❌ PUT request failed: $e');
      rethrow;
    }
  }

  // DELETE request
  Future<Response> delete(String path) async {
    try {
      _logger.d('🗑️ Making DELETE request to: $path');
      final response = await _dio.delete(path);
      return response;
    } catch (e) {
      _logger.e('❌ DELETE request failed: $e');
      rethrow;
    }
  }

  // Optional: validate token by pinging a protected endpoint
  Future<bool> validateToken() async {
    try {
      final response = await get('/auth/me');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Upload file
  Future<Response> uploadFile(
    String path,
    String filePath,
    String fieldName,
  ) async {
    try {
      _logger.d('📁 Uploading file to: $path');
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(path, data: formData);
      return response;
    } catch (e) {
      _logger.e('❌ File upload failed: $e');
      rethrow;
    }
  }

  // Auth methods
  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String fullName,
    required String address,
    String role = 'Petani',
  }) async {
    _logger.i('👤 Starting registration process...');
    _logger.d('📱 Phone: $phone');
    _logger.d('👤 Full Name: $fullName');
    _logger.d('📍 Address: $address');
    _logger.d('👨‍🌾 Role: $role');

    try {
      final requestData = {
        'phone': phone,
        'password': password,
        'fullName': fullName,
        'address': address,
        'role': role,
      };

      _logger.d('📤 Sending registration request...');
      final response = await post('/auth/register', data: requestData);

      _logger.i('✅ Registration successful!');
      _logger.d('📄 Response: ${response.data}');

      return {
        'success': true,
        'message': response.data['message'],
        'user': User.fromJson(response.data['user']),
      };
    } catch (e) {
      _logger.e('❌ Registration failed: $e');

      if (e is DioException) {
        _logger.e('🔍 DioException details:');
        _logger.e('   Type: ${e.type}');
        _logger.e('   Message: ${e.message}');
        _logger.e('   Response: ${e.response?.data}');
        _logger.e('   Status Code: ${e.response?.statusCode}');

        return {
          'success': false,
          'message':
              e.response?.data['message'] ?? 'Terjadi kesalahan pada server',
          'error_type': e.type.toString(),
          'status_code': e.response?.statusCode,
        };
      }

      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi: $e',
        'error_type': 'network_error',
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    _logger.i('🔐 Starting login process...');
    _logger.d('📱 Phone: $phone');

    try {
      final requestData = {'phone': phone, 'password': password};

      _logger.d('📤 Sending login request...');
      final response = await post('/auth/login', data: requestData);

      _logger.i('✅ Login successful!');
      _logger.d('📄 Response: ${response.data}');

      return {
        'success': true,
        'message': response.data['message'],
        'token': response.data['token'],
        'user': User.fromJson(response.data['user']),
      };
    } catch (e) {
      _logger.e('❌ Login failed: $e');

      if (e is DioException) {
        _logger.e('🔍 DioException details:');
        _logger.e('   Type: ${e.type}');
        _logger.e('   Message: ${e.message}');
        _logger.e('   Response: ${e.response?.data}');
        _logger.e('   Status Code: ${e.response?.statusCode}');

        return {
          'success': false,
          'message':
              e.response?.data['message'] ?? 'Terjadi kesalahan pada server',
          'error_type': e.type.toString(),
          'status_code': e.response?.statusCode,
        };
      }

      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi: $e',
        'error_type': 'network_error',
      };
    }
  }
}
