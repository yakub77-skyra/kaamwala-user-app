// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'KaamWala';

  @override
  String get appNamePartner => 'KaamWala Partner';

  @override
  String get home => 'Home';

  @override
  String get search => 'Search';

  @override
  String get bookings => 'Bookings';

  @override
  String get profile => 'Profile';

  @override
  String get earnings => 'Earnings';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get enterPhoneNumber => 'Enter your phone number';

  @override
  String get sendOTP => 'Send OTP';

  @override
  String get otp => 'OTP';

  @override
  String get enterOTP => 'Enter OTP';

  @override
  String get verifyOTP => 'Verify OTP';

  @override
  String get resendOTP => 'Resend OTP';

  @override
  String resendIn(Object seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get name => 'Name';

  @override
  String get enterName => 'Enter your name';

  @override
  String get city => 'City';

  @override
  String get selectCity => 'Select your city';

  @override
  String get roleSelection => 'Who are you?';

  @override
  String get customer => 'I need a worker';

  @override
  String get worker => 'I am a worker';

  @override
  String get bookWorker => 'Book Worker';

  @override
  String get whatWork => 'What work do you need?';

  @override
  String get describeWork => 'Describe the work...';

  @override
  String get when => 'When?';

  @override
  String get date => 'Date';

  @override
  String get timeSlot => 'Time Slot';

  @override
  String get where => 'Where?';

  @override
  String get address => 'Address';

  @override
  String get enterAddress => 'Enter your full address';

  @override
  String get jobEstimate => 'Job Estimate';

  @override
  String get bookingFee => 'Booking Fee (refundable)';

  @override
  String get finalPriceNote =>
      'Final price is agreed with the worker before work starts.';

  @override
  String payAndBook(Object amount) {
    return 'Pay ₹$amount & Book';
  }

  @override
  String get creatingBooking => 'Creating booking...';

  @override
  String get cancelAnytime => 'Cancel anytime while pending = full refund';

  @override
  String get myBookings => 'My Bookings';

  @override
  String get noBookings => 'No bookings yet';

  @override
  String get bookingDetail => 'Booking Details';

  @override
  String get workerDetails => 'Worker Details';

  @override
  String get status => 'Status';

  @override
  String get pending => 'Pending';

  @override
  String get accepted => 'Accepted';

  @override
  String get traveling => 'Traveling';

  @override
  String get arrived => 'Arrived';

  @override
  String get inProgress => 'In Progress';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get declined => 'Declined';

  @override
  String get cancelBooking => 'Cancel Booking';

  @override
  String get confirmCancel => 'Are you sure you want to cancel this booking?';

  @override
  String get yesCancel => 'Yes, Cancel';

  @override
  String get noKeep => 'No, Keep';

  @override
  String get chat => 'Chat';

  @override
  String get message => 'Message';

  @override
  String get send => 'Send';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get rateReview => 'Rate & Review';

  @override
  String get rating => 'Rating';

  @override
  String get review => 'Review';

  @override
  String get submitReview => 'Submit Review';

  @override
  String get addPhotos => 'Add photos/videos (optional)';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get maxPhotos => 'Maximum 5 photos/videos allowed';

  @override
  String get uploadFailed => 'Failed to upload media';

  @override
  String get searchWorkers => 'Search by name';

  @override
  String get sortBy => 'Sort by';

  @override
  String get topRated => 'Top rated first';

  @override
  String get priceLowHigh => 'Price: low to high';

  @override
  String get priceHighLow => 'Price: high to low';

  @override
  String get nearestFirst => 'Nearest first';

  @override
  String get enableLocation => 'Enable location for distance sorting';

  @override
  String get availableNow => 'Available now';

  @override
  String distance(Object distance) {
    return '$distance km away';
  }

  @override
  String fromPrice(Object price) {
    return 'from ₹$price';
  }

  @override
  String get verified => 'Verified';

  @override
  String get newWorker => 'New';

  @override
  String noWorkersFound(Object category) {
    return 'No ${category}s found';
  }

  @override
  String get tryDifferentCategory =>
      'Try a different category or check back soon - new workers join every day.';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get help => 'Help & FAQ';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get marathi => 'Marathi';

  @override
  String get version => 'Version';

  @override
  String get emergency => 'Emergency';

  @override
  String get urgent => 'Urgent';

  @override
  String get urgentTag => 'URGENT - Need within 30 minutes';

  @override
  String get favorites => 'Favorites';

  @override
  String get addToFavorites => 'Add to Favorites';

  @override
  String get removeFromFavorites => 'Remove from Favorites';

  @override
  String get jobHistory => 'Job History';

  @override
  String get downloadReceipt => 'Download Receipt';

  @override
  String get shareBooking => 'Share Booking';

  @override
  String get shareViaWhatsApp => 'Share via WhatsApp';

  @override
  String get workerOnTheWay => 'Worker is on the way!';

  @override
  String get workerArrived => 'Worker has arrived';

  @override
  String get workStarted => 'Work started';

  @override
  String get jobCompleted => 'Job completed';

  @override
  String get confirmCompletion => 'Confirm Completion';

  @override
  String get tipWorker => 'Tip Worker';

  @override
  String get tipAmount => 'Tip Amount';

  @override
  String get thankYou => 'Thank you!';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get offline => 'You\'re offline';

  @override
  String get checkConnection => 'Check your internet connection and try again';

  @override
  String get serverError => 'Could not reach the server';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get locationPermission =>
      'Location permission needed for distance sorting';

  @override
  String get cameraPermission => 'Camera permission needed for photos';

  @override
  String get storagePermission => 'Storage permission needed for media';

  @override
  String get workerDashboard => 'Dashboard';

  @override
  String get newJobs => 'New Jobs';

  @override
  String get activeJobs => 'Active Jobs';

  @override
  String get completedJobs => 'Completed Jobs';

  @override
  String get earningsToday => 'Today\'s Earnings';

  @override
  String get earningsWeek => 'This Week';

  @override
  String get earningsMonth => 'This Month';

  @override
  String get acceptJob => 'Accept';

  @override
  String get declineJob => 'Decline';

  @override
  String get startTraveling => 'Start Traveling';

  @override
  String get markArrived => 'Mark Arrived';

  @override
  String get startWork => 'Start Work';

  @override
  String get completeWork => 'Complete Work';

  @override
  String get shareLocation => 'Share Live Location';

  @override
  String get stopSharingLocation => 'Stop Sharing Location';

  @override
  String get locationShared => 'Location shared with client';

  @override
  String get locationStopped => 'Location sharing stopped';

  @override
  String get workerProfile => 'Worker Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get availability => 'Availability';

  @override
  String get available => 'Available';

  @override
  String get notAvailable => 'Not Available';

  @override
  String get skills => 'Skills';

  @override
  String get bio => 'Bio';

  @override
  String get priceRange => 'Price Range';

  @override
  String get minPrice => 'Min Price';

  @override
  String get maxPrice => 'Max Price';

  @override
  String get portfolio => 'Portfolio';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get aadharFront => 'Aadhar Front';

  @override
  String get aadharBack => 'Aadhar Back';

  @override
  String get submitForApproval => 'Submit for Approval';

  @override
  String get underReview => 'Under Review';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get rejectionReason => 'Rejection Reason';

  @override
  String get paymentSetup => 'Payment Setup';

  @override
  String get upiId => 'UPI ID';

  @override
  String get bankAccount => 'Bank Account';

  @override
  String get ifsc => 'IFSC';

  @override
  String get accountHolder => 'Account Holder';

  @override
  String get save => 'Save';

  @override
  String get adminConsole => 'Admin Console';

  @override
  String get pendingWorkers => 'Pending Workers';

  @override
  String get approveWorker => 'Approve Worker';

  @override
  String get rejectWorker => 'Reject Worker';

  @override
  String get wrongApp => 'Wrong App';

  @override
  String wrongAppMessage(Object role) {
    return 'This app is for ${role}s only. Please download the correct app.';
  }

  @override
  String get downloadCustomerApp => 'Download KaamWala (Customer)';

  @override
  String get downloadWorkerApp => 'Download KaamWala Partner (Worker)';

  @override
  String get onboardingTitle => 'Welcome to KaamWala';

  @override
  String get onboardingSubtitle => 'Verified workers. Instant booking.';

  @override
  String get onboardingPartnerSubtitle => 'Get jobs near you. Earn every day.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get confirmCompletionTitle => 'Confirm Job Completion';

  @override
  String get confirmCompletionMessage =>
      'Has the worker completed the job to your satisfaction?';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get ratingSubmitted => 'Rating submitted!';

  @override
  String get thankYouForRating => 'Thank you for your feedback.';

  @override
  String get paymentSuccess => 'Payment Successful';

  @override
  String get paymentFailed => 'Payment Failed';

  @override
  String get orderCreated => 'Order Created';

  @override
  String get refundInitiated => 'Refund Initiated';

  @override
  String get refundProcessing => 'Refund is processing...';

  @override
  String get payoutPending => 'Payout Pending';

  @override
  String get payoutProcessing => 'Payout Processing';

  @override
  String get payoutSuccess => 'Payout Successful';

  @override
  String get payoutFailed => 'Payout Failed';

  @override
  String get liveLocation => 'Live Location';

  @override
  String get workerLocation => 'Worker Location';

  @override
  String get yourLocation => 'Your Location';

  @override
  String get tracking => 'Tracking...';

  @override
  String get stopTracking => 'Stop Tracking';

  @override
  String get jobDescription => 'Job Description';

  @override
  String get bookingRef => 'Booking Reference';

  @override
  String get bookingDate => 'Booking Date';

  @override
  String get bookingTime => 'Booking Time';

  @override
  String get workerName => 'Worker Name';

  @override
  String get clientName => 'Client Name';

  @override
  String get callWorker => 'Call Worker';

  @override
  String get callClient => 'Call Client';

  @override
  String get viewOnMap => 'View on Map';

  @override
  String get directions => 'Directions';

  @override
  String get shareLocationWithWorker => 'Share Location with Worker';

  @override
  String get workerWillSeeYourLocation => 'Worker will see your location';

  @override
  String get bookingPhotos => 'Booking Photos';

  @override
  String get viewPhotos => 'View Photos';

  @override
  String get noPhotos => 'No photos uploaded';

  @override
  String get photoUploaded => 'Photo uploaded';

  @override
  String get videoUploaded => 'Video uploaded';

  @override
  String get mediaUploaded => 'Media uploaded';

  @override
  String get selectMedia => 'Select photos/videos';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get remove => 'Remove';

  @override
  String get clearAll => 'Clear All';

  @override
  String get done => 'Done';

  @override
  String get apply => 'Apply';

  @override
  String get filter => 'Filter';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get category => 'Category';

  @override
  String get allCategories => 'All Categories';

  @override
  String get plumber => 'Plumber';

  @override
  String get electrician => 'Electrician';

  @override
  String get painter => 'Painter';

  @override
  String get carpenter => 'Carpenter';

  @override
  String get workerList => 'Workers';

  @override
  String get topRatedNearYou => 'Top Rated Near You';

  @override
  String get seeAll => 'See All';

  @override
  String get bookAgain => 'Book Again';

  @override
  String get recentlyBooked => 'Recently Booked';

  @override
  String get favoriteWorkers => 'Favorite Workers';

  @override
  String get noFavorites => 'No favorite workers yet';

  @override
  String get addWorkersToFavorites =>
      'Add workers to favorites from their profile';

  @override
  String get recurringBooking => 'Recurring Booking';

  @override
  String get scheduleRecurring => 'Schedule Recurring Service';

  @override
  String get frequency => 'Frequency';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get quarterly => 'Quarterly';

  @override
  String get custom => 'Custom';

  @override
  String get servicePackages => 'Service Packages';

  @override
  String get packageDetails => 'Package Details';

  @override
  String get bookPackage => 'Book Package';

  @override
  String get warranty => 'Warranty';

  @override
  String get warrantyPeriod => 'Warranty Period';

  @override
  String get days30 => '30 Days';

  @override
  String get days90 => '90 Days';

  @override
  String get days180 => '180 Days';

  @override
  String get guarantee => 'Guarantee';

  @override
  String get workGuarantee => 'Work Guarantee';

  @override
  String get emergencySurcharge => 'Emergency Surcharge';

  @override
  String get extraForUrgent => 'Extra for urgent service';

  @override
  String get multiWorkerBooking => 'Multi-Worker Booking';

  @override
  String get addAnotherWorker => 'Add Another Worker';

  @override
  String get bundleDiscount => 'Bundle Discount';

  @override
  String get structuredQuote => 'Structured Quote';

  @override
  String get sendQuote => 'Send Quote';

  @override
  String get acceptQuote => 'Accept Quote';

  @override
  String get rejectQuote => 'Reject Quote';

  @override
  String get quoteAmount => 'Quote Amount';

  @override
  String get quoteDetails => 'Quote Details';

  @override
  String get negotiatePrice => 'Negotiate Price';

  @override
  String get finalPrice => 'Final Price';

  @override
  String get agreedPrice => 'Agreed Price';

  @override
  String get priceAgreed => 'Price Agreed';

  @override
  String get paymentAfterWork => 'Payment After Work';

  @override
  String get payAfterConfirmation => 'Pay after work confirmation';

  @override
  String get holdMoney => 'Money held until you confirm';

  @override
  String get refundPolicy => 'Refund Policy';

  @override
  String get fullRefundIfCancelled => 'Full refund if cancelled while pending';

  @override
  String get partialRefund => 'Partial refund after worker accepts';

  @override
  String get noRefundAfterStart => 'No refund after work starts';

  @override
  String get support => 'Support';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get faq => 'FAQ';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get about => 'About';

  @override
  String get aboutKaamWala => 'About KaamWala';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get pune => 'Pune';

  @override
  String get maharashtra => 'Maharashtra';

  @override
  String get india => 'India';

  @override
  String get loading => 'Loading...';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get noInternet => 'No Internet Connection';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get unknownError => 'Unknown error occurred';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Information';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get continueBtn => 'Continue';

  @override
  String get finish => 'Finish';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get discardChanges => 'Discard Changes';

  @override
  String get unsavedChanges =>
      'You have unsaved changes. Are you sure you want to leave?';

  @override
  String get leave => 'Leave';

  @override
  String get stay => 'Stay';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get view => 'View';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied!';

  @override
  String get share => 'Share';

  @override
  String get download => 'Download';

  @override
  String get print => 'Print';

  @override
  String get refresh => 'Refresh';

  @override
  String get searchHint => 'Search...';

  @override
  String get noResults => 'No results found';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get swipeToRefresh => 'Swipe to refresh';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(Object minutes) {
    return '$minutes minutes ago';
  }

  @override
  String hoursAgo(Object hours) {
    return '$hours hours ago';
  }

  @override
  String daysAgo(Object days) {
    return '$days days ago';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get thisWeek => 'This Week';

  @override
  String get lastWeek => 'Last Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get lastMonth => 'Last Month';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get am => 'AM';

  @override
  String get pm => 'PM';

  @override
  String get rupee => '₹';

  @override
  String currencyFormat(Object amount) {
    return '₹$amount';
  }

  @override
  String get thousand => 'K';

  @override
  String get lakh => 'L';

  @override
  String get crore => 'Cr';

  @override
  String get percent => '%';

  @override
  String ratingOutOf5(Object rating) {
    return '$rating/5';
  }

  @override
  String reviewsCount(Object count) {
    return '$count reviews';
  }

  @override
  String ratingCount(Object count) {
    return '$count ratings';
  }

  @override
  String get highlyRated => 'Highly Rated';

  @override
  String get popular => 'Popular';

  @override
  String get recommended => 'Recommended';

  @override
  String get trending => 'Trending';

  @override
  String get newItem => 'New';

  @override
  String get featured => 'Featured';

  @override
  String get exclusive => 'Exclusive';

  @override
  String get limitedTime => 'Limited Time';

  @override
  String get offer => 'Offer';

  @override
  String get discount => 'Discount';

  @override
  String get coupon => 'Coupon';

  @override
  String get promoCode => 'Promo Code';

  @override
  String get applyCoupon => 'Apply Coupon';

  @override
  String get couponApplied => 'Coupon Applied';

  @override
  String get invalidCoupon => 'Invalid Coupon';

  @override
  String get couponExpired => 'Coupon Expired';

  @override
  String get freeBooking => 'Free Booking';

  @override
  String get firstBookingFree => 'First Booking Free';

  @override
  String get referralBonus => 'Referral Bonus';

  @override
  String get inviteFriends => 'Invite Friends';

  @override
  String get shareApp => 'Share App';

  @override
  String get rateApp => 'Rate App';

  @override
  String get feedback => 'Feedback';

  @override
  String get suggestFeature => 'Suggest Feature';

  @override
  String get reportBug => 'Report Bug';

  @override
  String get appVersion => 'App Version';

  @override
  String get buildNumber => 'Build Number';

  @override
  String get deviceInfo => 'Device Info';

  @override
  String get osVersion => 'OS Version';

  @override
  String get networkInfo => 'Network Info';

  @override
  String get debugInfo => 'Debug Info';

  @override
  String get logs => 'Logs';

  @override
  String get clearLogs => 'Clear Logs';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get crashReport => 'Crash Report';

  @override
  String get sendCrashReport => 'Send Crash Report';

  @override
  String get analytics => 'Analytics';

  @override
  String get events => 'Events';

  @override
  String get users => 'Users';

  @override
  String get sessions => 'Sessions';

  @override
  String get retention => 'Retention';

  @override
  String get conversion => 'Conversion';

  @override
  String get revenue => 'Revenue';

  @override
  String get bookingsCount => 'Bookings';

  @override
  String get workersCount => 'Workers';

  @override
  String get activeUsers => 'Active Users';

  @override
  String get churnRate => 'Churn Rate';

  @override
  String get ltv => 'LTV';

  @override
  String get cac => 'CAC';

  @override
  String get roi => 'ROI';
}
