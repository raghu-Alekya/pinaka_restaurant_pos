class Guestcount {
  final int guestCount;

  Guestcount({required this.guestCount});

  Map<String, dynamic> toJson() {
    return {
      "guest_count": guestCount,
    };
  }

  factory Guestcount.fromJson(Map<String, dynamic> json) {
    return Guestcount(
      guestCount: json["guest_count"] ?? 0,
    );
  }
}
