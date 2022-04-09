import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ignore: must_be_immutable
class CustomTextField extends StatefulWidget {
  CustomTextField(
      {Key? key,
      this.horizontalPadding = 0,
      this.showCounter = true,
      this.verticalPadding = 7,
      this.hintText,
      this.validationMessage = '',
      this.autofillHints,
      this.onEditingComplete,
      this.onChanged,
      this.contentPadding,
      this.obscureText = false,
      this.keyboardType,
      this.controller,
      this.maxLength,
      this.inputFormatters,
      this.enabled,
      this.focusNode,
      this.suffixIcon,
      this.showValidationMessage = false})
      : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
  final double horizontalPadding, verticalPadding;
  final int? maxLength;
  final String? hintText, validationMessage;
  final bool showValidationMessage, obscureText, showCounter;
  final bool? enabled;
  final List<String>? autofillHints;
  final FocusNode? focusNode;
  void Function()? onEditingComplete;
  void Function(String)? onChanged;
  final EdgeInsetsGeometry? contentPadding;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
}

class _CustomTextFieldState extends State<CustomTextField> {
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(
            horizontal: widget.horizontalPadding,
            vertical: widget.verticalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              enableSuggestions: true,
              focusNode: widget.focusNode,
              inputFormatters: widget.inputFormatters,
              enabled: widget.enabled,
              maxLength: widget.maxLength,
              controller: widget.controller,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscureText,
              onEditingComplete: widget.onEditingComplete,
              autofillHints: widget.autofillHints,
              style: const TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 17,
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                  counter: widget.showCounter ? null : const SizedBox.shrink(),
                  suffixIcon: widget.suffixIcon,
                  contentPadding:
                      widget.contentPadding ?? const EdgeInsets.all(14),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F2),
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(
                      color: Color(0xffAAAAAA),
                      fontFamily: 'WorkSans',
                      fontSize: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(
                        width: 0,
                        style: BorderStyle.none,
                      ))),
              onChanged: widget.onChanged,
            ),
            if (widget.showValidationMessage)
              Text(
                widget.validationMessage ?? '',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
      );
}
