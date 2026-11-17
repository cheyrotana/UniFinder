import 'package:flutter/material.dart';

import '../../../Domain/model/Dream/dreams_model.dart';
import '../../../main.dart' show dreamService;
import '../../widgets/common.dart';
import '../major/major_screen.dart';

/// A saved dream, by ID: its major's screen with the dream's actions.
class DreamScreen extends StatefulWidget {
  const DreamScreen({super.key, required this.dreamId, this.dream});

  final String dreamId;

  /// The dream when the opener has it (Home): then the screen is ready on
  /// its first frame, which the photo's hero flight needs.
  final Dream? dream;

  @override
  State<DreamScreen> createState() => _DreamScreenState();
}

class _DreamScreenState extends State<DreamScreen> {
  late final Future<Dream?> _dream = widget.dream != null
      ? Future.value(widget.dream)
      : dreamService.getDreamById(widget.dreamId);

  @override
  Widget build(BuildContext context) {
    if (widget.dream case final dream?) {
      return MajorScreen(majorId: dream.majorId, dream: dream);
    }
    return FutureBuilder<Dream?>(
      future: _dream,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final dream = snapshot.data;
        if (dream == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: EmptyState(
                icon: Icons.auto_awesome_outlined,
                title: 'Dream not found',
                message: 'It may have been deleted.',
              ),
            ),
          );
        }
        return MajorScreen(majorId: dream.majorId, dream: dream);
      },
    );
  }
}
