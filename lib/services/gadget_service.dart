import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart';

class GadgetService {
  static final String? baseUrl = dotenv.env['BACKEND_URL'];

  static Future<dynamic> recognizeGadget(File imageFile) async {
    try {
      var uri = Uri.parse("$baseUrl/gadgets/recognize");
      var request = http.MultipartRequest("POST", uri);
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: basename(imageFile.path),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
