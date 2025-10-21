import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';
import 'package:markmeapp/presentation/widgets/ui/calendar.dart';

class StudentPersonalInfoSection extends StatelessWidget {
  final TextEditingController firstNameCtrl;
  final TextEditingController middleNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController dobCtrl;
  final DateTime? dob;
  final BoxDecoration cardDecoration;

  const StudentPersonalInfoSection({
    Key? key,
    required this.firstNameCtrl,
    required this.middleNameCtrl,
    required this.lastNameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.dobCtrl,
    required this.dob,
    required this.cardDecoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InputField(
                  label: 'First name',
                  controller: firstNameCtrl,
                  isRequired: true,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InputField(
                  label: 'Middle name',
                  controller: middleNameCtrl,
                  hintText: 'Optional',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InputField(
            label: 'Last name',
            controller: lastNameCtrl,
            isRequired: true,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          InputField(
            label: 'Email',
            controller: emailCtrl,
            readOnly: true,
            suffixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),
          InputField(
            label: 'Phone',
            controller: phoneCtrl,
            isRequired: true,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          // Calendar(
          //   controller: dobCtrl,
          //   label: 'Date of Birth',
          //   isRequired: true,
          //   validator: (_) => dob == null ? 'Select a date' : null,
          // ),
        ],
      ),
    );
  }
}
