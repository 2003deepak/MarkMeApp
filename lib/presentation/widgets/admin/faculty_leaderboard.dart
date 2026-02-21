import 'package:flutter/material.dart';

class FacultyLeaderboardCard extends StatefulWidget {
  final List<FacultyPerformer> performers;
  final VoidCallback? onViewFullLeaderboard;
  final bool initiallyExpanded;

  const FacultyLeaderboardCard({
    super.key,
    required this.performers,
    this.onViewFullLeaderboard,
    this.initiallyExpanded = false,
  });

  @override
  State<FacultyLeaderboardCard> createState() => _FacultyLeaderboardCardState();
}

class _FacultyLeaderboardCardState extends State<FacultyLeaderboardCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildHeader(),
                if (_isExpanded) _buildExpandedContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.auto_graph_rounded,
            color: Color(0xFFF97316),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Faculty Leaderboard",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
              ),
              Text(
                "Top attendance consistency",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
              ),
            ],
          ),
        ),
        AnimatedRotation(
          turns: _isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 300),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        const SizedBox(height: 24),
        
        // Podium for Top 3
        if (widget.performers.length >= 3)
          _Podium(performers: widget.performers.take(3).toList())
        else
          _Podium(performers: widget.performers),
        
        const SizedBox(height: 32),
        
        // Remaining performers (4th place and beyond)
        if (widget.performers.length > 3)
          ...widget.performers.skip(3).map(
            (performer) => _PerformerItem(performer: performer),
          ),
        
        const SizedBox(height: 8),
        
        // View Full Leaderboard Button
        TextButton(
          onPressed: widget.onViewFullLeaderboard ?? () {},
          child: Text(
            "View Full Leaderboard",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

// Podium Component
class _Podium extends StatelessWidget {
  final List<FacultyPerformer> performers;

  const _Podium({required this.performers});

  @override
  Widget build(BuildContext context) {
    // Reorder for podium display (2nd place left, 1st place center, 3rd place right)
    final secondPlace = performers.length > 1 ? performers[1] : null;
    final firstPlace = performers.isNotEmpty ? performers[0] : null;
    final thirdPlace = performers.length > 2 ? performers[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Second Place
        if (secondPlace != null)
          Expanded(
            child: _PodiumItem(
              performer: secondPlace,
              position: 2,
              height: 120,
              color: const Color(0xFF94A3B8), // Silver
            ),
          ),
        
        const SizedBox(width: 12),
        
        // First Place
        if (firstPlace != null)
          Expanded(
            child: _PodiumItem(
              performer: firstPlace,
              position: 1,
              height: 160,
              color: const Color(0xFFFFD700), // Gold
            ),
          ),
        
        const SizedBox(width: 12),
        
        // Third Place
        if (thirdPlace != null)
          Expanded(
            child: _PodiumItem(
              performer: thirdPlace,
              position: 3,
              height: 90,
              color: const Color(0xFFCD7F32), // Bronze
            ),
          ),
      ],
    );
  }
}

// Podium Item Component
class _PodiumItem extends StatelessWidget {
  final FacultyPerformer performer;
  final int position;
  final double height;
  final Color color;

  const _PodiumItem({
    required this.performer,
    required this.position,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = performer.trend.startsWith('+');
    
    return Column(
      children: [
        // Avatar with initials
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.7),
                color,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _getInitials(performer.name),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Last name only
        Text(
          performer.name.split(' ').last,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1E293B),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        // Abbreviated department
        Text(
          _abbreviateDept(performer.department),
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 4),
        
        // Score badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            performer.score,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Trend indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              size: 12,
              color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
            const SizedBox(width: 2),
            Text(
              performer.trend,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Podium stand
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              '#$position',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return nameParts[0][0] + nameParts[1][0];
    }
    return nameParts[0][0];
  }

  String _abbreviateDept(String dept) {
    if (dept.contains(' ')) {
      return dept.split(' ').map((word) => word[0]).join('');
    }
    return dept.substring(0, 3).toUpperCase();
  }
}

// Performer Item for 4th place and beyond
class _PerformerItem extends StatelessWidget {
  final FacultyPerformer performer;

  const _PerformerItem({required this.performer});

  @override
  Widget build(BuildContext context) {
    final isPositive = performer.trend.startsWith('+');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                performer.rank,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                    ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Name and Department
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performer.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                ),
                Text(
                  performer.department,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF94A3B8),
                      ),
                ),
              ],
            ),
          ),
          
          // Score and Trend
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                performer.score,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    performer.trend,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Data Model
class FacultyPerformer {
  final String name;
  final String department;
  final String score;
  final String trend;
  final String rank;

  const FacultyPerformer({
    required this.name,
    required this.department,
    required this.score,
    required this.trend,
    required this.rank,
  });
}