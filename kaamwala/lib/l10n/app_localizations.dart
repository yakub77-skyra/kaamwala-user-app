import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'KaamWala'**
  String get appName;

  /// No description provided for @appNamePartner.
  ///
  /// In en, this message translates to:
  /// **'KaamWala Partner'**
  String get appNamePartner;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneNumber;

  /// No description provided for @sendOTP.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOTP;

  /// No description provided for @otp.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get otp;

  /// No description provided for @enterOTP.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOTP;

  /// No description provided for @verifyOTP.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOTP;

  /// No description provided for @resendOTP.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOTP;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(Object seconds);

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterName;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select your city'**
  String get selectCity;

  /// No description provided for @roleSelection.
  ///
  /// In en, this message translates to:
  /// **'Who are you?'**
  String get roleSelection;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'I need a worker'**
  String get customer;

  /// No description provided for @worker.
  ///
  /// In en, this message translates to:
  /// **'I am a worker'**
  String get worker;

  /// No description provided for @bookWorker.
  ///
  /// In en, this message translates to:
  /// **'Book Worker'**
  String get bookWorker;

  /// No description provided for @whatWork.
  ///
  /// In en, this message translates to:
  /// **'What work do you need?'**
  String get whatWork;

  /// No description provided for @describeWork.
  ///
  /// In en, this message translates to:
  /// **'Describe the work...'**
  String get describeWork;

  /// No description provided for @when.
  ///
  /// In en, this message translates to:
  /// **'When?'**
  String get when;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @timeSlot.
  ///
  /// In en, this message translates to:
  /// **'Time Slot'**
  String get timeSlot;

  /// No description provided for @where.
  ///
  /// In en, this message translates to:
  /// **'Where?'**
  String get where;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @enterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your full address'**
  String get enterAddress;

  /// No description provided for @jobEstimate.
  ///
  /// In en, this message translates to:
  /// **'Job Estimate'**
  String get jobEstimate;

  /// No description provided for @bookingFee.
  ///
  /// In en, this message translates to:
  /// **'Booking Fee (refundable)'**
  String get bookingFee;

  /// No description provided for @finalPriceNote.
  ///
  /// In en, this message translates to:
  /// **'Final price is agreed with the worker before work starts.'**
  String get finalPriceNote;

  /// No description provided for @payAndBook.
  ///
  /// In en, this message translates to:
  /// **'Pay ₹{amount} & Book'**
  String payAndBook(Object amount);

  /// No description provided for @creatingBooking.
  ///
  /// In en, this message translates to:
  /// **'Creating booking...'**
  String get creatingBooking;

  /// No description provided for @cancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime while pending = full refund'**
  String get cancelAnytime;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// No description provided for @noBookings.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get noBookings;

  /// No description provided for @bookingDetail.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get bookingDetail;

  /// No description provided for @workerDetails.
  ///
  /// In en, this message translates to:
  /// **'Worker Details'**
  String get workerDetails;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @traveling.
  ///
  /// In en, this message translates to:
  /// **'Traveling'**
  String get traveling;

  /// No description provided for @arrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get arrived;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBooking;

  /// No description provided for @confirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking?'**
  String get confirmCancel;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @noKeep.
  ///
  /// In en, this message translates to:
  /// **'No, Keep'**
  String get noKeep;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @rateReview.
  ///
  /// In en, this message translates to:
  /// **'Rate & Review'**
  String get rateReview;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos/videos (optional)'**
  String get addPhotos;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @maxPhotos.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 photos/videos allowed'**
  String get maxPhotos;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload media'**
  String get uploadFailed;

  /// No description provided for @searchWorkers.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get searchWorkers;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @topRated.
  ///
  /// In en, this message translates to:
  /// **'Top rated first'**
  String get topRated;

  /// No description provided for @priceLowHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get priceLowHigh;

  /// No description provided for @priceHighLow.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get priceHighLow;

  /// No description provided for @nearestFirst.
  ///
  /// In en, this message translates to:
  /// **'Nearest first'**
  String get nearestFirst;

  /// No description provided for @enableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable location for distance sorting'**
  String get enableLocation;

  /// No description provided for @availableNow.
  ///
  /// In en, this message translates to:
  /// **'Available now'**
  String get availableNow;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String distance(Object distance);

  /// No description provided for @fromPrice.
  ///
  /// In en, this message translates to:
  /// **'from ₹{price}'**
  String fromPrice(Object price);

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @newWorker.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newWorker;

  /// No description provided for @noWorkersFound.
  ///
  /// In en, this message translates to:
  /// **'No {category}s found'**
  String noWorkersFound(Object category);

  /// No description provided for @tryDifferentCategory.
  ///
  /// In en, this message translates to:
  /// **'Try a different category or check back soon - new workers join every day.'**
  String get tryDifferentCategory;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get help;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'Marathi'**
  String get marathi;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @urgentTag.
  ///
  /// In en, this message translates to:
  /// **'URGENT - Need within 30 minutes'**
  String get urgentTag;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// No description provided for @jobHistory.
  ///
  /// In en, this message translates to:
  /// **'Job History'**
  String get jobHistory;

  /// No description provided for @downloadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Download Receipt'**
  String get downloadReceipt;

  /// No description provided for @shareBooking.
  ///
  /// In en, this message translates to:
  /// **'Share Booking'**
  String get shareBooking;

  /// No description provided for @shareViaWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Share via WhatsApp'**
  String get shareViaWhatsApp;

  /// No description provided for @workerOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Worker is on the way!'**
  String get workerOnTheWay;

  /// No description provided for @workerArrived.
  ///
  /// In en, this message translates to:
  /// **'Worker has arrived'**
  String get workerArrived;

  /// No description provided for @workStarted.
  ///
  /// In en, this message translates to:
  /// **'Work started'**
  String get workStarted;

  /// No description provided for @jobCompleted.
  ///
  /// In en, this message translates to:
  /// **'Job completed'**
  String get jobCompleted;

  /// No description provided for @confirmCompletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Completion'**
  String get confirmCompletion;

  /// No description provided for @tipWorker.
  ///
  /// In en, this message translates to:
  /// **'Tip Worker'**
  String get tipWorker;

  /// No description provided for @tipAmount.
  ///
  /// In en, this message translates to:
  /// **'Tip Amount'**
  String get tipAmount;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get thankYou;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offline;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again'**
  String get checkConnection;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server'**
  String get serverError;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @locationPermission.
  ///
  /// In en, this message translates to:
  /// **'Location permission needed for distance sorting'**
  String get locationPermission;

  /// No description provided for @cameraPermission.
  ///
  /// In en, this message translates to:
  /// **'Camera permission needed for photos'**
  String get cameraPermission;

  /// No description provided for @storagePermission.
  ///
  /// In en, this message translates to:
  /// **'Storage permission needed for media'**
  String get storagePermission;

  /// No description provided for @workerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get workerDashboard;

  /// No description provided for @newJobs.
  ///
  /// In en, this message translates to:
  /// **'New Jobs'**
  String get newJobs;

  /// No description provided for @activeJobs.
  ///
  /// In en, this message translates to:
  /// **'Active Jobs'**
  String get activeJobs;

  /// No description provided for @completedJobs.
  ///
  /// In en, this message translates to:
  /// **'Completed Jobs'**
  String get completedJobs;

  /// No description provided for @earningsToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Earnings'**
  String get earningsToday;

  /// No description provided for @earningsWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get earningsWeek;

  /// No description provided for @earningsMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get earningsMonth;

  /// No description provided for @acceptJob.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptJob;

  /// No description provided for @declineJob.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineJob;

  /// No description provided for @startTraveling.
  ///
  /// In en, this message translates to:
  /// **'Start Traveling'**
  String get startTraveling;

  /// No description provided for @markArrived.
  ///
  /// In en, this message translates to:
  /// **'Mark Arrived'**
  String get markArrived;

  /// No description provided for @startWork.
  ///
  /// In en, this message translates to:
  /// **'Start Work'**
  String get startWork;

  /// No description provided for @completeWork.
  ///
  /// In en, this message translates to:
  /// **'Complete Work'**
  String get completeWork;

  /// No description provided for @shareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share Live Location'**
  String get shareLocation;

  /// No description provided for @stopSharingLocation.
  ///
  /// In en, this message translates to:
  /// **'Stop Sharing Location'**
  String get stopSharingLocation;

  /// No description provided for @locationShared.
  ///
  /// In en, this message translates to:
  /// **'Location shared with client'**
  String get locationShared;

  /// No description provided for @locationStopped.
  ///
  /// In en, this message translates to:
  /// **'Location sharing stopped'**
  String get locationStopped;

  /// No description provided for @workerProfile.
  ///
  /// In en, this message translates to:
  /// **'Worker Profile'**
  String get workerProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min Price'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get maxPrice;

  /// No description provided for @portfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolio;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @aadharFront.
  ///
  /// In en, this message translates to:
  /// **'Aadhar Front'**
  String get aadharFront;

  /// No description provided for @aadharBack.
  ///
  /// In en, this message translates to:
  /// **'Aadhar Back'**
  String get aadharBack;

  /// No description provided for @submitForApproval.
  ///
  /// In en, this message translates to:
  /// **'Submit for Approval'**
  String get submitForApproval;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason'**
  String get rejectionReason;

  /// No description provided for @paymentSetup.
  ///
  /// In en, this message translates to:
  /// **'Payment Setup'**
  String get paymentSetup;

  /// No description provided for @upiId.
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get upiId;

  /// No description provided for @bankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get bankAccount;

  /// No description provided for @ifsc.
  ///
  /// In en, this message translates to:
  /// **'IFSC'**
  String get ifsc;

  /// No description provided for @accountHolder.
  ///
  /// In en, this message translates to:
  /// **'Account Holder'**
  String get accountHolder;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @adminConsole.
  ///
  /// In en, this message translates to:
  /// **'Admin Console'**
  String get adminConsole;

  /// No description provided for @pendingWorkers.
  ///
  /// In en, this message translates to:
  /// **'Pending Workers'**
  String get pendingWorkers;

  /// No description provided for @approveWorker.
  ///
  /// In en, this message translates to:
  /// **'Approve Worker'**
  String get approveWorker;

  /// No description provided for @rejectWorker.
  ///
  /// In en, this message translates to:
  /// **'Reject Worker'**
  String get rejectWorker;

  /// No description provided for @wrongApp.
  ///
  /// In en, this message translates to:
  /// **'Wrong App'**
  String get wrongApp;

  /// No description provided for @wrongAppMessage.
  ///
  /// In en, this message translates to:
  /// **'This app is for {role}s only. Please download the correct app.'**
  String wrongAppMessage(Object role);

  /// No description provided for @downloadCustomerApp.
  ///
  /// In en, this message translates to:
  /// **'Download KaamWala (Customer)'**
  String get downloadCustomerApp;

  /// No description provided for @downloadWorkerApp.
  ///
  /// In en, this message translates to:
  /// **'Download KaamWala Partner (Worker)'**
  String get downloadWorkerApp;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to KaamWala'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verified workers. Instant booking.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingPartnerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get jobs near you. Earn every day.'**
  String get onboardingPartnerSubtitle;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @confirmCompletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Job Completion'**
  String get confirmCompletionTitle;

  /// No description provided for @confirmCompletionMessage.
  ///
  /// In en, this message translates to:
  /// **'Has the worker completed the job to your satisfaction?'**
  String get confirmCompletionMessage;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ratingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Rating submitted!'**
  String get ratingSubmitted;

  /// No description provided for @thankYouForRating.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback.'**
  String get thankYouForRating;

  /// No description provided for @paymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful'**
  String get paymentSuccess;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get paymentFailed;

  /// No description provided for @orderCreated.
  ///
  /// In en, this message translates to:
  /// **'Order Created'**
  String get orderCreated;

  /// No description provided for @refundInitiated.
  ///
  /// In en, this message translates to:
  /// **'Refund Initiated'**
  String get refundInitiated;

  /// No description provided for @refundProcessing.
  ///
  /// In en, this message translates to:
  /// **'Refund is processing...'**
  String get refundProcessing;

  /// No description provided for @payoutPending.
  ///
  /// In en, this message translates to:
  /// **'Payout Pending'**
  String get payoutPending;

  /// No description provided for @payoutProcessing.
  ///
  /// In en, this message translates to:
  /// **'Payout Processing'**
  String get payoutProcessing;

  /// No description provided for @payoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payout Successful'**
  String get payoutSuccess;

  /// No description provided for @payoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Payout Failed'**
  String get payoutFailed;

  /// No description provided for @liveLocation.
  ///
  /// In en, this message translates to:
  /// **'Live Location'**
  String get liveLocation;

  /// No description provided for @workerLocation.
  ///
  /// In en, this message translates to:
  /// **'Worker Location'**
  String get workerLocation;

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your Location'**
  String get yourLocation;

  /// No description provided for @tracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking...'**
  String get tracking;

  /// No description provided for @stopTracking.
  ///
  /// In en, this message translates to:
  /// **'Stop Tracking'**
  String get stopTracking;

  /// No description provided for @jobDescription.
  ///
  /// In en, this message translates to:
  /// **'Job Description'**
  String get jobDescription;

  /// No description provided for @bookingRef.
  ///
  /// In en, this message translates to:
  /// **'Booking Reference'**
  String get bookingRef;

  /// No description provided for @bookingDate.
  ///
  /// In en, this message translates to:
  /// **'Booking Date'**
  String get bookingDate;

  /// No description provided for @bookingTime.
  ///
  /// In en, this message translates to:
  /// **'Booking Time'**
  String get bookingTime;

  /// No description provided for @workerName.
  ///
  /// In en, this message translates to:
  /// **'Worker Name'**
  String get workerName;

  /// No description provided for @clientName.
  ///
  /// In en, this message translates to:
  /// **'Client Name'**
  String get clientName;

  /// No description provided for @callWorker.
  ///
  /// In en, this message translates to:
  /// **'Call Worker'**
  String get callWorker;

  /// No description provided for @callClient.
  ///
  /// In en, this message translates to:
  /// **'Call Client'**
  String get callClient;

  /// No description provided for @viewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on Map'**
  String get viewOnMap;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @shareLocationWithWorker.
  ///
  /// In en, this message translates to:
  /// **'Share Location with Worker'**
  String get shareLocationWithWorker;

  /// No description provided for @workerWillSeeYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Worker will see your location'**
  String get workerWillSeeYourLocation;

  /// No description provided for @bookingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Booking Photos'**
  String get bookingPhotos;

  /// No description provided for @viewPhotos.
  ///
  /// In en, this message translates to:
  /// **'View Photos'**
  String get viewPhotos;

  /// No description provided for @noPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos uploaded'**
  String get noPhotos;

  /// No description provided for @photoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Photo uploaded'**
  String get photoUploaded;

  /// No description provided for @videoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Video uploaded'**
  String get videoUploaded;

  /// No description provided for @mediaUploaded.
  ///
  /// In en, this message translates to:
  /// **'Media uploaded'**
  String get mediaUploaded;

  /// No description provided for @selectMedia.
  ///
  /// In en, this message translates to:
  /// **'Select photos/videos'**
  String get selectMedia;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @plumber.
  ///
  /// In en, this message translates to:
  /// **'Plumber'**
  String get plumber;

  /// No description provided for @electrician.
  ///
  /// In en, this message translates to:
  /// **'Electrician'**
  String get electrician;

  /// No description provided for @painter.
  ///
  /// In en, this message translates to:
  /// **'Painter'**
  String get painter;

  /// No description provided for @carpenter.
  ///
  /// In en, this message translates to:
  /// **'Carpenter'**
  String get carpenter;

  /// No description provided for @workerList.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get workerList;

  /// No description provided for @topRatedNearYou.
  ///
  /// In en, this message translates to:
  /// **'Top Rated Near You'**
  String get topRatedNearYou;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @bookAgain.
  ///
  /// In en, this message translates to:
  /// **'Book Again'**
  String get bookAgain;

  /// No description provided for @recentlyBooked.
  ///
  /// In en, this message translates to:
  /// **'Recently Booked'**
  String get recentlyBooked;

  /// No description provided for @favoriteWorkers.
  ///
  /// In en, this message translates to:
  /// **'Favorite Workers'**
  String get favoriteWorkers;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorite workers yet'**
  String get noFavorites;

  /// No description provided for @addWorkersToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add workers to favorites from their profile'**
  String get addWorkersToFavorites;

  /// No description provided for @recurringBooking.
  ///
  /// In en, this message translates to:
  /// **'Recurring Booking'**
  String get recurringBooking;

  /// No description provided for @scheduleRecurring.
  ///
  /// In en, this message translates to:
  /// **'Schedule Recurring Service'**
  String get scheduleRecurring;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @quarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get quarterly;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @servicePackages.
  ///
  /// In en, this message translates to:
  /// **'Service Packages'**
  String get servicePackages;

  /// No description provided for @packageDetails.
  ///
  /// In en, this message translates to:
  /// **'Package Details'**
  String get packageDetails;

  /// No description provided for @bookPackage.
  ///
  /// In en, this message translates to:
  /// **'Book Package'**
  String get bookPackage;

  /// No description provided for @warranty.
  ///
  /// In en, this message translates to:
  /// **'Warranty'**
  String get warranty;

  /// No description provided for @warrantyPeriod.
  ///
  /// In en, this message translates to:
  /// **'Warranty Period'**
  String get warrantyPeriod;

  /// No description provided for @days30.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get days30;

  /// No description provided for @days90.
  ///
  /// In en, this message translates to:
  /// **'90 Days'**
  String get days90;

  /// No description provided for @days180.
  ///
  /// In en, this message translates to:
  /// **'180 Days'**
  String get days180;

  /// No description provided for @guarantee.
  ///
  /// In en, this message translates to:
  /// **'Guarantee'**
  String get guarantee;

  /// No description provided for @workGuarantee.
  ///
  /// In en, this message translates to:
  /// **'Work Guarantee'**
  String get workGuarantee;

  /// No description provided for @emergencySurcharge.
  ///
  /// In en, this message translates to:
  /// **'Emergency Surcharge'**
  String get emergencySurcharge;

  /// No description provided for @extraForUrgent.
  ///
  /// In en, this message translates to:
  /// **'Extra for urgent service'**
  String get extraForUrgent;

  /// No description provided for @multiWorkerBooking.
  ///
  /// In en, this message translates to:
  /// **'Multi-Worker Booking'**
  String get multiWorkerBooking;

  /// No description provided for @addAnotherWorker.
  ///
  /// In en, this message translates to:
  /// **'Add Another Worker'**
  String get addAnotherWorker;

  /// No description provided for @bundleDiscount.
  ///
  /// In en, this message translates to:
  /// **'Bundle Discount'**
  String get bundleDiscount;

  /// No description provided for @structuredQuote.
  ///
  /// In en, this message translates to:
  /// **'Structured Quote'**
  String get structuredQuote;

  /// No description provided for @sendQuote.
  ///
  /// In en, this message translates to:
  /// **'Send Quote'**
  String get sendQuote;

  /// No description provided for @acceptQuote.
  ///
  /// In en, this message translates to:
  /// **'Accept Quote'**
  String get acceptQuote;

  /// No description provided for @rejectQuote.
  ///
  /// In en, this message translates to:
  /// **'Reject Quote'**
  String get rejectQuote;

  /// No description provided for @quoteAmount.
  ///
  /// In en, this message translates to:
  /// **'Quote Amount'**
  String get quoteAmount;

  /// No description provided for @quoteDetails.
  ///
  /// In en, this message translates to:
  /// **'Quote Details'**
  String get quoteDetails;

  /// No description provided for @negotiatePrice.
  ///
  /// In en, this message translates to:
  /// **'Negotiate Price'**
  String get negotiatePrice;

  /// No description provided for @finalPrice.
  ///
  /// In en, this message translates to:
  /// **'Final Price'**
  String get finalPrice;

  /// No description provided for @agreedPrice.
  ///
  /// In en, this message translates to:
  /// **'Agreed Price'**
  String get agreedPrice;

  /// No description provided for @priceAgreed.
  ///
  /// In en, this message translates to:
  /// **'Price Agreed'**
  String get priceAgreed;

  /// No description provided for @paymentAfterWork.
  ///
  /// In en, this message translates to:
  /// **'Payment After Work'**
  String get paymentAfterWork;

  /// No description provided for @payAfterConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Pay after work confirmation'**
  String get payAfterConfirmation;

  /// No description provided for @holdMoney.
  ///
  /// In en, this message translates to:
  /// **'Money held until you confirm'**
  String get holdMoney;

  /// No description provided for @refundPolicy.
  ///
  /// In en, this message translates to:
  /// **'Refund Policy'**
  String get refundPolicy;

  /// No description provided for @fullRefundIfCancelled.
  ///
  /// In en, this message translates to:
  /// **'Full refund if cancelled while pending'**
  String get fullRefundIfCancelled;

  /// No description provided for @partialRefund.
  ///
  /// In en, this message translates to:
  /// **'Partial refund after worker accepts'**
  String get partialRefund;

  /// No description provided for @noRefundAfterStart.
  ///
  /// In en, this message translates to:
  /// **'No refund after work starts'**
  String get noRefundAfterStart;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutKaamWala.
  ///
  /// In en, this message translates to:
  /// **'About KaamWala'**
  String get aboutKaamWala;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @pune.
  ///
  /// In en, this message translates to:
  /// **'Pune'**
  String get pune;

  /// No description provided for @maharashtra.
  ///
  /// In en, this message translates to:
  /// **'Maharashtra'**
  String get maharashtra;

  /// No description provided for @india.
  ///
  /// In en, this message translates to:
  /// **'India'**
  String get india;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternet;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get unknownError;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes'**
  String get discardChanges;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to leave?'**
  String get unsavedChanges;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copied;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get pullToRefresh;

  /// No description provided for @swipeToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Swipe to refresh'**
  String get swipeToRefresh;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String minutesAgo(Object minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String hoursAgo(Object hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(Object days);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get lastWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @am.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get am;

  /// No description provided for @pm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pm;

  /// No description provided for @rupee.
  ///
  /// In en, this message translates to:
  /// **'₹'**
  String get rupee;

  /// No description provided for @currencyFormat.
  ///
  /// In en, this message translates to:
  /// **'₹{amount}'**
  String currencyFormat(Object amount);

  /// No description provided for @thousand.
  ///
  /// In en, this message translates to:
  /// **'K'**
  String get thousand;

  /// No description provided for @lakh.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get lakh;

  /// No description provided for @crore.
  ///
  /// In en, this message translates to:
  /// **'Cr'**
  String get crore;

  /// No description provided for @percent.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get percent;

  /// No description provided for @ratingOutOf5.
  ///
  /// In en, this message translates to:
  /// **'{rating}/5'**
  String ratingOutOf5(Object rating);

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(Object count);

  /// No description provided for @ratingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ratings'**
  String ratingCount(Object count);

  /// No description provided for @highlyRated.
  ///
  /// In en, this message translates to:
  /// **'Highly Rated'**
  String get highlyRated;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @newItem.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newItem;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @exclusive.
  ///
  /// In en, this message translates to:
  /// **'Exclusive'**
  String get exclusive;

  /// No description provided for @limitedTime.
  ///
  /// In en, this message translates to:
  /// **'Limited Time'**
  String get limitedTime;

  /// No description provided for @offer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get offer;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @coupon.
  ///
  /// In en, this message translates to:
  /// **'Coupon'**
  String get coupon;

  /// No description provided for @promoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo Code'**
  String get promoCode;

  /// No description provided for @applyCoupon.
  ///
  /// In en, this message translates to:
  /// **'Apply Coupon'**
  String get applyCoupon;

  /// No description provided for @couponApplied.
  ///
  /// In en, this message translates to:
  /// **'Coupon Applied'**
  String get couponApplied;

  /// No description provided for @invalidCoupon.
  ///
  /// In en, this message translates to:
  /// **'Invalid Coupon'**
  String get invalidCoupon;

  /// No description provided for @couponExpired.
  ///
  /// In en, this message translates to:
  /// **'Coupon Expired'**
  String get couponExpired;

  /// No description provided for @freeBooking.
  ///
  /// In en, this message translates to:
  /// **'Free Booking'**
  String get freeBooking;

  /// No description provided for @firstBookingFree.
  ///
  /// In en, this message translates to:
  /// **'First Booking Free'**
  String get firstBookingFree;

  /// No description provided for @referralBonus.
  ///
  /// In en, this message translates to:
  /// **'Referral Bonus'**
  String get referralBonus;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @suggestFeature.
  ///
  /// In en, this message translates to:
  /// **'Suggest Feature'**
  String get suggestFeature;

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report Bug'**
  String get reportBug;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @buildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build Number'**
  String get buildNumber;

  /// No description provided for @deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device Info'**
  String get deviceInfo;

  /// No description provided for @osVersion.
  ///
  /// In en, this message translates to:
  /// **'OS Version'**
  String get osVersion;

  /// No description provided for @networkInfo.
  ///
  /// In en, this message translates to:
  /// **'Network Info'**
  String get networkInfo;

  /// No description provided for @debugInfo.
  ///
  /// In en, this message translates to:
  /// **'Debug Info'**
  String get debugInfo;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get clearLogs;

  /// No description provided for @exportLogs.
  ///
  /// In en, this message translates to:
  /// **'Export Logs'**
  String get exportLogs;

  /// No description provided for @crashReport.
  ///
  /// In en, this message translates to:
  /// **'Crash Report'**
  String get crashReport;

  /// No description provided for @sendCrashReport.
  ///
  /// In en, this message translates to:
  /// **'Send Crash Report'**
  String get sendCrashReport;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @retention.
  ///
  /// In en, this message translates to:
  /// **'Retention'**
  String get retention;

  /// No description provided for @conversion.
  ///
  /// In en, this message translates to:
  /// **'Conversion'**
  String get conversion;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @bookingsCount.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookingsCount;

  /// No description provided for @workersCount.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get workersCount;

  /// No description provided for @activeUsers.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get activeUsers;

  /// No description provided for @churnRate.
  ///
  /// In en, this message translates to:
  /// **'Churn Rate'**
  String get churnRate;

  /// No description provided for @ltv.
  ///
  /// In en, this message translates to:
  /// **'LTV'**
  String get ltv;

  /// No description provided for @cac.
  ///
  /// In en, this message translates to:
  /// **'CAC'**
  String get cac;

  /// No description provided for @roi.
  ///
  /// In en, this message translates to:
  /// **'ROI'**
  String get roi;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
