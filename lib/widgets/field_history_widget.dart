import 'package:flutter/material.dart';

class FieldHistoryWidget extends StatelessWidget {
  final String fieldName;
  final List<dynamic>? histories;

  const FieldHistoryWidget({
    super.key,
    required this.fieldName,
    this.histories,
  });

  @override
  Widget build(BuildContext context) {
    if (histories == null || histories!.isEmpty) {
      return const SizedBox.shrink();
    }

    final fieldHistory = histories!.firstWhere(
      (element) => element['field_name'] == fieldName,
      orElse: () => null,
    );

    if (fieldHistory == null) {
      return const SizedBox.shrink();
    }

    final String oldValue = fieldHistory['old_value'] ?? 'فارغ';
    final String newValue = fieldHistory['new_value'] ?? 'فارغ';
    final String date = fieldHistory['date'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
      child: Text(
        'تم تعديله من "$oldValue" إلى "$newValue" بتاريخ $date',
        style: const TextStyle(
          fontSize: 11,
          color: Colors.amber,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
