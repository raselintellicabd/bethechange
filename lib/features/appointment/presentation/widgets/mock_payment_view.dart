export '../../../../core/widgets/checkout/mock_payment_view.dart';
export '../../../../core/widgets/checkout/mock_payment_otp_view.dart';

import '../../domain/models/book_online_offering.dart';

String paymentAmountLabel(BookOnlineOffering? offering) {
  if (offering == null) return 'Free';
  return offering.priceDisplay;
}
