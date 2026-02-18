import 'package:flutter/material.dart';
import '../../core/extensions/translation_extension.dart';

class RideCard extends StatelessWidget {
  final String from;
  final String to;
  final String driver;
  final double rating;
  final int seats;
  final VoidCallback onTap;
  final VoidCallback? onSchedule; // NEW: Optional schedule callback

  const RideCard({
    super.key,
    required this.from,
    required this.to,
    required this.driver,
    required this.rating,
    required this.seats,
    required this.onTap,
    this.onSchedule, // NEW
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$from → $to",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Driver: $driver"),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  Text(rating.toString()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text("$seats seats left",
              style: const TextStyle(color: Colors.grey)),
          
          // NEW: Action buttons
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSchedule,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text("Schedule"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.directions_car, size: 16),
                  label: const Text("Book Now"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}