import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MultiEngineReproApp());
}

class MultiEngineReproApp extends StatelessWidget {
  const MultiEngineReproApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MultiEngineReproPage(),
    );
  }
}

class MultiEngineReproPage extends StatefulWidget {
  const MultiEngineReproPage({Key? key}) : super(key: key);

  @override
  State<MultiEngineReproPage> createState() => _MultiEngineReproPageState();
}

class _MultiEngineReproPageState extends State<MultiEngineReproPage> {
  static const MethodChannel _channel = MethodChannel(
    'tradplus_sdk/multi_engine_repro',
  );

  Map<String, dynamic>? _state;
  final List<bool> _hostActivityHistory = <bool>[];
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _invoke('getState');
  }

  Future<void> _invoke(String method) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>(method);
      if (!mounted) {
        return;
      }
      setState(() {
        _state = result?.cast<String, dynamic>();
        _hostActivityHistory.add(_state?['tradPlusActivityIsHost'] == true);
      });
    } on PlatformException catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = exception.message ?? exception.code;
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool secondaryRunning = _state?['secondaryEngineRunning'] == true;
    final bool secondaryDestroyed = _state?['secondaryEngineDestroyed'] == true;
    final bool hostActivityOwned = _state?['tradPlusActivityIsHost'] == true;
    final bool bugReproduced = _hostActivityHistory.length == 3 &&
        _hostActivityHistory[0] &&
        _hostActivityHistory[1] &&
        !_hostActivityHistory[2];
    final String transition = _hostActivityHistory.isEmpty
        ? 'Loading'
        : _hostActivityHistory
            .map((bool value) => value ? 'true' : 'false')
            .join(' -> ');

    return Scaffold(
      appBar: AppBar(title: const Text('TradPlus multi-Engine repro')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            _StatusRow(
              label: 'Secondary FlutterEngine',
              value: secondaryDestroyed
                  ? 'Destroyed'
                  : secondaryRunning
                      ? 'Running'
                      : 'Not created',
            ),
            const Divider(height: 32),
            _StatusRow(
              label: 'Original instance owns host Activity',
              value: _state == null
                  ? 'Loading'
                  : hostActivityOwned
                      ? 'true'
                      : 'false',
              isFailure: secondaryDestroyed && !hostActivityOwned,
            ),
            const Divider(height: 32),
            _StatusRow(
              label: 'Observed instance',
              value: _state?['observedTradPlusInstanceId']?.toString() ??
                  'Loading',
            ),
            const Divider(height: 32),
            _StatusRow(
              label: 'Host ownership history',
              value: transition,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _busy || secondaryRunning || secondaryDestroyed
                  ? null
                  : () => _invoke('createSecondaryEngine'),
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('1. Create secondary Engine'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _busy || !secondaryRunning
                  ? null
                  : () => _invoke('destroySecondaryEngine'),
              icon: const Icon(Icons.delete_outline),
              label: const Text('2. Destroy secondary Engine'),
            ),
            const SizedBox(height: 28),
            if (_busy) const Center(child: CircularProgressIndicator()),
            if (bugReproduced)
              const _ResultBanner(
                text: 'Bug reproduced: the secondary Engine detached the '
                    'main Engine\'s TradPlus Activity.',
              ),
            if (secondaryDestroyed && !bugReproduced)
              const _ResultBanner(
                text: 'Inconclusive: expected host ownership history '
                    'true -> true -> false.',
                isError: true,
              ),
            if (_error != null) _ResultBanner(text: _error!, isError: true),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    this.isFailure = false,
  });

  final String label;
  final String value;
  final bool isFailure;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label)),
        const SizedBox(width: 16),
        Text(
          value,
          style: TextStyle(
            color: isFailure ? Colors.red : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.text, this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final Color color = isError ? Colors.red : Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}
