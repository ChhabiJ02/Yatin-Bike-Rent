import 'package:flutter/material.dart';
import '../models/qr_code.dart';
import '../theme/app_theme.dart';

class QRCodeSelector extends StatelessWidget {
  final List<QRCodePayment> qrCodes;
  final String? selectedQRId;
  final ValueChanged<QRCodePayment> onQRSelected;

  const QRCodeSelector({
    super.key,
    required this.qrCodes,
    required this.selectedQRId,
    required this.onQRSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (qrCodes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No QR codes available.\nPlease add QR codes in Payment Settings.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: qrCodes.length,
      itemBuilder: (context, index) {
        final qr = qrCodes[index];
        final isSelected = qr.id == selectedQRId;

        return _QRCodeCard(
          qrCode: qr,
          isSelected: isSelected,
          onTap: () => onQRSelected(qr),
        );
      },
    );
  }
}

class _QRCodeCard extends StatelessWidget {
  final QRCodePayment qrCode;
  final bool isSelected;
  final VoidCallback onTap;

  const _QRCodeCard({
    required this.qrCode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.ember : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.ember.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Expanded(
                      child: qrCode.imageUrl.isNotEmpty
                          ? Image.network(
                              qrCode.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  _buildPlaceholderIcon(),
                            )
                          : _buildPlaceholderIcon(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      qrCode.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (qrCode.upiId.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        qrCode.upiId,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.ember,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: Colors.grey[100],
      child: const Icon(
        Icons.qr_code,
        size: 48,
        color: AppColors.muted,
      ),
    );
  }
}