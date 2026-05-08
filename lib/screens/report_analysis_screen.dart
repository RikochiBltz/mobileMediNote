import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/report_analysis_service.dart';
import '../services/theme_provider.dart';
import '../theme/app_design.dart';

class ReportAnalysisScreen extends StatefulWidget {
  final User user;

  const ReportAnalysisScreen({super.key, required this.user});

  @override
  State<ReportAnalysisScreen> createState() => _ReportAnalysisScreenState();
}

class _ReportAnalysisScreenState extends State<ReportAnalysisScreen> {
  final _service = ReportAnalysisService();

  PlatformFile? _selectedFile;
  ReportAnalysisResult? _result;
  bool _isLoading = false;
  String? _error;

  Future<void> _pickFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      withData: false,
    );

    if (picked == null || picked.files.isEmpty) {
      return;
    }

    setState(() {
      _selectedFile = picked.files.single;
      _result = null;
      _error = null;
    });
  }

  Future<void> _analyze() async {
    final file = _selectedFile;
    if (file == null || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.analyzeFile(file);
      if (!mounted) return;
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeInheritedWidget.of(context)?.isDarkMode ?? false;
    final background = isDark ? AppDesign.darkBackground : Colors.white;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppDesign.pageGradient(isDark),
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 16),
              _buildPicker(isDark),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _buildError(isDark),
              ],
              if (_result != null) ...[
                const SizedBox(height: 16),
                _buildResult(isDark, _result!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppDesign.green, AppDesign.greenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppDesign.green.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Report Analysis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicker(bool isDark) {
    final cardColor = AppDesign.surface(isDark);
    final textColor = AppDesign.textPrimary(isDark);
    final secondaryColor = AppDesign.textSecondary(isDark);
    final file = _selectedFile;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppDesign.cardBorder(isDark)),
        boxShadow: [
          BoxShadow(
            color: AppDesign.green.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _isLoading ? null : _pickFile,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppDesign.green.withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppDesign.green.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    file == null
                        ? Icons.upload_file_rounded
                        : Icons.insert_drive_file_rounded,
                    color: AppDesign.green,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file?.name ?? 'Select PDF or image',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          file == null
                              ? 'PDF, PNG, JPG, JPEG, WEBP'
                              : _size(file.size),
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppDesign.green),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: file == null || _isLoading ? null : _analyze,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesign.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppDesign.green.withValues(
                  alpha: 0.35,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.analytics_rounded),
              label: Text(
                _isLoading ? 'Analyzing' : 'Analyze',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: isDark ? Colors.red[100] : Colors.red[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(bool isDark, ReportAnalysisResult result) {
    final cardColor = AppDesign.surface(isDark);
    final textColor = AppDesign.textPrimary(isDark);
    final secondaryColor = AppDesign.textSecondary(isDark);
    final validColor = result.isValid ? AppDesign.green : Colors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppDesign.cardBorder(isDark)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _scoreRing(result.finalScore, validColor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _pill(result.validationStatus, validColor),
                        const SizedBox(height: 8),
                        Text(
                          result.filename,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${result.extractionSource}  |  ${result.validationReason}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: secondaryColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _sectionTitle('Missing fields', textColor),
              const SizedBox(height: 8),
              _chips(
                result.missingFields.isEmpty
                    ? const ['None']
                    : result.missingFields,
                result.missingFields.isEmpty ? AppDesign.green : Colors.orange,
              ),
              const SizedBox(height: 16),
              _sectionTitle('Keywords', textColor),
              const SizedBox(height: 8),
              _chips(
                result.keywords.isEmpty
                    ? const ['No keywords detected']
                    : result.keywords,
                const Color(0xFF2980B9),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _fieldsCard(isDark, result),
        const SizedBox(height: 14),
        _scoresCard(isDark, result),
        const SizedBox(height: 14),
        _textCard(isDark, result),
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 14),
          _warningsCard(isDark, result),
        ],
      ],
    );
  }

  Widget _fieldsCard(bool isDark, ReportAnalysisResult result) {
    final fields = result.structuredFields.entries.toList();
    return _resultCard(
      isDark: isDark,
      title: 'Fields',
      child: fields.isEmpty
          ? _mutedText(isDark, 'No structured fields found')
          : Column(
              children: fields.map((entry) {
                final value = entry.value?.toString() ?? '';
                return _keyValueRow(
                  isDark,
                  entry.key,
                  value.isEmpty ? '-' : value,
                );
              }).toList(),
            ),
    );
  }

  Widget _scoresCard(bool isDark, ReportAnalysisResult result) {
    final scores = result.scores.entries
        .where((entry) => entry.key != 'final_score')
        .toList();
    return _resultCard(
      isDark: isDark,
      title: 'Score details',
      child: Column(
        children: scores.map((entry) {
          return _keyValueRow(isDark, entry.key, entry.value.toString());
        }).toList(),
      ),
    );
  }

  Widget _textCard(bool isDark, ReportAnalysisResult result) {
    return _resultCard(
      isDark: isDark,
      title: 'Reformulated text',
      child: SelectableText(
        result.reformulatedText.isEmpty
            ? result.correctedText
            : result.reformulatedText,
        style: TextStyle(
          color: AppDesign.textPrimary(isDark),
          height: 1.45,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _warningsCard(bool isDark, ReportAnalysisResult result) {
    return _resultCard(
      isDark: isDark,
      title: 'Warnings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: result.warnings
            .map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  warning,
                  style: TextStyle(
                    color: AppDesign.textSecondary(isDark),
                    fontSize: 13,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _resultCard({
    required bool isDark,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppDesign.surface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppDesign.cardBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, AppDesign.textPrimary(isDark)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _scoreRing(int score, Color color) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: (score.clamp(0, 100)) / 100,
            strokeWidth: 7,
            backgroundColor: color.withValues(alpha: 0.14),
            color: color,
          ),
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _chips(List<String> values, Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) => _pill(value, color)).toList(),
    );
  }

  Widget _keyValueRow(bool isDark, String label, String value) {
    final textColor = AppDesign.textPrimary(isDark);
    final secondaryColor = AppDesign.textSecondary(isDark);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label.replaceAll('_', ' '),
              style: TextStyle(
                color: secondaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mutedText(bool isDark, String text) {
    return Text(
      text,
      style: TextStyle(color: AppDesign.textSecondary(isDark), fontSize: 13),
    );
  }

  String _size(int bytes) {
    if (bytes <= 0) return 'Unknown size';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
