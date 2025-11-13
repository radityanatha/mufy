import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/converter_provider.dart';
import '../providers/playlist_provider.dart';
import '../models/playlist.dart';
import '../models/downloaded_song.dart';

class MyMusicScreen extends StatelessWidget {
  const MyMusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenHeight = MediaQuery.of(context).size.height;
    final expandedHeight = isLandscape
        ? (screenHeight * 0.2).clamp(120.0, 180.0)
        : (screenHeight * 0.25).clamp(150.0, 250.0);
    final iconSize = isLandscape ? 60.0 : 80.0;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header seperti Spotify
          SliverAppBar(
            expandedHeight: expandedHeight,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Your Library',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1DB954), // Spotify Green
                      const Color(0xFF1DB954).withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.library_music,
                    size: iconSize,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Actions
                _buildQuickActions(context),

                // Playlists Section
                _buildPlaylistsSection(context),

                // Songs Section
                _buildSongsSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showCreatePlaylistDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Playlist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954), // Spotify Green
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistsSection(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        if (playlistProvider.playlists.isEmpty) {
          return const SizedBox.shrink();
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final isPortrait =
            MediaQuery.of(context).orientation == Orientation.portrait;
        final cardHeight = isPortrait ? 180.0 : 160.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Playlists',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: cardHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                itemCount: playlistProvider.playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlistProvider.playlists[index];
                  return _buildPlaylistCard(context, playlist);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaylistCard(BuildContext context, Playlist playlist) {
    return Consumer<ConverterProvider>(
      builder: (context, converterProvider, child) {
        // Ambil thumbnail dari lagu pertama di playlist
        String? thumbnail;
        if (playlist.songIds.isNotEmpty) {
          try {
            final firstSong = converterProvider.downloadedSongs.firstWhere(
              (s) => s.id == playlist.songIds.first,
            );
            thumbnail = firstSong.thumbnail;
          } catch (e) {
            thumbnail = null;
          }
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final isPortrait =
            MediaQuery.of(context).orientation == Orientation.portrait;
        final cardWidth = isPortrait
            ? (screenWidth * 0.35).clamp(120.0, 160.0)
            : (screenWidth * 0.25).clamp(140.0, 180.0);

        return Container(
          width: cardWidth,
          margin: EdgeInsets.only(right: screenWidth * 0.03),
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () => _navigateToPlaylist(context, playlist),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover Image
                  Flexible(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: thumbnail != null
                          ? Image.network(
                              thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.library_music,
                                    size: 50,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.library_music, size: 50),
                            ),
                    ),
                  ),
                  // Playlist Info
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${playlist.songCount} songs',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSongsSection(BuildContext context) {
    return Consumer<ConverterProvider>(
      builder: (context, converterProvider, child) {
        if (converterProvider.downloadedSongs.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
            child: Center(
              child: Text(
                'No songs downloaded yet',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }

        final screenWidth = MediaQuery.of(context).size.width;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: 8,
              ),
              child: Text(
                'Songs',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
              itemCount: converterProvider.downloadedSongs.length,
              itemBuilder: (context, index) {
                final song = converterProvider.downloadedSongs[index];
                return _buildSongTile(context, song);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSongTile(BuildContext context, DownloadedSong song) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: 2),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.02,
          vertical: 4,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            song.thumbnail,
            width: isPortrait ? 56 : 48,
            height: isPortrait ? 56 : 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: isPortrait ? 56 : 48,
                height: isPortrait ? 56 : 48,
                color: Colors.grey.shade300,
                child: const Icon(Icons.music_note),
              );
            },
          ),
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'Downloaded ${_formatDate(song.downloadedAt)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'add_to_playlist',
              child: Row(
                children: [
                  Icon(Icons.playlist_add, size: 20),
                  SizedBox(width: 8),
                  Text('Add to Playlist'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'add_to_playlist') {
              _showAddToPlaylistDialog(context, song);
            } else if (value == 'delete') {
              _showDeleteDialog(context, song);
            }
          },
        ),
        onTap: () {
          // TODO: Play song
        },
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                hintText: 'My Playlist',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add a description',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                context.read<PlaylistProvider>().createPlaylist(
                  nameController.text,
                  description: descriptionController.text.isEmpty
                      ? null
                      : descriptionController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Playlist created'),
                    backgroundColor: const Color(0xFF1DB954),
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, DownloadedSong song) {
    // Baca provider langsung seperti _showDeleteDialog
    final playlistProvider = context.read<PlaylistProvider>();
    final playlists = playlistProvider.playlists;

    // Jika tidak ada playlist, tampilkan dialog sederhana
    if (playlists.isEmpty) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Add to Playlist'),
          content: const Text('Create a playlist first'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showCreatePlaylistDialog(context);
              },
              child: const Text('Create Playlist'),
            ),
          ],
        ),
      );
      return;
    }

    // Gunakan showModalBottomSheet untuk menghindari rendering error
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) {
        final maxHeight = MediaQuery.of(dialogContext).size.height * 0.7;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add to Playlist',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List playlist
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final isInPlaylist = playlist.songIds.contains(song.id);

                    return ListTile(
                      leading: const Icon(Icons.playlist_play),
                      title: Text(playlist.name),
                      subtitle: Text('${playlist.songCount} songs'),
                      trailing: isInPlaylist
                          ? const Icon(Icons.check, color: Color(0xFF1DB954))
                          : const Icon(Icons.add),
                      onTap: () async {
                        if (!isInPlaylist) {
                          try {
                            await playlistProvider.addSongToPlaylist(
                              playlist.id,
                              song.id,
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added to ${playlist.name}'),
                                  backgroundColor: const Color(0xFF1DB954),
                                ),
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } else {
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Already in ${playlist.name}'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToPlaylist(BuildContext context, Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, DownloadedSong song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song'),
        content: Text('Delete "${song.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ConverterProvider>().deleteSong(song.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Playlist Detail Screen
class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          // Hapus IconButton - hanya gunakan FloatingActionButton untuk konsistensi
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Delete Playlist',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _showDeletePlaylistDialog(context);
              }
            },
          ),
        ],
      ),
      body: Consumer2<PlaylistProvider, ConverterProvider>(
        builder: (context, playlistProvider, converterProvider, child) {
          final songs = playlistProvider.getSongsInPlaylist(
            playlist.id,
            converterProvider.downloadedSongs,
          );

          if (songs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.playlist_play, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'This playlist is empty',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSongsToPlaylistDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Songs'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    song.thumbnail,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.music_note),
                      );
                    },
                  ),
                ),
                title: Text(song.title),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    playlistProvider.removeSongFromPlaylist(
                      playlist.id,
                      song.id,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed from ${playlist.name}'),
                        backgroundColor: const Color(0xFF1DB954),
                      ),
                    );
                  },
                ),
                onTap: () {
                  // TODO: Play song
                },
              );
            },
          );
        },
      ),
      // Hanya gunakan FloatingActionButton untuk menambah lagu
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSongsToPlaylistDialog(context),
        backgroundColor: const Color(0xFF1DB954),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Fungsi baru untuk menampilkan dialog add songs ke playlist
  void _showAddSongsToPlaylistDialog(BuildContext context) {
    // Baca provider langsung seperti _showDeleteDialog
    final playlistProvider = context.read<PlaylistProvider>();
    final converterProvider = context.read<ConverterProvider>();

    // Cek apakah ada lagu yang didownload
    if (converterProvider.downloadedSongs.isEmpty) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Add Songs to Playlist'),
          content: const Text('No songs available. Download some songs first.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    // Dapatkan playlist terbaru dari provider atau gunakan yang di-pass
    final currentPlaylist =
        playlistProvider.playlists
            .where((p) => p.id == playlist.id)
            .firstOrNull ??
        playlist;

    // Filter lagu yang belum ada di playlist
    final songIds = currentPlaylist.songIds;
    final availableSongs = converterProvider.downloadedSongs
        .where((song) => !songIds.contains(song.id))
        .toList();

    // Jika semua lagu sudah ada di playlist
    if (availableSongs.isEmpty) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Add Songs to Playlist'),
          content: const Text('All songs are already in this playlist.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    // Gunakan showModalBottomSheet untuk menghindari rendering error
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => Consumer2<PlaylistProvider, ConverterProvider>(
        builder: (context, playlistProvider, converterProvider, child) {
          // Refresh available songs
          final currentPlaylistRefresh =
              playlistProvider.playlists
                  .where((p) => p.id == playlist.id)
                  .firstOrNull ??
              playlist;
          final songIdsRefresh = currentPlaylistRefresh.songIds;
          final availableSongsRefresh = converterProvider.downloadedSongs
              .where((song) => !songIdsRefresh.contains(song.id))
              .toList();

          final maxHeight = MediaQuery.of(dialogContext).size.height * 0.7;
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Songs to ${playlist.name}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // List songs
                Flexible(
                  child: availableSongsRefresh.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'All songs are already in this playlist.',
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: availableSongsRefresh.length,
                          itemBuilder: (context, index) {
                            final song = availableSongsRefresh[index];
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  song.thumbnail,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.grey.shade300,
                                      child: const Icon(
                                        Icons.music_note,
                                        size: 20,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.add),
                              onTap: () async {
                                try {
                                  await playlistProvider.addSongToPlaylist(
                                    playlist.id,
                                    song.id,
                                  );
                                  // Tampilkan feedback
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Added ${song.title} to ${playlist.name}',
                                        ),
                                        backgroundColor: const Color(
                                          0xFF1DB954,
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                  // Dialog akan auto-update karena Consumer2
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeletePlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Delete "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<PlaylistProvider>().deletePlaylist(playlist.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close playlist detail screen
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Playlist deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
