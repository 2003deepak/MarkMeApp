import 'package:flutter/material.dart';
import 'package:markmeapp/data/models/teacher_leaderboard_model.dart';
import 'package:markmeapp/presentation/skeleton/widgets/faculty_leaderboard_skeleton.dart';

class FacultyLeaderboardCard extends StatefulWidget {
  final List<LeaderboardEntry> performers;
  final VoidCallback? onViewFullLeaderboard;
  final bool initiallyExpanded;
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final bool isLoading;

  const FacultyLeaderboardCard({
    super.key,
    required this.performers,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.onViewFullLeaderboard,
    this.initiallyExpanded = false,
    this.isLoading = false,
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
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Leaderboard",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                      fontSize: 18,
                    ),
              ),
              Text(
                "Top performances",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
              ),
            ],
          ),
        ),
        _buildPeriodToggle(),
        const SizedBox(width: 12),
        AnimatedRotation(
          turns: _isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 300),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PeriodButton(
            label: "Week",
            isSelected: widget.selectedPeriod == 'weekly',
            onTap: () => widget.onPeriodChanged('weekly'),
          ),
          _PeriodButton(
            label: "Month",
            isSelected: widget.selectedPeriod == 'monthly',
            onTap: () => widget.onPeriodChanged('monthly'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        
        if (widget.isLoading)
          const FacultyLeaderboardSkeleton()
        else if (widget.performers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                const Icon(Icons.leaderboard_rounded, size: 24, color: Color(0xFFCBD5E1)),
                const SizedBox(height: 8),
                Text(
                  "No data available",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              const SizedBox(height: 20),
              // Podium for Top 3
              if (widget.performers.length >= 3)
                _Podium(performers: widget.performers.take(3).toList())
              else
                _Podium(performers: widget.performers),
              
              const SizedBox(height: 24),
              
              // Remaining performers (4th place and beyond)
              if (widget.performers.length > 3)
                ...widget.performers.skip(3).map(
                  (performer) => _PerformerItem(performer: performer),
                ),
            ],
          ),
      ],
    );
  }


}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

// Podium Component
class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> performers;

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
              height: 80,
              color: const Color(0xFF94A3B8), // Silver
            ),
          ),
        
        const SizedBox(width: 8),
        
        // First Place
        if (firstPlace != null)
          Expanded(
            child: _PodiumItem(
              performer: firstPlace,
              position: 1,
              height: 110,
              color: const Color(0xFFFFD700), // Gold
            ),
          ),
        
        const SizedBox(width: 8),
        
        // Third Place
        if (thirdPlace != null)
          Expanded(
            child: _PodiumItem(
              performer: thirdPlace,
              position: 3,
              height: 60,
              color: const Color(0xFFCD7F32), // Bronze
            ),
          ),
      ],
    );
  }
}

// Podium Item Component
class _PodiumItem extends StatelessWidget {
  final LeaderboardEntry performer;
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
    return Column(
      children: [
        // Avatar with initials or profile picture
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.7),
                color,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            image: performer.profilePicture != null
                ? DecorationImage(
                    image: NetworkImage(performer.profilePicture!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: performer.profilePicture == null
              ? Center(
                  child: Text(
                    _getInitials(performer.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                )
              : null,
        ),
        
        const SizedBox(height: 6),
        
        // Last name or short name
        Text(
          performer.name.split(' ').last,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Color(0xFF1E293B),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 2),
        
        // Score badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "${performer.score.toStringAsFixed(1)}%",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: color,
            ),
          ),
        ),
        
        const SizedBox(height: 6),
        
        // Podium stand
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(10),
            ),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              '#$position',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return "?";
    if (nameParts.length >= 2) {
      return (nameParts[0][0] + nameParts[nameParts.length - 1][0]).toUpperCase();
    }
    return nameParts[0][0].toUpperCase();
  }

  String _abbreviateDept(String dept) {
    if (dept.length <= 5) return dept.toUpperCase();
    if (dept.contains(' ')) {
      return dept.split(' ').map((word) => word.isNotEmpty ? word[0] : '').join('').toUpperCase();
    }
    return dept.substring(0, 3).toUpperCase();
  }
}

// Performer Item for 4th place and beyond
class _PerformerItem extends StatelessWidget {
  final LeaderboardEntry performer;

  const _PerformerItem({required this.performer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Rank
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                performer.rank.toString(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                    ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          
          // Avatar
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              image: performer.profilePicture != null
                  ? DecorationImage(
                      image: NetworkImage(performer.profilePicture!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: performer.profilePicture == null
                ? Center(
                    child: Text(
                      _getInitials(performer.name),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          
          // Name and Department
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performer.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                ),
                Text(
                  performer.department,
                  style: TextStyle(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${performer.score.toStringAsFixed(1)}%",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
              ),
              if (performer.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _getBadgeColor(performer.badge!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    performer.badge!,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: _getBadgeColor(performer.badge!),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getBadgeColor(String badge) {
    switch (badge.toLowerCase()) {
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFF94A3B8);
      case 'bronze':
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return "?";
    if (nameParts.length >= 2) {
      return (nameParts[0][0] + nameParts[nameParts.length - 1][0]).toUpperCase();
    }
    return nameParts[0][0].toUpperCase();
  }
}
