import 'package:flutter_test/flutter_test.dart';
import 'package:thc_lms_mobile/models/student_category_model.dart';

void main() {
  test('student categories parse nested API payload', () {
    final categories = parseStudentCategories({
      'status': true,
      'data': [
        {'id': 1, 'name': 'Staff'},
        {'id': '2', 'category_name': 'Nurse'},
        {'category_id': '3', 'title': 'Doctor'},
      ],
    });

    expect(categories.map((item) => item.id), ['1', '2', '3']);
    expect(categories.map((item) => item.displayName), [
      'Staff',
      'Nurse',
      'Doctor',
    ]);
  });

  test('student categories parse wrapped list and skip empty rows', () {
    final categories = parseStudentCategories({
      'data': {
        'categories': [
          {'value': 'staff', 'label': 'Staff'},
          {'id': '', 'name': ''},
        ],
      },
    });

    expect(categories, hasLength(1));
    expect(categories.single.id, 'staff');
    expect(categories.single.displayName, 'Staff');
  });
}
