class RoomAliasService {
  static const Map<String, List<String>> aliases = {
    // 5층
    "502": ["전효진", "전효진(Lab)"],
    "503": ["송진국", "송진국(Lab)"],
    "504": ["김흥준", "김건우", "김흥준(Lab)", "김건우(Lab)"],
    "505": ["학생회실"], // 매핑 요청에 "학생회실"만 있음 (505 추정)
    "506": ["김흥준 교수님"],
    "507": ["강창구 교수님"],
    "508": ["진효진 교수님"],
    "509": ["송진국 교수님"],
    "510": ["김건우 교수님"],
    "511": ["김건우(Lab)"],
    "512": ["강찬구(Lab)"],

    // 6층
    "601": ["김지윤(Lab)"],
    "602": ["남영호(Lab)"],
    "603": ["서영건(Lab)"],
    "604": ["부석준(Lab)"],
    "606": ["학과사무실"],
    "607": ["남영호 교수님"],
    "608": ["서영건 교수님"],
    "609": ["김현주 교수님"],
    "610": ["김지윤 교수님"],
    "611": ["부석준 교수님"],
    "612": ["김범수 교수님"],
    "613": ["김범수(Lab)"],
    "614": ["김현주(Lab)"],

    // 7층
    "701": ["서현(Lab)"],
    "702": ["이수원(Lab)"],
    "703": ["김봉기", "김건우", "김봉기(Lab)", "김건우(Lab)"],
    "704": ["김민기(Lab)"],
    "705": ["최상민(Lab)"],
    "706": ["대학원 세미나실"],
    "707": ["최상민 교수님"],
    "708": ["서현 교수님"],
    "709": ["이수원 교수님"],
    "710": ["김봉기 교수님"],
    "711": ["김창근 교수님"],
    "712": ["윤응창 교수님"],
    "713": ["김민기 교수님"],
    "714": ["윤응창(Lab)"],
    "715": ["김창근(Lab)"],
  };

  static List<String> getAliases(String roomName) {
    return aliases[roomName] ?? [];
  }

  static bool matches(String roomName, String query) {
    // 1. 호수 직접 매칭 (예: "502")
    if (roomName.toLowerCase().contains(query.toLowerCase())) return true;

    // 2. 검색어가 비어있으면 매칭 안함
    if (query.trim().isEmpty) return false;

    // 3. 별칭(교수님 이름 등) 매칭
    final roomAliases = getAliases(roomName);
    for (final alias in roomAliases) {
      // 띄어쓰기 무시하고 비교 (편의성)
      final cleanAlias = alias.replaceAll(' ', '').toLowerCase();
      final cleanQuery = query.replaceAll(' ', '').toLowerCase();

      if (cleanAlias.contains(cleanQuery)) {
        return true;
      }
    }
    return false;
  }
}
