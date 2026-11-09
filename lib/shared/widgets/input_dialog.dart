import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/tokens.dart';

/// 값 하나를 입력받는 대화상자. 확인하면 입력값, 취소하면 null.
///
/// 입력칸 컨트롤러를 대화상자가 직접 갖고 있다가 닫힘 애니메이션이 끝난 뒤 정리한다.
/// (호출한 쪽에서 바로 dispose하면 닫히는 동안 오류가 난다)
Future<String?> showInputDialog(
  BuildContext context, {
  required String title,
  String initial = '',
  String? message,
  String? hint,
  String? suffix,
  TextInputType keyboardType = TextInputType.text,
  List<TextInputFormatter>? formatters,
  bool obscure = false,
  String confirmLabel = '확인',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _InputDialog(
      title: title,
      initial: initial,
      message: message,
      hint: hint,
      suffix: suffix,
      keyboardType: keyboardType,
      formatters: formatters,
      obscure: obscure,
      confirmLabel: confirmLabel,
    ),
  );
}

/// 숫자 입력 (정수 또는 소수 한 자리)
Future<num?> showNumberDialog(
  BuildContext context, {
  required String title,
  num? initial,
  String? suffix,
  bool decimal = false,
  String confirmLabel = '확인',
}) async {
  final text = await showInputDialog(
    context,
    title: title,
    initial: initial == null
        ? ''
        : (decimal ? initial.toStringAsFixed(1) : '${initial.round()}'),
    suffix: suffix,
    keyboardType: decimal
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.number,
    formatters: [
      decimal
          ? FilteringTextInputFormatter.allow(RegExp(r'^\d{0,4}(\.\d?)?'))
          : FilteringTextInputFormatter.digitsOnly,
    ],
    confirmLabel: confirmLabel,
  );
  if (text == null) return null;
  return decimal ? double.tryParse(text) : int.tryParse(text);
}

class _InputDialog extends StatefulWidget {
  const _InputDialog({
    required this.title,
    required this.initial,
    required this.message,
    required this.hint,
    required this.suffix,
    required this.keyboardType,
    required this.formatters,
    required this.obscure,
    required this.confirmLabel,
  });

  final String title;
  final String initial;
  final String? message;
  final String? hint;
  final String? suffix;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? formatters;
  final bool obscure;
  final String confirmLabel;

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late final _ctrl = TextEditingController(text: widget.initial);
  late bool _hidden = widget.obscure;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null) ...[
            Text(
              widget.message!,
              style: AppText.caption.copyWith(color: p.text2),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
          TextField(
            controller: _ctrl,
            autofocus: true,
            obscureText: _hidden,
            autocorrect: !widget.obscure,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.formatters,
            style: widget.keyboardType == TextInputType.text
                ? null
                : AppText.numeric(AppText.title2),
            onSubmitted: (v) => Navigator.pop(context, v),
            decoration: InputDecoration(
              hintText: widget.hint,
              suffixText: widget.suffix,
              suffixIcon: widget.obscure
                  ? IconButton(
                      icon: Icon(
                        _hidden
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                      tooltip: _hidden ? '보기' : '숨기기',
                      onPressed: () => setState(() => _hidden = !_hidden),
                    )
                  : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
