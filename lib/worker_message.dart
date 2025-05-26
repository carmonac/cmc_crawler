class WorkerMessage {
  final String type;
  final dynamic data;

  WorkerMessage(this.type, this.data);

  Map<String, dynamic> toMap() => {'type': type, 'data': data};

  factory WorkerMessage.fromMap(Map<String, dynamic> json) =>
      WorkerMessage(json['type'], json['data']);
}
