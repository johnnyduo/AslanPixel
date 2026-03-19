import 'package:flutter/material.dart';
import 'package:aslan_pixel/features/finance/data/models/ai_insight_model.dart';

// ---------------------------------------------------------------------------
// Color constants
// ---------------------------------------------------------------------------

const Color _surface = Color(0xFF0F2040);
const Color _neonGreen = Color(0xFF00F5A0);
const Color _textWhite = Color(0xFFE8F4F8);
const Color _gold = Color(0xFFFFD700);
const Color _grey = Color(0xFF7A9BB5);

// ---------------------------------------------------------------------------
// MarketInsightCard
// ---------------------------------------------------------------------------

/// Displays an AI-generated market insight.
///
/// States:
///   • [isLoading] = true  → shimmer placeholder rows
///   • [insight] != null   → full content view
///   • [insight] == null   → tap-to-load placeholder
class MarketInsightCard extends StatelessWidget {
  const MarketInsightCard({
    super.key,
    this.insight,
    this.isLoading = false,
    this.onRefresh,
  });

  final AiInsightModel? insight;
  final bool isLoading;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoading
          ? const _ShimmerContent()
          : insight != null
              ? _LoadedContent(insight: insight!, onRefresh: onRefresh)
              : _EmptyContent(onTap: onRefresh),
    );
  }
}

// ---------------------------------------------------------------------------
// _ShimmerContent — animated pulsing placeholder rows
// ---------------------------------------------------------------------------

class _ShimmerContent extends StatefulWidget {
  const _ShimmerContent();

  @override
  State<_ShimmerContent> createState() => _ShimmerContentState();
}

class _ShimmerContentState extends State<_ShimmerContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final alpha = 0.12 + _pulse.value * 0.18;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row — label + loading indicator
            Row(
              children: [
                Container(
                  width: 130,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _neonGreen.withValues(alpha: alpha * 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    color: _neonGreen,
                    strokeWidth: 1.5,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'กำลังวิเคราะห์...',
                  style: TextStyle(
                    color: _neonGreen.withValues(alpha: alpha * 1.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Line 1 — full width
            _ShimmerBox(
              width: double.infinity,
              height: 12,
              alpha: alpha,
            ),
            const SizedBox(height: 8),
            // Line 2 — 80%
            _ShimmerBox(
              width: MediaQuery.of(context).size.width * 0.75,
              height: 12,
              alpha: alpha * 0.85,
            ),
            const SizedBox(height: 8),
            // Line 3 — 55%
            _ShimmerBox(
              width: MediaQuery.of(context).size.width * 0.55,
              height: 12,
              alpha: alpha * 0.65,
            ),
          ],
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.alpha,
  });

  final double width;
  final double height;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _grey.withValues(alpha: alpha.clamp(0.0, 1.0)),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// _LoadedContent
// ---------------------------------------------------------------------------

class _LoadedContent extends StatelessWidget {
  const _LoadedContent({required this.insight, this.onRefresh});

  final AiInsightModel insight;
  final VoidCallback? onRefresh;

  String _minutesAgo() {
    final diff = DateTime.now().difference(insight.generatedAt);
    final minutes = diff.inMinutes;
    if (minutes < 1) return 'เมื่อกี้';
    return '$minutes นาทีที่แล้ว';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            const Text(
              '🤖 AI Insight',
              style: TextStyle(
                color: _neonGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            // Model chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                insight.modelUsed,
                style: const TextStyle(color: _grey, fontSize: 9),
              ),
            ),
            const SizedBox(width: 4),
            // Refresh button
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.refresh, color: _grey, size: 16),
                onPressed: onRefresh,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Content
        Text(
          insight.contentTh,
          style: const TextStyle(
            color: _textWhite,
            fontSize: 13,
            height: 1.5,
          ),
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        // Footer
        Row(
          children: [
            Text(
              'อัปเดต ${_minutesAgo()}',
              style: const TextStyle(color: _grey, fontSize: 11),
            ),
            const Spacer(),
            const Text(
              'ข้อมูลเพื่อการศึกษา',
              style: TextStyle(color: _gold, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _EmptyContent
// ---------------------------------------------------------------------------

class _EmptyContent extends StatelessWidget {
  const _EmptyContent({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _neonGreen, width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights_outlined, color: _neonGreen, size: 18),
            SizedBox(width: 8),
            Text(
              'แตะเพื่อโหลด Insight',
              style: TextStyle(
                color: _neonGreen,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
