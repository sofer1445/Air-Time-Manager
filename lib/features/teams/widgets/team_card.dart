import 'package:flutter/material.dart';

class TeamCardModel {
  final String name;
  final String timerText;
  final String? membersText;
  final String primaryActionText;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onUndo;
  final VoidCallback? onAddMember;
  final String? statusText; // "בזירה", "במוקד", "בשטיפה" וכו'
  final Color? statusColor;
  final String? icon;
  final bool canUndo;

  const TeamCardModel({
    required this.name,
    required this.timerText,
    this.membersText,
    required this.primaryActionText,
    required this.onPrimaryAction,
    required this.onUndo,
    this.onAddMember,
    this.statusText,
    this.statusColor,
    this.icon,
    this.canUndo = true,
  });
}

class TeamCard extends StatelessWidget {
  final TeamCardModel model;

  const TeamCard({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Tablet: מעל 600px
            // Phone: מתחת 600px
            final isTablet = constraints.maxWidth >= 600;
            final isNarrow = constraints.maxWidth < 400;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header - שם הצוות + סטטוס
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model.name,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isTablet ? 28 : 24,
                                ),
                          ),
                          if (model.statusText != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (model.icon != null)
                                  Text(
                                    model.icon!,
                                    style: TextStyle(fontSize: isTablet ? 20 : 16),
                                  ),
                                if (model.icon != null) const SizedBox(width: 6),
                                Text(
                                  model.statusText!,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: model.statusColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: isTablet ? 18 : 16,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (model.onAddMember != null)
                      IconButton.filled(
                        icon: Icon(Icons.person_add, size: isTablet ? 28 : 24),
                        onPressed: model.onAddMember,
                        tooltip: 'הוסף לוחם',
                        padding: EdgeInsets.all(isTablet ? 16 : 12),
                      ),
                  ],
                ),
                if (model.membersText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    model.membersText!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: isTablet ? 16 : 14,
                        ),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // טיימר - גדול ובולט
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 24 : 16,
                    horizontal: isTablet ? 32 : 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      model.timerText,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: isTablet
                            ? 72 // Tablet - ענק!
                            : (isNarrow ? 48 : 56), // Phone
                        fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ],
                        letterSpacing: isTablet ? 4 : 2,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: isTablet ? 24 : 16),
                
                // כפתורים - גדולים במיוחד לטאבלט
                isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPrimaryButton(context, isTablet),
                          const SizedBox(height: 12),
                          _buildUndoButton(context, isTablet),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildPrimaryButton(context, isTablet),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildUndoButton(context, isTablet),
                          ),
                        ],
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context, bool isTablet) {
    return ElevatedButton(
      onPressed: model.onPrimaryAction,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 24 : 16,
          horizontal: isTablet ? 32 : 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        model.primaryActionText,
        style: TextStyle(
          fontSize: isTablet ? 22 : 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUndoButton(BuildContext context, bool isTablet) {
    return OutlinedButton.icon(
      onPressed: model.canUndo ? model.onUndo : null,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 24 : 16,
          horizontal: isTablet ? 24 : 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: Icon(
        Icons.undo,
        size: isTablet ? 24 : 20,
      ),
      label: Text(
        'ביטול',
        style: TextStyle(
          fontSize: isTablet ? 20 : 16,
        ),
      ),
    );
  }
}

