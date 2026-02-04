/// Submission stored in Firestore `submissions` collection.
class Submission {
  final String id;
  final String uid;
  final String referenceNumber;
  final String title;
  final String? author;
  final String? pdfUrl;
  final String? docBase64;
  final String? docName;
  final String? extractedText;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final String submissionType; // 'abstract' | 'fullpaper'
  final DateTime? createdAt;

  Submission({
    required this.id,
    required this.uid,
    required this.referenceNumber,
    required this.title,
    this.author,
    this.pdfUrl,
    this.docBase64,
    this.docName,
    this.extractedText,
    required this.status,
    required this.submissionType,
    this.createdAt,
  });

  factory Submission.fromDoc(String id, Map<String, dynamic> data) {
    Object? ts = data['createdAt'];
    DateTime? createdAt;
    if (ts is DateTime) {
      createdAt = ts;
    } else if (ts != null) {
      try {
        createdAt = (ts as dynamic).toDate();
      } catch (_) {}
    }
    return Submission(
      id: id,
      uid: data['uid'] as String? ?? '',
      referenceNumber: data['referenceNumber'] as String? ?? '',
      title: data['title'] as String? ?? '',
      author: data['author'] as String?,
      pdfUrl: data['pdfUrl'] as String?,
      docBase64: data['docBase64'] as String?,
      docName: data['docName'] as String?,
      extractedText: data['extractedText'] as String?,
      status: (data['status'] as String? ?? 'pending').toLowerCase(),
      submissionType: data['submissionType'] as String? ?? 'abstract',
      createdAt: createdAt,
    );
  }
}
