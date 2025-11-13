import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/converter_provider.dart';
import '../widgets/url_input_widget.dart';
import '../widgets/video_info_card.dart';
import '../widgets/my_music_screen.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Untuk landscape, gunakan Row, untuk portrait gunakan Column
        if (isLandscape || screenWidth > screenHeight) {
          return Row(
            children: [
              // Left side: Converter
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(padding),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - (padding * 2),
                      ),
                      child: _buildConverterSection(context),
                    ),
                  ),
                ),
              ),
              // Divider
              const VerticalDivider(width: 1),
              // Right side: My Music
              Expanded(
                flex: 1,
                child: Container(
                  padding: EdgeInsets.all(padding),
                  child: const MyMusicScreen(),
                ),
              ),
            ],
          );
        } else {
          // Portrait mode untuk desktop (jarang, tapi tetap support)
          return Column(
            children: [
              // Top: Converter
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(padding),
                  child: SingleChildScrollView(
                    child: _buildConverterSection(context),
                  ),
                ),
              ),
              // Divider
              const Divider(height: 1),
              // Bottom: My Music
              Expanded(
                flex: 1,
                child: Container(
                  padding: EdgeInsets.all(padding),
                  child: const MyMusicScreen(),
                ),
              ),
            ],
          );
        }
      },
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
                // My Music Tab
                const MyMusicScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConverterSection(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    // Adjust icon size based on screen size
    final iconSize = isDesktop 
        ? (isLandscape ? 80.0 : 96.0).clamp(64.0, 96.0)
        : 64.0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 800 : double.infinity,
              maxHeight: constraints.maxHeight,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 0 : 16,
                  vertical: isDesktop ? 0 : 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Icon(
                      Icons.music_note,
                      size: iconSize,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(height: isDesktop ? 24 : 16),
                    
                    // Title
                    Text(
                      'YouTube Audio Downloader',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Download audio dari video YouTube (M4A/WebM)',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isDesktop ? 32 : 24),
                    
                    // URL Input
                    const UrlInputWidget(),
                    const SizedBox(height: 24),
                    
                    // Error Message (ditampilkan jika ada error)
                    Consumer<ConverterProvider>(
                      builder: (context, provider, child) {
                        if (provider.error != null && provider.videoInfo == null) {
                          return Card(
                            color: Colors.red.shade50,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red),
                                  const SizedBox(height: 8),
                                  Text(
                                    provider.error!,
                                    style: const TextStyle(color: Colors.red),
                                    textAlign: TextAlign.center,
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    
                    // Loading indicator saat fetch video info
                    Consumer<ConverterProvider>(
                      builder: (context, provider, child) {
                        if (provider.isLoading && provider.videoInfo == null) {
                          return const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    
                    // Video Info Card
                    Consumer<ConverterProvider>(
                      builder: (context, provider, child) {
                        if (provider.videoInfo != null) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Error message saat download (jika ada)
                              if (provider.error != null && provider.videoInfo != null)
                                Card(
                                  color: Colors.red.shade50,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.red),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            provider.error!,
                                            style: const TextStyle(color: Colors.red),
                                            textAlign: TextAlign.center,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              VideoInfoCard(videoInfo: provider.videoInfo!),
                            ],
                          );
                        }
                        
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

