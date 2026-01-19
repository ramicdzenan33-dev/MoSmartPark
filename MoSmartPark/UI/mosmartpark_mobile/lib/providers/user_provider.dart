
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mosmartpark_mobile/model/user.dart';
import 'package:mosmartpark_mobile/providers/base_provider.dart';

class UserProvider extends BaseProvider<User> {
  UserProvider() : super("Users");

  static User? currentUser;

  @override
  User fromJson(dynamic json) {
    return User.fromJson(json);
  }

  // Override insert to not send auth headers for registration
  @override
  Future<User> insert(dynamic request) async {
    var url = "${BaseProvider.baseUrl}Users";
    var uri = Uri.parse(url);
    // Don't include auth headers for registration (anonymous endpoint)
    var headers = {
      "Content-Type": "application/json",
    };

    var jsonRequest = jsonEncode(request);
    
    print("Registration request URL: $url");
    print("Registration request body: $jsonRequest");
    print("Registration headers: $headers");
    
    var response = await http.post(uri, headers: headers, body: jsonRequest);

    print("Registration response status: ${response.statusCode}");
    print("Registration response body: ${response.body}");

    if (response.statusCode < 299) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception("Registration failed: Please check your information and try again.");
    } else {
      var errorBody = response.body;
      print("Registration error: $errorBody");
      throw Exception("Registration failed: ${errorBody.isNotEmpty ? errorBody : 'Something went wrong, please try again later!'}");
    }
  }

  Future<User?> authenticate(String username, String password) async {
    var url = "${BaseProvider.baseUrl}Users/authenticate";
    var uri = Uri.parse(url);
    var headers = {"Content-Type": "application/json"};
    var body = jsonEncode({"username": username, "password": password});

    print("Attempting to authenticate at URL: $url");
    print("Request body: $body");

    try {
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(
            Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                "Request timed out. Please check your network connection.",
              );
            },
          );

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        currentUser = User.fromJson(data);
        return currentUser;
      } else if (response.statusCode == 401) {
        print("Authentication failed: Invalid credentials");
        return null;
      } else {
        print("Authentication failed with status code: ${response.statusCode}");
        throw Exception(
          "Failed to authenticate user. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("Exception during authentication: $e");
      if (e.toString().contains("SocketException") ||
          e.toString().contains("Connection refused")) {
        throw Exception(
          "Cannot connect to server. Please check:\n1. Your computer's IP address\n2. The server is running\n3. Both devices are on the same network",
        );
      }
      throw Exception("Authentication failed: $e");
    }
  }
}
