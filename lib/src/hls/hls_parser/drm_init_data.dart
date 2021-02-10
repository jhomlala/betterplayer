import 'package:flutter/cupertino.dart';

import 'scheme_data.dart';
import 'package:collection/collection.dart';

class DrmInitData {
  DrmInitData({this.schemeType, this.schemeData = const []});

  final List<SchemeData> schemeData;
  final String schemeType;

  @override
  bool operator ==(dynamic other) {
    if (other is DrmInitData)
      return schemeType == other.schemeType &&
          const ListEquality<SchemeData>().equals(other.schemeData, schemeData);
    return false;
  }

  @override
  int get hashCode => hashValues(schemeType, schemeData);
}
