import 'package:flutter_test/flutter_test.dart';
import 'package:what_to_cook/presentation/providers/meal_plan_provider.dart';

void main() {
  test('curatedDishById resolves dishes from every catalog', () {
    expect(curatedDishById('hb-poha')?.name, 'Poha');
    expect(curatedDishById('hg-poi')?.name, 'Sanna & Poee');
    expect(curatedDishById('c-pa-b1')?.name, 'Akuri');
    expect(curatedDishById('c-gu-b1')?.name, 'Thepla');
  });
}
