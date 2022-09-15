import 'dart:convert';

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
}
