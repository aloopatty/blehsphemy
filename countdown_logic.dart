Duration remainingUntil(DateTime target, DateTime now) {
  final delta = target.difference(now);
  return delta.isNegative ? Duration.zero : delta;
}
String countdownLabel(Duration d) {
  final days=d.inDays;
  final hours=d.inHours%24;
  final minutes=d.inMinutes%60;
  if(d.inHours<24) return '${hours.toString().padLeft(2,'0')}h : ${minutes.toString().padLeft(2,'0')}m : ${(d.inSeconds%60).toString().padLeft(2,'0')}s';
  return '${days}d : ${hours.toString().padLeft(2,'0')}h : ${minutes.toString().padLeft(2,'0')}m';
}
