import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../Domain/model/User/user_model.dart';
import '../../../main.dart' show userService;
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/entrance.dart';

/// Asks for the student's name before the quiz.
class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _name = TextEditingController();
  bool _saving = false;

  bool get _valid => _name.text.trim().length >= 2;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    await userService.saveUser(User(name: _name.text.trim()));
    if (mounted) context.go('/quiz');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.card,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 2 * AppSpacing.gutter,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Entrance(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: context.colors.brandSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.waving_hand_rounded,
                          color: context.scheme.primary,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Entrance(
                      index: 1,
                      child: Text(
                        "First, what's your name?",
                        style: context.text.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Entrance(
                      index: 2,
                      child: Text(
                        "We'll use it to personalise your results. It stays on this phone.",
                        style: context.text.bodyLarge!.copyWith(
                          color: context.colors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Entrance(
                      index: 3,
                      child: TextField(
                        controller: _name,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        style: context.text.titleMedium,
                        decoration: const InputDecoration(
                          hintText: 'Your name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _valid && !_saving ? _submit : null,
                        child: const Text('Start the quiz'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
