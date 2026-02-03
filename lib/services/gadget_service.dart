import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart';

class GadgetService {
  static final String baseUrl = dotenv.env['BACKEND_URL'] ?? 
    "https://might-ampora-backend-p4tz.onrender.com/api/v1";

  static Future<dynamic> recognizeGadget(File imageFile) async {
    try {
      var uri = Uri.parse("$baseUrl/gadgets/recognize");
      var request = http.MultipartRequest("POST", uri);
      print("URI: $uri");
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: basename(imageFile.path),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("STATUS CODE: ${response.statusCode}");
      print("RAW BODY: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print("PARSED RESPONSE: $data");
        return data;
      } else {
        print("Upload failed → ${response.body}");
        return null;
      }
    } catch (e) {
      print("ERROR → $e");
      return null;
    }
  }
}
