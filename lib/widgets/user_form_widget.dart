import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UserFormWidget extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController idNoController;
  final TextEditingController birthDateController;
  final FocusNode nameFocusNode;
  final FocusNode idNoFocusNode;
  final FocusNode birthDateFocusNode;
  final VoidCallback onNameSubmitted;
  final VoidCallback onIdNoSubmitted;
  final VoidCallback onBirthDateSubmitted;

  const UserFormWidget({
    Key? key,
    required this.nameController,
    required this.idNoController,
    required this.birthDateController,
    required this.nameFocusNode,
    required this.idNoFocusNode,
    required this.birthDateFocusNode,
    required this.onNameSubmitted,
    required this.onIdNoSubmitted,
    required this.onBirthDateSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: nameController,
          focusNode: nameFocusNode,
          decoration: InputDecoration(
            labelText: 'Ad Soyad',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => onNameSubmitted(),
        ),
        SizedBox(height: 16),
        TextField(
          controller: idNoController,
          focusNode: idNoFocusNode,
          decoration: InputDecoration(
            labelText: 'Kimlik No',
            border: OutlineInputBorder(),
            counterText: '${idNoController.text.length}/11',
            helperText: '11 haneli kimlik numarası giriniz',
          ),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          maxLength: 11,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          onChanged: (value) {
            // Trigger rebuild for counter update
          },
          onSubmitted: (_) => onIdNoSubmitted(),
        ),
        SizedBox(height: 16),
        TextField(
          controller: birthDateController,
          focusNode: birthDateFocusNode,
          decoration: InputDecoration(
            labelText: 'Doğum Tarihi (YYYY-AA-GG)',
            border: OutlineInputBorder(),
            counterText: '${birthDateController.text.length}/10',
            helperText: 'Sadece rakamları girin',
          ),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: 10,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _DateInputFormatter(),
          ],
          onChanged: (value) {
            // Trigger rebuild for counter update
          },
          onSubmitted: (_) => onBirthDateSubmitted(),
        ),
      ],
    );
  }
}

// Tarih formatı için özel input formatter
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // Sadece rakamları al
    String text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Maksimum 8 rakam (YYYYMMDD)
    if (text.length > 8) {
      text = text.substring(0, 8);
    }

    // Tire ekleme
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 4 || i == 6) {
        formatted += '-';
      }
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
