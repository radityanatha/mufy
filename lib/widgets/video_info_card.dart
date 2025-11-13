import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video_info.dart';
import '../models/audio_quality.dart';
import '../providers/converter_provider.dart';
import '../utils/responsive.dart';
import 'quality_selection_dialog.dart';

class VideoInfoCard extends StatelessWidget {
  final VideoInfo videoInfo;

  const VideoInfoCard({super.key, required this.videoInfo});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail dan Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    videoInfo.thumbnail,
                    width: isDesktop ? 160 : 120,
                    height: isDesktop ? 120 : 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: isDesktop ? 160 : 120,
                        height: isDesktop ? 120 : 90,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.video_library),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        videoInfo.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              videoInfo.channelName,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            videoInfo.duration,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Bar
            Consumer<ConverterProvider>(
              builder: (context, provider, child) {
                if (provider.downloadProgress > 0 && provider.downloadProgress < 1) {
                  return Column(
                    children: [
                      LinearProgressIndicator(value: provider.downloadProgress),
                      const SizedBox(height: 8),
                      Text(
                        '${(provider.downloadProgress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            // Convert Button
            Consumer<ConverterProvider>(
              builder: (context, provider, child) {
                if (provider.downloadProgress >= 1.0) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Download Selesai'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            // Show quality selection dialog
                            final selectedQuality = await showDialog<AudioQuality>(
                              context: context,
                              builder: (context) => QualitySelectionDialog(
                                selectedQuality: provider.selectedQuality,
                              ),
                            );

                            if (selectedQuality != null) {
                              provider.setQuality(selectedQuality);
                              provider.convertToMp3(quality: selectedQuality);
                            }
                          },
                    icon: const Icon(Icons.download),
                    label: Text(
                      provider.isLoading ? 'Mengunduh...' : 'Download Audio',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

