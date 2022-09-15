import 'dart:convert';
import 'package:intl/intl.dart';

class ProffixHelpers {
/*   GetFiltererCount(header http.Header) (total int) {
	type PxMetadata struct {
		FilteredCount int
	}
	var pxmetadata PxMetadata
	head := header.Get("pxmetadata")
	_ = json.Unmarshal([]byte(head), &pxmetadata)

	return pxmetadata.FilteredCount
} */

  int getFiltererCount(Map<String, String> header) {
    String? pxmetadata = header["pxmetadata"];
    if (pxmetadata != "") {
      return jsonDecode(pxmetadata!)["FilteredCount"];
    } else {
      return 0;
    }
  }

  int convertLocationId(Map<String, String> header) {
    String? location = header["location"];
    if (location != "" && location != null) {
      String lastPath = Uri.parse(location).pathSegments.last;
      return int.parse(lastPath);
    } else {
      return 0;
    }
  }

  DateTime convertPxTimeToTime(String pxtime) {
    DateFormat pxformat = DateFormat("yyyy-dd-MM HH:mm:ss");
    return pxformat.parse(pxtime);
  }

  String convertTimeToPxTime(DateTime date) {
    final DateFormat pxformat = DateFormat("yyyy-dd-MM HH:mm:ss");
    return pxformat.format(date);
  }
}
