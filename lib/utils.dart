String _two(int n) => n.toString().padLeft(2, '0');

String fmtDateTime(DateTime d) =>
    '${_two(d.day)}/${_two(d.month)}/${d.year} ${_two(d.hour)}:${_two(d.minute)}';

String fmtWeight(double? w) {
  if (w == null) return '-';
  var s = w.toStringAsFixed(2);
  s = s.replaceFirst(RegExp(r'0+$'), '');
  s = s.replaceFirst(RegExp(r'\.$'), '');
  return '${s.replaceAll('.', ',')} kg';
}
