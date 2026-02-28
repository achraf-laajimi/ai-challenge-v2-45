import 'package:flutter/foundation.dart';
import '../models/person.dart';
import '../models/family.dart';
import '../core/mock_data.dart';

/// Selected family member index in family.allMembers (0 = father, 1 = mother, then children).
class SelectedMemberProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  Family _family = demoFamily;

  Family get family => _family;
  int get selectedIndex => _selectedIndex;
  Person? get selectedPerson {
    final members = _family.allMembers;
    if (members.isEmpty) return null;
    final i = _selectedIndex.clamp(0, members.length - 1);
    return members[i];
  }

  void selectMember(int index) {
    if (index >= 0 && index < _family.allMembers.length) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void setFamily(Family f) {
    _family = f;
    final len = f.allMembers.length;
    _selectedIndex = len > 0 ? 0 : 0;
    if (len > 0 && _selectedIndex >= len) _selectedIndex = len - 1;
    notifyListeners();
  }
}
