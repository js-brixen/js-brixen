import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/internal_note.dart';
import '../services/firestore_admin_service.dart';

class InternalNotesWidget extends StatefulWidget {
  final String bookingId;
  final String? customerEmail; // Added customerEmail

  const InternalNotesWidget({
    super.key,
    required this.bookingId,
    this.customerEmail,
  });

  @override
  State<InternalNotesWidget> createState() => _InternalNotesWidgetState();
}

class _InternalNotesWidgetState extends State<InternalNotesWidget> {
  final FirestoreAdminService _firestoreService = FirestoreAdminService();
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  // Helper to format sender name
  String _getDisplayName(InternalNote note) {
    // If exact match with customer email, show 'Customer'
    if (widget.customerEmail != null &&
        note.authorName.toLowerCase() == widget.customerEmail!.toLowerCase()) {
      return 'Customer';
    }

    // If it looks like an email, strip domain
    if (note.authorName.contains('@')) {
      return note.authorName.split('@')[0];
    }

    return note.authorName;
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await _firestoreService.addInternalNote(
        widget.bookingId,
        text: _noteController.text.trim(),
      );
      _noteController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add note: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, HH:mm').format(timestamp);
    }
  }

  Future<void> _deleteAllNotes() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notes'),
        content: const Text(
          'Are you sure you want to delete all internal notes? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isSubmitting = true);

      // Get all notes first
      final notes = await _firestoreService
          .streamInternalNotes(widget.bookingId)
          .first;

      // Delete each note
      for (final note in notes) {
        await _firestoreService.deleteInternalNote(widget.bookingId, note.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${notes.length} notes deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete notes: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Internal Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (!_isSubmitting)
              IconButton(
                onPressed: _deleteAllNotes,
                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                tooltip: 'Delete All Notes',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Add note input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'Add a note...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                maxLines: 2,
                enabled: !_isSubmitting,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isSubmitting ? null : _addNote,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Notes list
        StreamBuilder<List<InternalNote>>(
          stream: _firestoreService.streamInternalNotes(widget.bookingId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final notes = snapshot.data ?? [];

            if (notes.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'No notes yet. Add one above!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final note = notes[index];
                final displayName = _getDisplayName(note);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.cyan.withValues(alpha: 0.2),
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.cyan,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatTimestamp(note.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            color: Colors.red.shade400,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              // Confirm before delete
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF1a1a2e),
                                  title: const Text(
                                    'Delete Note',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to delete this note?',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade600,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await _firestoreService.deleteInternalNote(
                                    widget.bookingId,
                                    note.id,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Note deleted'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(note.text, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
