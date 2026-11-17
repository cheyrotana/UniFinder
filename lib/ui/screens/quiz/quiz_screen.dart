import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../Domain/model/Quiz/answer_model.dart';
import '../../../Domain/model/Quiz/option_model.dart';
import '../../../Domain/model/Quiz/question_model.dart';
import '../../../Domain/model/Quiz/submission_model.dart';
import '../../../main.dart' show questionService, userService;
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/category_style.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

/// The 10-question interest quiz. Picking an answer moves on by itself;
/// questions slide left/right with the direction of travel.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Question> _questions = [];
  Map<String, List<Option>> _options = {};
  final Map<String, String> _answers = {};
  int _index = 0;

  /// +1 moving forward, -1 back: which way the questions slide.
  int _direction = 1;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final questions = await questionService.getQuestionData();
    final options = await questionService.getOptionsByQuestion();
    if (!mounted) return;
    setState(() {
      _questions = questions;
      _options = options;
      _loading = false;
    });
  }

  Question get _question => _questions[_index];
  bool get _isLast => _index == _questions.length - 1;
  bool get _answered => _answers.containsKey(_question.id);

  void _go(int to) {
    if (to < 0 || to >= _questions.length) return;
    setState(() {
      _direction = to > _index ? 1 : -1;
      _index = to;
    });
  }

  void _select(Option option) {
    HapticFeedback.selectionClick();
    final questionId = _question.id;
    final wasAnswered = _answers.containsKey(questionId);
    setState(() => _answers[questionId] = option.id);
    // First answer to a question: move on after the tick shows.
    if (!wasAnswered && !_isLast) {
      final at = _index;
      Future.delayed(const Duration(milliseconds: 380), () {
        if (mounted && _index == at) _go(_index + 1);
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final user = await userService.getUser();
    if (user == null) {
      if (mounted) context.go('/name');
      return;
    }
    await questionService.saveSubmission(
      Submission(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id ?? '',
        answers: [
          for (final e in _answers.entries)
            Answer(questionId: e.key, selectedOptionId: e.value),
        ],
        completedAt: DateTime.now(),
      ),
    );
    if (mounted) context.go('/recommendation');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_questions.isEmpty) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.quiz_outlined,
          title: 'No questions found',
        ),
      );
    }

    final options = _options[_question.id] ?? const <Option>[];
    final progress = (_index + (_answered ? 1 : 0)) / _questions.length;

    return Scaffold(
      backgroundColor: context.colors.card,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              index: _index,
              total: _questions.length,
              progress: progress,
              onClose: context.canPop() ? () => context.pop() : null,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: context.motion(const Duration(milliseconds: 380)),
                switchInCurve: AppMotion.emphasized,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                transitionBuilder: (child, animation) {
                  final incoming = child.key == ValueKey(_index);
                  final dx = (incoming ? 1 : -1) * _direction * 0.25;
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: Offset(dx, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _QuestionView(
                  key: ValueKey(_index),
                  question: _question,
                  options: options,
                  selectedId: _answers[_question.id],
                  onSelect: _select,
                ),
              ),
            ),
            _Footer(
              canBack: _index > 0,
              isLast: _isLast,
              canNext: _answered,
              submitting: _submitting,
              onBack: () => _go(_index - 1),
              onNext: _isLast ? _submit : () => _go(_index + 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.index,
    required this.total,
    required this.progress,
    this.onClose,
  });

  final int index;
  final int total;
  final double progress;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.gutter,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          if (onClose != null)
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded),
              onPressed: onClose,
            )
          else
            const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: const Duration(milliseconds: 450),
              curve: AppMotion.emphasized,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(value: value, minHeight: 8),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${index + 1}/$total',
            style: context.text.labelMedium!.copyWith(
              color: context.colors.muted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    super.key,
    required this.question,
    required this.options,
    required this.selectedId,
    required this.onSelect,
  });

  final Question question;
  final List<Option> options;
  final String? selectedId;
  final ValueChanged<Option> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.lg,
        AppSpacing.gutter,
        AppSpacing.lg,
      ),
      children: [
        Text(question.text, style: context.text.headlineSmall),
        const SizedBox(height: 6),
        Text('Pick the one that fits you best', style: context.text.bodySmall),
        const SizedBox(height: AppSpacing.lg),
        for (final option in options) ...[
          _OptionCard(
            option: option,
            selected: option.id == selectedId,
            onTap: () => onSelect(option),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final Option option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(option.categoryId);
    final primary = context.scheme.primary;
    return Semantics(
      selected: selected,
      button: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? context.colors.brandSoft : context.colors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? primary : context.colors.hairline,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              IconTile(icon: style.icon, color: style.color, size: 42),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  option.text,
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AnimatedContainer(
                duration: AppMotion.medium,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? primary : context.colors.hairline,
                    width: 2,
                  ),
                ),
                child: AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: AppMotion.medium,
                  curve: Curves.easeOutBack,
                  child: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.canBack,
    required this.isLast,
    required this.canNext,
    required this.submitting,
    required this.onBack,
    required this.onNext,
  });

  final bool canBack;
  final bool isLast;
  final bool canNext;
  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.colors.hairline)),
      ),
      child: Row(
        children: [
          AnimatedSize(
            duration: AppMotion.medium,
            curve: AppMotion.emphasized,
            child: canBack
                ? Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(52, 52),
                        ),
                        onPressed: onBack,
                        child: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: FilledButton(
              onPressed: canNext && !submitting ? onNext : null,
              child: AnimatedSwitcher(
                duration: AppMotion.medium,
                child: submitting
                    ? const SizedBox.square(
                        key: ValueKey('busy'),
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isLast ? 'See my matches' : 'Next',
                        key: ValueKey(isLast),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
