import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class OrderFormDialog extends StatefulWidget {
  const OrderFormDialog({super.key});

  @override
  State<OrderFormDialog> createState() => _OrderFormDialogState();
}

class _OrderFormDialogState extends State<OrderFormDialog> {
  final _numeroNotaController = TextEditingController();
  final _uuid = const Uuid();

  final List<String> _responsaveis = [
    'José Lima',
    'Carla Mendes',
    'Fernanda Costa',
    'Roberto Dias',
  ];

  String? _responsavelSelecionado;

  late FocusNode _numeroNotaFocus;
  late FocusNode _responsavelFocus;
  late FocusNode _botaoSalvarFocus;

  @override
  void initState() {
    super.initState();
    _numeroNotaFocus = FocusNode();
    _responsavelFocus = FocusNode();
    _botaoSalvarFocus = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _numeroNotaFocus.requestFocus();
    });
  }

  Future<void> _saveOrder() async {
    final orderId = _uuid.v4();
    final agora = DateTime.now();

    try {
      await FirebaseFirestore.instance.collection('notas').doc(orderId).set({
        'id': orderId,
        'numeroNota': _numeroNotaController.text.trim(),
        'responsavel': _responsavelSelecionado ?? '',
        'entrada': agora.toIso8601String(),
        'criadoEm': agora.toIso8601String(),
        'expedicao': null,
        'motorista': null,
        'finalizacao': null,
      });

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    }
  }

  @override
  void dispose() {
    _numeroNotaController.dispose();
    _numeroNotaFocus.dispose();
    _responsavelFocus.dispose();
    _botaoSalvarFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova Nota'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _numeroNotaController,
              focusNode: _numeroNotaFocus,
              decoration: const InputDecoration(labelText: 'Número da Nota'),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onEditingComplete: () {
                FocusScope.of(context).requestFocus(_responsavelFocus);
              },
            ),
            const SizedBox(height: 12),
            Focus(
              focusNode: _responsavelFocus,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Responsável'),
                value: _responsavelSelecionado,
                items: _responsaveis.map((responsavel) {
                  return DropdownMenuItem<String>(
                    value: responsavel,
                    child: Text(responsavel),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _responsavelSelecionado = value;
                  });
                  if (value != null) {
                    FocusScope.of(context).requestFocus(_botaoSalvarFocus);
                  }
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        Focus(
          focusNode: _botaoSalvarFocus,
          child: ElevatedButton(
            onPressed: _responsavelSelecionado == null || _numeroNotaController.text.trim().isEmpty
                ? null
                : _saveOrder,
            child: const Text('Salvar'),
          ),
        ),
      ],
    );
  }
}
