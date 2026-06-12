import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/ai_advisor_service.dart';

class AiAdvisorBottomSheet extends StatefulWidget {
  final double totalIncome;
  final double totalExpense;
  final Map<String, double> expensesByCategory;

  const AiAdvisorBottomSheet({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.expensesByCategory,
  });

  @override
  State<AiAdvisorBottomSheet> createState() => _AiAdvisorBottomSheetState();
}

class _AiAdvisorBottomSheetState extends State<AiAdvisorBottomSheet> {
  String? _advice;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdvice();
  }

  Future<void> _fetchAdvice() async {
    try {
      final advice = await AiAdvisorService.getFinancialAdvice(
        totalIncome: widget.totalIncome,
        totalExpense: widget.totalExpense,
        expensesByCategory: widget.expensesByCategory,
      );
      if (mounted) {
        setState(() {
          _advice = advice;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Çizgi (Draggable Handle)
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber.shade600, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Yapay Zeka Danışmanı',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: _buildContent(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return Column(
        children: [
          const SizedBox(height: 32),
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Harcamalarınız analiz ediliyor...\nLütfen bekleyin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 32),
        ],
      );
    }

    if (_error != null) {
      return Column(
        children: [
          const SizedBox(height: 16),
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _fetchAdvice();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
          ),
        ],
      );
    }

    if (_advice != null) {
      return MarkdownBody(
        data: _advice!,
        styleSheet: MarkdownStyleSheet(
          p: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          h1: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          h2: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          h3: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          listBullet: theme.textTheme.bodyLarge,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
