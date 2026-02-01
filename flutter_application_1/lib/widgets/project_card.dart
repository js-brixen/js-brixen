import 'package:flutter/material.dart';
import '../models/project.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onToggleFeatured;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
    this.onToggleFeatured,
  });

  @override
  Widget build(BuildContext context) {
    // Compact Card Design
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            height: 80, // Fixed height for compactness
            child: Row(
              children: [
                // 1. Thumbnail Image (Square)
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: project.images.isNotEmpty
                            ? Image.network(
                                project.images.first.url,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                      ),
                      // Type Badge (Tiny overlay)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            project.type.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title + Live Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              project.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(
                            project.status == ProjectStatus.live,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 10,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              project.district,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Stats + Edit Button
                      Row(
                        children: [
                          _buildStat(
                            Icons.visibility,
                            project.views.toString(),
                          ),
                          const SizedBox(width: 8),
                          _buildStat(
                            Icons.bookmark,
                            project.bookingConversions.toString(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Right Action (Edit/More)
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      size: 18,
                      color: Colors.blueAccent,
                    ),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.white.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.business_center, color: Colors.white24),
      ),
    );
  }

  Widget _buildStatusBadge(bool isLive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: isLive
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.2),
        border: Border.all(
          color: isLive ? Colors.green : Colors.grey,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isLive ? 'LIVE' : 'HIDDEN',
        style: TextStyle(
          color: isLive ? Colors.green : Colors.grey,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 10, color: Colors.white54),
        const SizedBox(width: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
} // End ProjectCard
