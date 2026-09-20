import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/time_format.dart';
import '../../models/cube_solve.dart';
import '../../data/cube_solves_repository.dart';
import '../../widgets/solves_history_modal.dart';

class CubeTimerScreen extends StatefulWidget {
  const CubeTimerScreen({super.key});

  @override
  State<CubeTimerScreen> createState() => _CubeTimerScreenState();
}

// `awaitingInspection` = dedo pressionado, esperando soltar para a
// contagem de 15s começar (ver `_onPointerDown`/`_onPointerUp`).
enum TimerState { idle, awaitingInspection, inspecting, holding, running, finished }

class _CubeTimerScreenState extends State<CubeTimerScreen> {
  final CubeSolvesRepository _repository = CubeSolvesRepository();
  List<CubeSolve> _solves = [];
  bool _isLoading = true;

  // Imagem de fundo guardada como bytes (base64), não como caminho de
  // arquivo: no navegador não existe sistema de arquivos, então um
  // "path" nunca funcionaria ali. Guardando os bytes em si, a imagem
  // funciona igual no navegador, no celular e no desktop.
  String? _bgImageBase64;

  // Provider da imagem criado UMA vez (não a cada build). Antes o
  // `base64Decode` + `Image.memory` rodavam dentro do `build`, que é
  // chamado a cada 200ms na inspeção e a cada 16ms com o timer
  // rodando: cada chamada gerava um provider novo, a imagem recarregava
  // (piscava) e, com o timer a 60fps, nunca chegava a ser desenhada
  // (sumia). Guardando o provider aqui, o Flutter reaproveita a imagem
  // já decodificada.
  ImageProvider? _bgImage;

  TimerState _timerState = TimerState.idle;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;

  // --- Inspeção (regra oficial da WCA) ---
  final Stopwatch _inspectionStopwatch = Stopwatch();
  Timer? _inspectionTimer;
  bool _inspectionEnabled = false;
  // Penalidade calculada a partir do tempo de inspeção gasto, aplicada
  // à próxima solução salva em `_stopTimer`. Fica 0 quando a inspeção
  // está desativada ou quando o competidor começou a resolver dentro
  // dos 15s normais.
  int _pendingInspectionPenalty = 0;

  static const int _inspectionNormalLimitMs = 15000; // até aqui: sem penalidade
  static const int _inspectionDnfLimitMs = 17000; // depois daqui: DNF

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _inspectionTimer?.cancel();
    super.dispose();
  }

  /// Decodifica o base64 uma única vez e já deixa a imagem pronta no
  /// cache (`precacheImage`), para ela aparecer de primeira, sem piscar.
  Future<ImageProvider?> _prepareBackground(String? base64Image) async {
    if (base64Image == null || base64Image.isEmpty) return null;
    try {
      final provider = MemoryImage(base64Decode(base64Image));
      if (!mounted) return null;
      await precacheImage(provider, context);
      return provider;
    } catch (_) {
      // Base64 corrompido ou imagem inválida: segue sem wallpaper.
      return null;
    }
  }

  Future<void> _loadData() async {
    final loadedSolves = await _repository.loadSolves();
    final bgImage = await _repository.getBackgroundImageBase64();
    final inspectionEnabled = await _repository.getInspectionEnabled();
    final bgProvider = await _prepareBackground(bgImage);
    if (!mounted) return;
    setState(() {
      _solves = loadedSolves;
      _bgImageBase64 = bgImage;
      _bgImage = bgProvider;
      _inspectionEnabled = inspectionEnabled;
      _isLoading = false;
    });
  }

  Future<void> _pickBackgroundImage() async {
    final file = await FilePicker.pickFile();
    if (file == null) return;

    // Desde o file_picker 12, `PlatformFile.bytes` foi removido: os bytes
    // são lidos sob demanda com `readAsBytes()`, que funciona em todas
    // as plataformas (inclusive no navegador, onde não há `path`).
    final bytes = await file.readAsBytes();

    final base64Image = base64Encode(bytes);
    await _repository.saveBackgroundImageBase64(base64Image);
    final provider = await _prepareBackground(base64Image);

    if (!mounted) return;
    setState(() {
      _bgImageBase64 = base64Image;
      _bgImage = provider;
    });
  }

  Future<void> _removeBackgroundImage() async {
    await _repository.saveBackgroundImageBase64('');
    if (!mounted) return;
    setState(() {
      _bgImageBase64 = null;
      _bgImage = null;
    });
  }

  Future<void> _saveSolve(int timeMs, {int penalty = 0}) async {
    final newSolve = CubeSolve(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      time: timeMs,
      date: DateTime.now(),
      penalty: penalty,
    );
    // Atualiza a lista na tela imediatamente (antes de gravar no disco):
    // assim o relógio já mostra o tempo recém-feito, sem um instante em
    // que apareceria a solução anterior.
    setState(() => _solves = [..._solves, newSolve]);
    await _repository.addSolve(newSolve);
  }

  Future<void> _updatePenalty(String id, int newPenalty) async {
    await _repository.updatePenalty(id, newPenalty);
    final loaded = await _repository.loadSolves();
    if (!mounted) return;
    setState(() => _solves = loaded);
  }

  Future<void> _deleteSolve(String id) async {
    await _repository.deleteSolve(id);
    final loaded = await _repository.loadSolves();
    if (!mounted) return;
    setState(() {
      _solves = loaded;
      _resetClockAfterDelete();
    });
  }

  /// Ao apagar uma solução, o relógio volta a 00:00.000 (em vez de
  /// mostrar o tempo de outra solução). Só mexe no estado se o relógio
  /// estava exibindo um resultado (`finished`); durante inspeção ou
  /// cronômetro rodando, não interfere.
  void _resetClockAfterDelete() {
    if (_timerState == TimerState.finished) {
      _timerState = TimerState.idle;
    }
  }

  void _confirmDeleteSolve(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Apagar tempo'),
          content: const Text('Tem certeza de que deseja apagar a última solução?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _deleteSolve(id);
              },
              child: const Text('Apagar', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  // --- Controle do Cronômetro ---
  void _onPointerDown() {
    if (_timerState == TimerState.running) {
      _stopTimer();
      return;
    }

    if (_timerState == TimerState.idle || _timerState == TimerState.finished) {
      _pendingInspectionPenalty = 0;
      if (_inspectionEnabled) {
        // Só entra em "aguardando" — a contagem de 15s só começa
        // quando o dedo for solto (`_onPointerUp`).
        setState(() => _timerState = TimerState.awaitingInspection);
      } else {
        setState(() => _timerState = TimerState.holding);
      }
    } else if (_timerState == TimerState.inspecting) {
      // Usuário decidiu começar a resolver: trava agora a penalidade
      // de inspeção (0, +2s ou DNF) de acordo com o tempo já gasto.
      _stopInspectionTimer();
      final penalty = _inspectionPenaltyFor(_inspectionStopwatch.elapsedMilliseconds);

      if (penalty == -1) {
        // Passou de 17s bem no instante do toque: já é DNF, não dá
        // pra começar a resolução.
        _saveSolve(0, penalty: -1);
        setState(() => _timerState = TimerState.finished);
        return;
      }

      _pendingInspectionPenalty = penalty;
      setState(() => _timerState = TimerState.holding);
    }
  }

  void _onPointerUp() {
    if (_timerState == TimerState.awaitingInspection) {
      _startInspection();
    } else if (_timerState == TimerState.holding) {
      _startTimer();
    }
  }

  /// Penalidade correspondente ao tempo de inspeção já gasto, seguindo
  /// a regra oficial da WCA:
  /// - até 15s: sem penalidade (0)
  /// - de 15s a 17s: penalidade de +2s (2000ms), somada ao tempo final
  /// - acima de 17s: desclassificado (-1 = DNF)
  int _inspectionPenaltyFor(int elapsedMs) {
    if (elapsedMs <= _inspectionNormalLimitMs) return 0;
    if (elapsedMs <= _inspectionDnfLimitMs) return 2000;
    return -1;
  }

  void _stopInspectionTimer() {
    _inspectionTimer?.cancel();
    _inspectionTimer = null;
    _inspectionStopwatch.stop();
  }

  void _startInspection() {
    _inspectionStopwatch
      ..reset()
      ..start();
    setState(() => _timerState = TimerState.inspecting);

    // Tique curto (200ms) para o cronômetro de inspeção reagir rápido
    // ao estourar 17s, sem depender só de um tique de 1 em 1 segundo.
    _inspectionTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      final elapsedMs = _inspectionStopwatch.elapsedMilliseconds;
      if (elapsedMs > _inspectionDnfLimitMs) {
        // Tempo esgotado sem o competidor começar a resolver: DNF
        // automático.
        _stopInspectionTimer();
        _saveSolve(0, penalty: -1);
        setState(() => _timerState = TimerState.finished);
      } else {
        setState(() {}); // só atualiza a contagem exibida na tela
      }
    });
  }

  void _startTimer() {
    _stopwatch.reset();
    _stopwatch.start();
    setState(() => _timerState = TimerState.running);
    _uiTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      setState(() {});
    });
  }

  void _stopTimer() {
    _stopwatch.stop();
    _uiTimer?.cancel();
    _saveSolve(_stopwatch.elapsedMilliseconds, penalty: _pendingInspectionPenalty);
    _pendingInspectionPenalty = 0;
    setState(() => _timerState = TimerState.finished);
  }

  // --- Estatísticas ---
  int? get _bestTime {
    final valid = _solves.where((s) => s.penalty != -1).toList();
    if (valid.isEmpty) return null;
    return valid.map((s) => s.effectiveTime).reduce((a, b) => a < b ? a : b);
  }

  int? get _worstTime {
    final valid = _solves.where((s) => s.penalty != -1).toList();
    if (valid.isEmpty) return null;
    return valid.map((s) => s.effectiveTime).reduce((a, b) => a > b ? a : b);
  }

  int? _getAverage(int count) {
    final valid = _solves.where((s) => s.penalty != -1).toList();
    if (valid.length < count) return null;
    final lastN = valid.sublist(valid.length - count);
    final sum = lastN.fold<int>(0, (acc, s) => acc + s.effectiveTime);
    return sum ~/ count;
  }

  void _showSettingsPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Configurações do Timer'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Inspeção de 15s'),
                      Switch(
                        value: _inspectionEnabled,
                        onChanged: (val) {
                          setDialogState(() => _inspectionEnabled = val);
                          setState(() {});
                          _repository.saveInspectionEnabled(val);
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Imagem de Fundo'),
                    subtitle: Text(_bgImageBase64 != null && _bgImageBase64!.isNotEmpty
                        ? 'Imagem selecionada'
                        : 'Nenhuma imagem'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_bgImageBase64 != null && _bgImageBase64!.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              await _removeBackgroundImage();
                              setDialogState(() {});
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.image),
                          onPressed: () async {
                            await _pickBackgroundImage();
                            setDialogState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showHistoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SolvesHistoryModal(
              solves: _solves,
              onDeleteSolve: (id) async {
                await _repository.deleteSolve(id);

                if (!mounted) return;

                setState(() {
                  _solves.removeWhere((solve) => solve.id == id);
                  _resetClockAfterDelete();
                });

                setModalState(() {});
              },
            );
          },
        );
      },
    );
  }

  Color _getTextColor() {
    switch (_timerState) {
      case TimerState.idle:
      case TimerState.finished:
        return Colors.white;
      case TimerState.awaitingInspection:
        return Colors.redAccent;
      case TimerState.inspecting:
        // Fica laranja durante os 15s normais e vermelho na janela de
        // penalidade (15s–17s), avisando visualmente do +2s iminente.
        return _inInspectionPenaltyZone ? Colors.redAccent : Colors.orangeAccent;
      case TimerState.holding:
        return Colors.redAccent;
      case TimerState.running:
        return Colors.greenAccent;
    }
  }

  /// `true` quando a inspeção já passou de 15s (janela em que uma
  /// penalidade de +2s será aplicada se a solução começar agora).
  bool get _inInspectionPenaltyZone =>
      _timerState == TimerState.inspecting &&
      _inspectionStopwatch.elapsedMilliseconds > _inspectionNormalLimitMs;

  /// Segundos restantes dos 15s normais de inspeção, para exibir a
  /// contagem regressiva grande na tela (15, 14, ... 0).
  int get _inspectionSecondsLeft {
    final remainingMs = _inspectionNormalLimitMs - _inspectionStopwatch.elapsedMilliseconds;
    if (remainingMs <= 0) return 0;
    return (remainingMs / 1000).ceil();
  }

  String _getStatusText() {
    switch (_timerState) {
      case TimerState.idle:
      case TimerState.finished:
        return 'Pressione e solte para começar';
      case TimerState.awaitingInspection:
        return 'Solte para iniciar a inspeção!';
      case TimerState.inspecting:
        // O número grande no lugar do timer já mostra a contagem (ou o
        // "+2" da penalidade); aqui só um lembrete curto.
        return _inInspectionPenaltyZone
            ? 'Penalidade! Solte para começar antes do DNF'
            : 'Segure e solte para iniciar a solução';
      case TimerState.holding:
        return 'Solte para iniciar!';
      case TimerState.running:
        return 'Resolvendo... (Toque para parar)';
    }
  }

  Widget _buildActionButton(String label, bool isSelected, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.white24 : Colors.black38,
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white30, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildStatText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12, // Fonte menor
        shadows: [
          Shadow(
            blurRadius: 4,
            color: Colors.black,
            offset: Offset(1, 1),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final lastSolve = _solves.isNotEmpty ? _solves.last : null;

    // O relógio começa zerado (ao abrir o app e após apagar uma solução)
    // e só mostra o tempo de uma solução logo depois de terminá-la
    // (`finished`). Antes ele sempre exibia a última solução salva.
    String timerDisplay = '00:00.000';
    if (_timerState == TimerState.inspecting) {
      // Durante a inspeção, o mesmo local grande do timer mostra a
      // contagem regressiva de 15s (ou "+2" se já estiver na janela
      // de penalidade) em vez do último tempo de solução.
      timerDisplay = _inInspectionPenaltyZone ? '+2' : '$_inspectionSecondsLeft';
    } else if (_timerState == TimerState.running) {
      timerDisplay = formatSolveTime(_stopwatch.elapsedMilliseconds);
    } else if (_timerState == TimerState.finished && lastSolve != null) {
      timerDisplay = formatSolveTime(lastSolve.effectiveTime);
    }

    // Os botões +2s / DNF / Apagar valem para a solução que acabou de
    // ser feita, então só aparecem no estado `finished`.
    final actionSolve = _timerState == TimerState.finished ? lastSolve : null;

    return Scaffold(
      body: Stack(
        children: [
          // Área inteira da foto controla o timer.
          // Os botões ficam desenhados depois desta área e recebem o toque primeiro.
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => _onPointerDown(),
              onPointerUp: (_) => _onPointerUp(),
              onPointerCancel: (_) {},
              child: const SizedBox.expand(),
            ),
          ),
          // Imagem de fundo (se configurada) com overlay escuro.
          // - O provider (`_bgImage`) é estável, então não recarrega a
          //   cada rebuild do timer.
          // - `gaplessPlayback` evita qualquer quadro em branco.
          // - O escurecimento é um ColoredBox por cima (em vez de
          //   `colorBlendMode`, que é pesado e instável no navegador).
          // - `RepaintBoundary` isola a imagem: o timer redesenha a 60fps
          //   sem precisar repintar o wallpaper.
          if (_bgImage != null)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image(
                        image: _bgImage!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                      ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
                    ],
                  ),
                ),
              ),
            ),

          // Botões no Topo Direito
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea( // SafeArea protege contra notch/barra de status no topo
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.white),
                    tooltip: 'Histórico de Solves',
                    onPressed: _showHistoryModal,
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    tooltip: 'Configurações',
                    onPressed: _showSettingsPopup,
                  ),
                ],
              ),
            ),
          ),

          // Centro: Display do Tempo, Status e Botões de Ação (+2s, DNF, Apagar)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IgnorePointer(
                  child: Text(
                    timerDisplay,
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(),
                      shadows: const [
                        Shadow(blurRadius: 10, color: Colors.black, offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                IgnorePointer(
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 16,
                      color: _getTextColor().withValues(alpha: 0.9),
                      shadows: const [
                        Shadow(blurRadius: 6, color: Colors.black, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Altura fixa reservada: os botões aparecem/somem sem
                // empurrar o relógio para cima e para baixo.
                SizedBox(
                  height: 48,
                  child: actionSolve != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionButton(
                              '+2s',
                              actionSolve.penalty == 2000,
                              () => _updatePenalty(
                                actionSolve.id,
                                actionSolve.penalty == 2000 ? 0 : 2000,
                              ),
                            ),
                            _buildActionButton(
                              'DNF',
                              actionSolve.penalty == -1,
                              () => _updatePenalty(
                                actionSolve.id,
                                actionSolve.penalty == -1 ? 0 : -1,
                              ),
                            ),
                            _buildActionButton(
                              'Apagar',
                              false,
                              () => _confirmDeleteSolve(actionSolve.id),
                            ),
                          ],
                        )
                      : null,
                ),
              ],
            ),
          ),

          // Estatísticas Esquerda (Fundo Transparente)
          Positioned(
            left: 4,
            bottom: 4,
            child: SafeArea(
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatText('Melhor tempo: ${_bestTime != null ? formatSolveTime(_bestTime!) : '--'}'),
                      _buildStatText('Média de 5: ${_getAverage(5) != null ? formatSolveTime(_getAverage(5)!) : '--'}'),
                      _buildStatText('Média de 12: ${_getAverage(12) != null ? formatSolveTime(_getAverage(12)!) : '--'}'),
                      _buildStatText('Média de 50: ${_getAverage(50) != null ? formatSolveTime(_getAverage(50)!) : '--'}'),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Estatísticas Direita (Fundo Transparente)
          Positioned(
            right: 4,
            bottom: 4,
            child: SafeArea(
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatText('Pior tempo: ${_worstTime != null ? formatSolveTime(_worstTime!) : '--'}'),
                      _buildStatText('Média de 100: ${_getAverage(100) != null ? formatSolveTime(_getAverage(100)!) : '--'}'),
                      _buildStatText('Média de 1000: ${_getAverage(1000) != null ? formatSolveTime(_getAverage(1000)!) : '--'}'),
                      _buildStatText('Número de soluções: ${_solves.length}'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
