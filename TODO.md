# TODO - UI/Loading/Overflow fixes (Bike Rental)

## Step 1: Staff Dashboard header + customer card + FAB
- Reduce dashboard header container padding (top/bottom) ~20–25% without changing colors/typography.
- Update customer card header layout:

  - Name stays one line with ellipsis.
  - Code stays one line: exactly "Code: <custCode>".
- Remove any potential RenderFlex overflow in customer card:
  - Use Expanded/Flexible/Wrap/Spacer appropriately.
  - Ensure bottom buttons (Edit, Invoice, Mark Returned) wrap on small screens.
  - Ensure Payment button appears after Mark Returned press and stays fully inside card.
- Fix FloatingActionButton overlap with Recent Bookings by adding proper bottom spacing/padding.

## Step 2: Payment screen loading/error/empty state
- Ensure PaymentRecordScreen never loads forever.
- Handle exceptions and show empty state if no QR/payment data exists.
- Keep Firestore logic unchanged.

## Step 3: Payment Settings empty state (no red error)
- PaymentSettingsScreen should show clean empty state when no methods.
- Avoid red error screen; handle stream errors gracefully.
- Ensure + Add QR Code continues to work.

## Step 4: Invoice screen disabled actions
- Identify why invoice actions are disabled.
- Enable Print/Share/Download/WhatsApp/PDF generation controls without redesigning.

## Step 5: Verify
- flutter run (build success, no compilation errors).
- Ensure zero RenderFlex overflow.
- Validate UI requirements listed in prompt.

