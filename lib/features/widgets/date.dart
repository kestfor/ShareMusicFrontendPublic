class Date {
  int? month;
  int year;
  int? day;

  Date({required this.year, this.day, this.month});

  List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  factory Date.fromString(String date) {
    List<String> values = date.split('-');
    if (values.length == 3) {
      return Date(year: int.parse(values[0]), month: int.parse(values[1]), day: int.parse(values[2]));
    } else if (values.length == 2) {
      return Date(year: int.parse(values[0]), month: int.parse(values[1]));
    } else if (values.length == 1) {
      return Date(year: int.parse(values[0]));
    } else {
      throw ArgumentError;
    }
  }

  @override
  String toString() {
    String res = '';
    res += month == null ? '' : months[month! - 1];
    res += day == null ? ', ' : ' $day, ';
    res += year.toString();
    return res;
  }
}
