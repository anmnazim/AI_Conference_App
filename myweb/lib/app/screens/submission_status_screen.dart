import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/submission.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class SubmissionStatusScreen extends StatelessWidget {
  const SubmissionStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(
          future: AuthService.getCurrentUserProfile(),
          builder: (context, snapshot) {
            final name = snapshot.data?.name ?? 'My Submissions';
            return Text('${snapshot.connectionState == ConnectionState.done ? name : 'My Submissions'} - Submissions');
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService.userSubmissionsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          final submissions = docs
              .map((d) => Submission.fromDoc(d.id, d.data()))
              .toList();
          if (submissions.isEmpty) {
            return const Center(
              child: Text('No submissions yet.\nSubmit from the home screen.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final s = submissions[index];
              return _SubmissionCard(submission: s);
            },
          );
        },
      ),
    );
  }
}

class _SubmissionCard extends StatefulWidget {
  final Submission submission;

  const _SubmissionCard({required this.submission});

  @override
  State<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends State<_SubmissionCard> {
  bool _expanded = false;

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.submission.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (widget.submission.author != null && widget.submission.author!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Author: ${widget.submission.author}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(widget.submission.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.submission.status.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(widget.submission.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reference: ${widget.submission.referenceNumber}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
            Text(
              'Type: ${widget.submission.submissionType == 'abstract' ? 'Abstract' : 'Full Paper'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (widget.submission.createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Submitted: ${DateFormat.yMMMd().add_Hm().format(widget.submission.createdAt!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ),
            if ((widget.submission.extractedText?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                label: Text(_expanded ? 'Hide document' : 'View document'),
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      widget.submission.extractedText ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
