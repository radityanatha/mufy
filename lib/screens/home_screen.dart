import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/converter_provider.dart';
import '../widgets/url_input_widget.dart';
import '../widgets/video_info_card.dart';
import '../widgets/downloaded_songs_list.dart';
import '../utils/responsive.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final padding = Responsive.getPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube to MP3 Converter'),
        centerTitle: !isDesktop,
        elevation: 0,
      ),
      body: isDesktop 
          ? _buildDesktopLayout(context, padding) 
          : _buildMobileLayout(context, padding),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, double padding) {
    return Row(
      children: [
        // Left side: Converter
        Expanded(
          flex: 2,
          child: Container(
            padding: EdgeInsets.all(padding),
            child: _buildConverterSection(context),
          ),
        ),
        // Divider
        const VerticalDivider(width: 1),
        // Right side: Downloaded Songs
        Expanded(
          flex: 1,
          child: Container(
            padding: EdgeInsets.all(padding),
            child: const DownloadedSongsList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, double padding) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Converter', icon: Icon(Icons.download)),
              Tab(text: 'My Music', icon: Icon(Icons.library_music)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Converter Tab
                SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: _buildConverterSection(context),
                ),
                // Downloaded Songs Tab
                const DownloadedSongsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConverterSection(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              Icons.music_note,
              size: Responsive.isDesktop(context) ? 96 : 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'YouTube to MP3',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Convert video YouTube menjadi file MP3',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // URL Input
            const UrlInputWidget(),
            const SizedBox(height: 24),
            
            // Video Info Card
            Consumer<ConverterProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.videoInfo == null) {
                  return const CircularProgressIndicator();
                }
                
                if (provider.error != null && provider.videoInfo == null) {
                  return Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(height: 8),
                          Text(
                            provider.error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                if (provider.videoInfo != null) {
                  return VideoInfoCard(videoInfo: provider.videoInfo!);
                }
                
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

