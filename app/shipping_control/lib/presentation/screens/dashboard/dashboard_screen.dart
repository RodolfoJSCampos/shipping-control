import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shipping_control/widgets/order_form_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  final List<String> motoristas = const [
    'João Silva',
    'Maria Oliveira',
    'Carlos Souza',
    'Ana Pereira',
  ];

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  void _addNewOrder(BuildContext context) {
    showDialog(context: context, builder: (context) => const OrderFormDialog());
  }

  Future<void> _handleNotaTap(
    BuildContext context,
    String notaId,
    Map<String, dynamic> nota,
  ) async {
    final motoristaAtual = nota['motorista'] as String?;

    if (motoristaAtual == null || motoristaAtual.isEmpty) {
      String? selectedMotorista;
      final motoristaFocus = FocusNode();
      final botaoSalvarFocus = FocusNode();

      await showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setState) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                motoristaFocus.requestFocus();
              });

              return AlertDialog(
                title: const Text('Atualizar Motorista'),
                content: DropdownButtonFormField<String>(
                  isExpanded: true,
                  focusNode: motoristaFocus,
                  decoration: const InputDecoration(
                    labelText: 'Selecione o motorista',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedMotorista,
                  items: motoristas
                      .map(
                        (motorista) => DropdownMenuItem(
                          value: motorista,
                          child: Text(motorista),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMotorista = value;
                    });
                    if (value != null) {
                      FocusScope.of(context).requestFocus(botaoSalvarFocus);
                    }
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      motoristaFocus.dispose();
                      botaoSalvarFocus.dispose();
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Cancelar'),
                  ),
                  Focus(
                    focusNode: botaoSalvarFocus,
                    child: FilledButton(
                      onPressed: selectedMotorista == null
                          ? null
                          : () async {
                              await FirebaseFirestore.instance
                                  .collection('notas')
                                  .doc(notaId)
                                  .update({
                                'motorista': selectedMotorista,
                                'expedicao':
                                    DateTime.now().toIso8601String(),
                              });
                              motoristaFocus.dispose();
                              botaoSalvarFocus.dispose();
                              Navigator.of(ctx).pop();
                            },
                      child: const Text('Salvar'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      final botaoNaoFocus = FocusNode();
      final botaoSimFocus = FocusNode();

      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            botaoSimFocus.requestFocus();
          });

          return AlertDialog(
            title: const Text('Finalizar Nota'),
            content: const Text('Deseja finalizar esta nota?'),
            actions: [
              Focus(
                focusNode: botaoNaoFocus,
                child: TextButton(
                  onPressed: () {
                    botaoNaoFocus.dispose();
                    botaoSimFocus.dispose();
                    Navigator.of(ctx).pop(false);
                  },
                  child: const Text('Não'),
                ),
              ),
              Focus(
                focusNode: botaoSimFocus,
                child: FilledButton(
                  onPressed: () {
                    botaoNaoFocus.dispose();
                    botaoSimFocus.dispose();
                    Navigator.of(ctx).pop(true);
                  },
                  child: const Text('Sim'),
                ),
              ),
            ],
          );
        },
      );

      if (confirmar == true) {
        await FirebaseFirestore.instance.collection('notas').doc(notaId).update(
          {'finalizacao': DateTime.now().toIso8601String()},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: colors.primary),
              child: Text(
                'Menu',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colors.onPrimary,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notas')
              .where('finalizacao', isNull: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Erro ao carregar notas: ${snapshot.error}'),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final notasDocs = (snapshot.data?.docs ?? []).toList()
              ..sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;

                final motoristaA = dataA['motorista'];
                final motoristaB = dataB['motorista'];

                final aSemMotorista = motoristaA == null || motoristaA.toString().isEmpty;
                final bSemMotorista = motoristaB == null || motoristaB.toString().isEmpty;

                if (aSemMotorista && !bSemMotorista) return -1;
                if (!aSemMotorista && bSemMotorista) return 1;

                final entradaA = DateTime.tryParse(dataA['entrada'] ?? '');
                final entradaB = DateTime.tryParse(dataB['entrada'] ?? '');

                if (entradaA != null && entradaB != null) {
                  return entradaA.compareTo(entradaB);
                }
                return 0;
              });

            if (notasDocs.isEmpty) {
              return const Center(child: Text('Nenhuma nota encontrada.'));
            }

            return GridView.builder(
              itemCount: notasDocs.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final notaDoc = notasDocs[index];
                final nota = notaDoc.data()! as Map<String, dynamic>;

                final numeroNota = nota['numeroNota'] ?? 'N/A';
                final responsavel = nota['responsavel'] ?? 'N/A';

                final entradaStr = nota['entrada'] ?? '';
                final entrada =
                    entradaStr.isNotEmpty ? DateTime.tryParse(entradaStr) : null;
                final entradaFormatada = entrada != null
                    ? '${entrada.day}/${entrada.month}/${entrada.year} ${entrada.hour.toString().padLeft(2, '0')}:${entrada.minute.toString().padLeft(2, '0')}'
                    : 'Não informada';

                final motorista = nota['motorista'] ?? '';
                final expedicaoStr = nota['expedicao'] ?? '';
                final expedicao =
                    expedicaoStr.isNotEmpty ? DateTime.tryParse(expedicaoStr) : null;
                final expedicaoFormatada = expedicao != null
                    ? '${expedicao.day}/${expedicao.month}/${expedicao.year} ${expedicao.hour.toString().padLeft(2, '0')}:${expedicao.minute.toString().padLeft(2, '0')}'
                    : '';

                final bool semMotorista = motorista.isEmpty;

                final cardColor = semMotorista
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFFE3F2FD);
                final titleColor = semMotorista
                    ? const Color(0xFFE65100)
                    : colors.primary;
                final iconColor =
                    semMotorista ? const Color(0xFFE65100) : colors.primary;
                final footerTextColor =
                    semMotorista ? const Color(0xFFE65100) : colors.primary;

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _handleNotaTap(context, notaDoc.id, nota),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    color: cardColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '#$numeroNota',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: titleColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                semMotorista
                                    ? Icons.pending_actions
                                    : Icons.local_shipping,
                                color: iconColor,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.person,
                                size: 18,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  responsavel,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                entradaFormatada,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          if (!semMotorista) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.local_shipping,
                                  size: 18,
                                  color: colors.onSurface,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    motorista,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colors.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (expedicaoFormatada.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 18,
                                    color: colors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    expedicaoFormatada,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                          const Spacer(),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              semMotorista
                                  ? 'Selecionar motorista'
                                  : 'Finalizar nota',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: footerTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNewOrder(context),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Nota'),
      ),
    );
  }
}
