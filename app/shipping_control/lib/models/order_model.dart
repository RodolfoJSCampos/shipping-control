class OrderModel {
  final String id;
  final DateTime dataEntrada;
  final String responsavel;
  final DateTime? dataExpedicao;
  final String motorista;
  final DateTime? dataFinalizacao;

  OrderModel({
    required this.id,
    required this.dataEntrada,
    required this.responsavel,
    this.dataExpedicao,
    required this.motorista,
    this.dataFinalizacao,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'dataEntrada': dataEntrada.toIso8601String(),
        'responsavel': responsavel,
        'dataExpedicao': dataExpedicao?.toIso8601String(),
        'motorista': motorista,
        'dataFinalizacao': dataFinalizacao?.toIso8601String(),
      };

  factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
        id: map['id'],
        dataEntrada: DateTime.parse(map['dataEntrada']),
        responsavel: map['responsavel'],
        dataExpedicao: map['dataExpedicao'] != null
            ? DateTime.parse(map['dataExpedicao'])
            : null,
        motorista: map['motorista'],
        dataFinalizacao: map['dataFinalizacao'] != null
            ? DateTime.parse(map['dataFinalizacao'])
            : null,
      );
}
