import 'dart:convert';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

/// Downloads a text file in Flutter Web
void downloadTextFileWeb(String text, String filename) {
  final bytes = utf8.encode(text);
  final blob = html.Blob([Uint8List.fromList(bytes)]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  // No variable needed, just create and click directly
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();

  html.Url.revokeObjectUrl(url);
}
