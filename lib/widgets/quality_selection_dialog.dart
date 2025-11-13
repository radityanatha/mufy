import 'package:flutter/material.dart';
import '../models/audio_quality.dart';

class QualitySelectionDialog extends StatelessWidget {
  final AudioQuality selectedQuality;

  const QualitySelectionDialog({
    super.key,
    required this.selectedQuality,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Kualitas Audio'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AudioQuality.values.map((quality) {
            final isSelected = quality == selectedQuality;
            return ListTile(
              leading: Radio<AudioQuality>(
                value: quality,
                groupValue: selectedQuality,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.of(context).pop(value);
                  }
                },
              ),
              title: Text(
                quality.shortLabel,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                quality.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () {
                Navigator.of(context).pop(quality);
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(selectedQuality),
          child: const Text('Download'),
        ),
      ],
    );
  }
}

