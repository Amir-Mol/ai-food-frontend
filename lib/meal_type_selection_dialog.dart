import 'package:flutter/material.dart';

/// A dialog widget that allows the user to select a meal type.
///
/// The dialog presents a dropdown list of meal types and provides options
/// to either confirm the selection or skip it.
class MealTypeSelectionDialog extends StatefulWidget {
  const MealTypeSelectionDialog({super.key});

  @override
  State<MealTypeSelectionDialog> createState() =>
      _MealTypeSelectionDialogState();
}

class _MealTypeSelectionDialogState extends State<MealTypeSelectionDialog> {
  // List of meal type options available for selection.
  final List<String> _mealTypeOptions = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Any'
  ];

  // Holds the currently selected meal type. Initially null.
  String? _selectedMealType;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text(
        "What type of meal are you looking for?",
        style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min, // Important for dialog content sizing
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 16.0),
          DropdownButtonFormField<String>(
            hint: const Text('Select a meal type'),
            value: _selectedMealType,
            items: _mealTypeOptions.map((String mealType) {
              return DropdownMenuItem<String>(
                value: mealType,
                child: Text(mealType),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedMealType = newValue;
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
              ),
            ),
            dropdownColor: colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 16.0), // Space after dropdown
          Align( // Align the "Skip" button to the right
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Return null when skipping
              },
              child: const Text('Skip'),
            ),
          ),
          const SizedBox(height: 24.0), // Space between "Skip" and "Show Recommendations"
          FilledButton( // "Show Recommendations" button, will stretch due to Column's CrossAxisAlignment
            onPressed: _selectedMealType == null
                ? null // Disable button if no meal type is selected
                : () {
                    Navigator.of(context)
                        .pop(_selectedMealType); // Return the selected meal type
                  },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              // Minimum padding to ensure the button is not too small if text is short
              padding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
            child: const Text('Show Recommendations'),
          ),
          // Add a little bottom padding if desired, or rely on AlertDialog's default content padding
          // const SizedBox(height: 8.0),
        ],
      ),
      // Setting actions to null or an empty list as they are now handled in content
      actions: const [], // Or simply remove the 'actions:' line
      actionsPadding: EdgeInsets.zero, // Remove default actions padding if actions is empty
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0), // Default, adjust if needed
    );
  }
}