import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class CloudinaryService {
  static const String cloudName = "dulwrbrzs";
  static const String uploadPreset = "turf_upload";

  static Future<String> uploadTurfImage(File file) async {
    final url =
    Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest("POST", url)
      ..fields["upload_preset"] = uploadPreset
      ..files.add(
        await http.MultipartFile.fromPath(
          "file",
          file.path,
          contentType: MediaType("image", "jpeg"),
        ),
      );

    final response = await request.send();
    final resStr = await response.stream.bytesToString();
    final data = json.decode(resStr);

    if (response.statusCode == 200) {
      return data["secure_url"]; // Cloudinary URL
    } else {
      throw Exception("Cloudinary upload failed: $data");
    }
  }
}
