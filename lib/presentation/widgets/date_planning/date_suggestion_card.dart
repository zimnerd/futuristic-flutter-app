import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';

/// Widget for displaying date suggestion information
class DateSuggestionCard extends StatelessWidget {
  final Map<String, dynamic> suggestion;
  final VoidCallback? onTap;

  const DateSuggestionCard({super.key, required this.suggestion, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String title = suggestion['title'] ?? 'Date Suggestion';
    final String description = suggestion['description'] ?? '';
    final String location = suggestion['location'] ?? '';
    final String category = suggestion['category'] ?? '';
    final String estimatedCost = suggestion['estimatedCost'] ?? '';
    final double rating = (suggestion['rating'] ?? 0.0).toDouble();
    final int duration = suggestion['duration'] ?? 0;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (rating > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: PulseColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(description, style: TextStyle(color: Colors.grey[600])),
              ],

              const SizedBox(height: 12),

              // Suggestion details
              Column(
                children: [
                  if (location.isNotEmpty)
                    _buildDetailRow(Icons.location_on, 'Location', location),
                  if (category.isNotEmpty)
                    _buildDetailRow(Icons.category, 'Category', category),
                  if (estimatedCost.isNotEmpty)
                    _buildDetailRow(
                      Icons.attach_money,
                      'Estimated Cost',
                      estimatedCost,
                    ),
                  if (duration > 0)
                    _buildDetailRow(
                      Icons.access_time,
                      'Duration',
                      '${duration}h',
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PulseColors.primary,
                  ),
                  child: const Text(
                    'Create Plan from Suggestion',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }
}
