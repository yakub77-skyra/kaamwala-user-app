// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appName => 'कामवाला';

  @override
  String get appNamePartner => 'कामवाला पार्टनर';

  @override
  String get home => 'होम';

  @override
  String get search => 'शोधा';

  @override
  String get bookings => 'बुकिंग्ज';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get earnings => 'कमाई';

  @override
  String get login => 'लॉगिन';

  @override
  String get logout => 'लॉगआऊट';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get enterPhoneNumber => 'तुमचा फोन नंबर टाका';

  @override
  String get sendOTP => 'OTP पाठवा';

  @override
  String get otp => 'OTP';

  @override
  String get enterOTP => 'OTP टाका';

  @override
  String get verifyOTP => 'OTP सत्यापित करा';

  @override
  String get resendOTP => 'OTP पुन्हा पाठवा';

  @override
  String resendIn(Object seconds) {
    return '$seconds सेकंदात पुन्हा पाठवा';
  }

  @override
  String get name => 'नाव';

  @override
  String get enterName => 'तुमचे नाव टाका';

  @override
  String get city => 'शहर';

  @override
  String get selectCity => 'तुमचे शहर निवडा';

  @override
  String get roleSelection => 'तुम्ही कोण आहात?';

  @override
  String get customer => 'मला कामगार हवा आहे';

  @override
  String get worker => 'मी कामगार आहे';

  @override
  String get bookWorker => 'कामगार बुक करा';

  @override
  String get whatWork => 'तुम्हाला काय काम हवा आहे?';

  @override
  String get describeWork => 'कामाचे वर्णन करा...';

  @override
  String get when => 'केव्हा?';

  @override
  String get date => 'तारीख';

  @override
  String get timeSlot => 'वेळ स्लॉट';

  @override
  String get where => 'कुठे?';

  @override
  String get address => 'पत्ता';

  @override
  String get enterAddress => 'पूर्ण पत्ता टाका';

  @override
  String get jobEstimate => 'कामाचा अंदाज';

  @override
  String get bookingFee => 'बुकिंग शुल्क (परत मिळणारा)';

  @override
  String get finalPriceNote =>
      'शेवटची किंमत काम सुरू होण्यापूर्वी कामगारशी ठरते.';

  @override
  String payAndBook(Object amount) {
    return '₹$amount देऊन बुक करा';
  }

  @override
  String get creatingBooking => 'बुकिंग तयार होत आहे...';

  @override
  String get cancelAnytime => 'पेंडिंग असताना कधीही रद्द करा = पूर्ण परतफेड';

  @override
  String get myBookings => 'माझी बुकिंग्ज';

  @override
  String get noBookings => 'अजून कोणतीही बुकिंग नाही';

  @override
  String get bookingDetail => 'बुकिंग तपशील';

  @override
  String get workerDetails => 'कामगारचे तपशील';

  @override
  String get status => 'स्थिती';

  @override
  String get pending => 'प्रलंबित';

  @override
  String get accepted => 'स्वीकारले';

  @override
  String get traveling => 'येऊ शकत आहे';

  @override
  String get arrived => 'पोहोचले';

  @override
  String get inProgress => 'चालू आहे';

  @override
  String get completed => 'पूर्ण झाले';

  @override
  String get cancelled => 'रद्द';

  @override
  String get declined => 'नाकारले';

  @override
  String get cancelBooking => 'बुकिंग रद्द करा';

  @override
  String get confirmCancel => ' तुम्ही खरं हे बुकिंग रद्द करायचं का?';

  @override
  String get yesCancel => 'हो, रद्द करा';

  @override
  String get noKeep => 'नाही, ठेवा';

  @override
  String get chat => 'चॅट';

  @override
  String get message => 'संदेश';

  @override
  String get send => 'पाठवा';

  @override
  String get typeMessage => 'संदेश टाइप करा...';

  @override
  String get rateReview => 'रेटिंग आणि पुनरावलोकन';

  @override
  String get rating => 'रेटिंग';

  @override
  String get review => 'पुनरावलोकन';

  @override
  String get submitReview => 'पुनरावलोकन सबमिट करा';

  @override
  String get addPhotos => 'फोटो/व्हिडिओ जोडा (पर्यायी)';

  @override
  String get gallery => 'गॅलरी';

  @override
  String get camera => 'कॅमेरा';

  @override
  String get maxPhotos => 'कमाल 5 फोटो/व्हिडिओ परवानगी';

  @override
  String get uploadFailed => 'मिडिया अपलोड करण्यात अयशस्वी';

  @override
  String get searchWorkers => 'नावाने शोधा';

  @override
  String get sortBy => 'क्रमवार करा';

  @override
  String get topRated => 'सर्वात जास्त रेटिंग';

  @override
  String get priceLowHigh => 'किंमत: कमी ते जास्त';

  @override
  String get priceHighLow => 'किंमत: जास्त ते कमी';

  @override
  String get nearestFirst => 'सर्वात जवळचे पहिले';

  @override
  String get enableLocation => 'अंतर क्रमासाठी स्थान चालू करा';

  @override
  String get availableNow => 'आता उपलब्ध';

  @override
  String distance(Object distance) {
    return '$distance किमी अंतर';
  }

  @override
  String fromPrice(Object price) {
    return '₹$price पासून सुरू';
  }

  @override
  String get verified => 'पडताळलेले';

  @override
  String get newWorker => 'नवीन';

  @override
  String noWorkersFound(Object category) {
    return 'कोणतेही $category सापडले नाही';
  }

  @override
  String get tryDifferentCategory =>
      'वेगळी श्रेणी प्रयत्न करा किंवा नंतर पहा - नवीन कामगार दररोज येथे येईल.';

  @override
  String get settings => 'सेटिंग्ज';

  @override
  String get notifications => 'सूचना';

  @override
  String get help => 'मदत आणि FAQ';

  @override
  String get language => 'भाषा';

  @override
  String get english => 'इंग्रजी';

  @override
  String get hindi => 'हिंदी';

  @override
  String get marathi => 'मराठी';

  @override
  String get version => 'संस्करण';

  @override
  String get emergency => 'आपत्कालीन';

  @override
  String get urgent => 'शीघ्र';

  @override
  String get urgentTag => 'शीघ्र - 30 मिनिटात हवे आहे';

  @override
  String get favorites => 'आवडते';

  @override
  String get addToFavorites => 'आवडतांमध्ये जोडा';

  @override
  String get removeFromFavorites => 'आवडतांकडून काढा';

  @override
  String get jobHistory => 'कामाचा इतिहास';

  @override
  String get downloadReceipt => 'पावती डाउनलोड करा';

  @override
  String get shareBooking => 'बुकिंग शेअर करा';

  @override
  String get shareViaWhatsApp => 'WhatsApp मार्फत शेअर करा';

  @override
  String get workerOnTheWay => 'कामगार मार्गे आहे!';

  @override
  String get workerArrived => 'कामगार पोहोचला';

  @override
  String get workStarted => 'काम सुरू झाले';

  @override
  String get jobCompleted => 'काम पूर्ण झाले';

  @override
  String get confirmCompletion => 'पूर्ण होण्याची पुष्टी करा';

  @override
  String get tipWorker => 'कामगारला टिप द्या';

  @override
  String get tipAmount => 'टिप रक्कम';

  @override
  String get thankYou => 'धन्यवाद!';

  @override
  String get error => 'त्रुटी';

  @override
  String get retry => 'पुन्हा प्रयत्न करा';

  @override
  String get offline => 'तुम्ही ऑफलाइन आहात';

  @override
  String get checkConnection => 'इंटरनेट कनेक्शन तपासा आणि पुन्हा प्रयत्न करा';

  @override
  String get serverError => 'सर्व्हरशी संपर्क साधू शकले नाही';

  @override
  String get permissionDenied => 'परवानगी नाकारली';

  @override
  String get locationPermission => 'अंतर क्रमासाठी स्थान परवानगी हवी आहे';

  @override
  String get cameraPermission => 'फोटो साठी कॅमेरा परवानगी हवी आहे';

  @override
  String get storagePermission => 'मिडिया साठी स्टोरेज परवानगी हवी आहे';

  @override
  String get workerDashboard => 'डॅशबोर्ड';

  @override
  String get newJobs => 'नवीन काम';

  @override
  String get activeJobs => 'चालू काम';

  @override
  String get completedJobs => 'पूर्ण झालेले काम';

  @override
  String get earningsToday => 'आजची कमाई';

  @override
  String get earningsWeek => 'या आठवडात';

  @override
  String get earningsMonth => 'या महिन्यात';

  @override
  String get acceptJob => 'स्वीकार करा';

  @override
  String get declineJob => 'नाकार द्या';

  @override
  String get startTraveling => 'प्रवास सुरू करा';

  @override
  String get markArrived => 'पोहोचले असे चिन्हांकित करा';

  @override
  String get startWork => 'काम सुरू करा';

  @override
  String get completeWork => 'काम पूर्ण करा';

  @override
  String get shareLocation => 'लाइव स्थान शेअर करा';

  @override
  String get stopSharingLocation => 'स्थान शेअर करणे थांबवा';

  @override
  String get locationShared => 'ग्राहकाशी स्थान शेअर केले';

  @override
  String get locationStopped => 'स्थान शेअर करणे थांबवले';

  @override
  String get workerProfile => 'कामगार प्रोफाइल';

  @override
  String get editProfile => 'प्रोफाइल संपादित करा';

  @override
  String get availability => 'उपलब्धता';

  @override
  String get available => 'उपलब्ध';

  @override
  String get notAvailable => 'उपलब्ध नाही';

  @override
  String get skills => 'कौशल्य';

  @override
  String get bio => 'बायो';

  @override
  String get priceRange => 'किंमतीचा रेंज';

  @override
  String get minPrice => 'कमीतमी किंमत';

  @override
  String get maxPrice => 'जास्तीत जास्त किंमत';

  @override
  String get portfolio => 'पोर्टफोलिओ';

  @override
  String get addPhoto => 'फोटो जोडा';

  @override
  String get aadharFront => 'आधार फ्रंट';

  @override
  String get aadharBack => 'आधार बॅक';

  @override
  String get submitForApproval => 'मान्यतेसाठी सबमिट करा';

  @override
  String get underReview => 'पुनरावलोकनात';

  @override
  String get approved => 'मान्यतप्राप्त';

  @override
  String get rejected => 'नाकारले';

  @override
  String get rejectionReason => 'नाकारल्याचे कारण';

  @override
  String get paymentSetup => 'पेमेंट सेटअप';

  @override
  String get upiId => 'UPI ID';

  @override
  String get bankAccount => 'बँक खाते';

  @override
  String get ifsc => 'IFSC';

  @override
  String get accountHolder => 'खातेधारक';

  @override
  String get save => 'सेव्ह करा';

  @override
  String get adminConsole => 'एडमिन कन्सोल';

  @override
  String get pendingWorkers => 'प्रलंबित कामगार';

  @override
  String get approveWorker => 'कामगार मान्य करा';

  @override
  String get rejectWorker => 'कामगार नाकार द्या';

  @override
  String get wrongApp => 'चुकीचा अॅप';

  @override
  String wrongAppMessage(Object role) {
    return 'हा अॅप फक्त $role साठी आहे. कृपया योग्य अॅप डाउनलोड करा.';
  }

  @override
  String get downloadCustomerApp => 'कामवाला (ग्राहक) डाउनलोड करा';

  @override
  String get downloadWorkerApp => 'कामवाला पार्टनर (कामगार) डाउनलोड करा';

  @override
  String get onboardingTitle => 'कामवाला मध्ये तुमचे स्वागत आहे';

  @override
  String get onboardingSubtitle => 'पडताळलेले कामगार. त्वरित बुकिंग.';

  @override
  String get onboardingPartnerSubtitle =>
      'तुमच्या जवळचे काम मिळवा. दररोज कमवा.';

  @override
  String get skip => 'जावा';

  @override
  String get next => 'पुढे';

  @override
  String get getStarted => 'सुरू करा';

  @override
  String get confirmCompletionTitle => 'काम पूर्ण होण्याची पुष्टी';

  @override
  String get confirmCompletionMessage =>
      'कामगाराने तुमच्या समाधानानुसार काम पूर्ण केले का?';

  @override
  String get confirm => 'पुष्टी करा';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get ratingSubmitted => 'रेटिंग सबमिट झाली!';

  @override
  String get thankYouForRating => 'तुमच्या प्रतिक्रियेसाठी धन्यवाद.';

  @override
  String get paymentSuccess => 'पेमेंट यशस्वी';

  @override
  String get paymentFailed => 'पेमेंट अयशस्वी';

  @override
  String get orderCreated => 'ऑर्डर तयार झाला';

  @override
  String get refundInitiated => 'रिफंड सुरू';

  @override
  String get refundProcessing => 'रिफंड प्रक्रिया चालू आहे...';

  @override
  String get payoutPending => 'पेआउट प्रलंबित';

  @override
  String get payoutProcessing => 'पेआउट प्रक्रिया चालू आहे';

  @override
  String get payoutSuccess => 'पेआउट यशस्वी';

  @override
  String get payoutFailed => 'पेआउट अयशस्वी';

  @override
  String get liveLocation => 'लाइव स्थान';

  @override
  String get workerLocation => 'कामगारचे स्थान';

  @override
  String get yourLocation => 'तुमचे स्थान';

  @override
  String get tracking => 'ट्रॅकिंग...';

  @override
  String get stopTracking => 'ट्रॅकिंग थांबवा';

  @override
  String get jobDescription => 'कामाचे वर्णन';

  @override
  String get bookingRef => 'बुकिंग संदर्भ';

  @override
  String get bookingDate => 'बुकिंग तारीख';

  @override
  String get bookingTime => 'बुकिंग वेळ';

  @override
  String get workerName => 'कामगारचे नाव';

  @override
  String get clientName => 'ग्राहकाचे नाव';

  @override
  String get callWorker => 'कामगारला कॉल करा';

  @override
  String get callClient => 'ग्राहकला कॉल करा';

  @override
  String get viewOnMap => 'नकाशावर पहा';

  @override
  String get directions => 'दिशा';

  @override
  String get shareLocationWithWorker => 'कामगाराबरोबर स्थान शेअर करा';

  @override
  String get workerWillSeeYourLocation => 'कामगार तुमचे स्थान पाहील';

  @override
  String get bookingPhotos => 'बुकिंग फोटो';

  @override
  String get viewPhotos => 'फोटो पहा';

  @override
  String get noPhotos => 'कोणतेही फोटो अपलोड केलेले नाही';

  @override
  String get photoUploaded => 'फोटो अपलोड केले';

  @override
  String get videoUploaded => 'व्हिडिओ अपलोड केले';

  @override
  String get mediaUploaded => 'मिडिया अपलोड केले';

  @override
  String get selectMedia => 'फोटो/व्हिडिओ निवडा';

  @override
  String get takePhoto => 'फोटो घ्या';

  @override
  String get chooseFromGallery => 'गॅलरीमधून निवडा';

  @override
  String get remove => 'काढा';

  @override
  String get clearAll => 'सर्व काढा';

  @override
  String get done => 'झाले';

  @override
  String get apply => 'लागू करा';

  @override
  String get filter => 'फिल्टर';

  @override
  String get clearFilters => 'फिल्टर साफ करा';

  @override
  String get category => 'श्रेणी';

  @override
  String get allCategories => 'सर्व श्रेणी';

  @override
  String get plumber => 'प्लंबर';

  @override
  String get electrician => 'इलेक्ट्रिशियन';

  @override
  String get painter => 'पेंटर';

  @override
  String get carpenter => 'कॅर्पेंटर';

  @override
  String get workerList => 'कामगार';

  @override
  String get topRatedNearYou => 'तुमच्या जवळचे सर्वात जास्त रेटिंग';

  @override
  String get seeAll => 'सर्व पहा';

  @override
  String get bookAgain => 'पुन्हा बुक करा';

  @override
  String get recentlyBooked => 'अजूनच बुक केलेले';

  @override
  String get favoriteWorkers => 'आवडते कामगार';

  @override
  String get noFavorites => 'अजून कोणतेही आवडते कामगार नाही';

  @override
  String get addWorkersToFavorites =>
      'त्यांची प्रोफाइलमधून कामगारांना आवडतांमध्ये जोडा';

  @override
  String get recurringBooking => 'पुनरावर्ती बुकिंग';

  @override
  String get scheduleRecurring => 'पुनरावर्ती सेवा शेड्यूल करा';

  @override
  String get frequency => 'आवृत्ती';

  @override
  String get weekly => 'साप्ताहिक';

  @override
  String get monthly => 'मासिक';

  @override
  String get quarterly => 'त्रैमासिक';

  @override
  String get custom => 'कस्टम';

  @override
  String get servicePackages => 'सेवा संकुल';

  @override
  String get packageDetails => 'संकुल तपशील';

  @override
  String get bookPackage => 'संकुल बुक करा';

  @override
  String get warranty => 'वारंटी';

  @override
  String get warrantyPeriod => 'वारंटी काळ';

  @override
  String get days30 => '30 दिवस';

  @override
  String get days90 => '90 दिवस';

  @override
  String get days180 => '180 दिवस';

  @override
  String get guarantee => 'गॅरंटी';

  @override
  String get workGuarantee => 'कामाची गॅरंटी';

  @override
  String get emergencySurcharge => 'आपत्कालीन अधिभार';

  @override
  String get extraForUrgent => 'शीघ्र सेवेसाठी अतिरिक्त';

  @override
  String get multiWorkerBooking => 'बहु-कामगार बुकिंग';

  @override
  String get addAnotherWorker => 'एक वेगळा कामगार जोडा';

  @override
  String get bundleDiscount => 'बंडल सूट';

  @override
  String get structuredQuote => 'संरचित कोटेशन';

  @override
  String get sendQuote => 'कोटेशन पाठवा';

  @override
  String get acceptQuote => 'कोटेशन स्वीकार करा';

  @override
  String get rejectQuote => 'कोटेशन नाकार द्या';

  @override
  String get quoteAmount => 'कोटेशन रक्कम';

  @override
  String get quoteDetails => 'कोटेशन तपशील';

  @override
  String get negotiatePrice => 'किंमतवर चर्चा करा';

  @override
  String get finalPrice => 'शेवटची किंमत';

  @override
  String get agreedPrice => 'मान्य किंमत';

  @override
  String get priceAgreed => 'किंमत मान्य';

  @override
  String get paymentAfterWork => 'कामानंतर पेमेंट';

  @override
  String get payAfterConfirmation => 'पुष्टीनंतर पेमेंट करा';

  @override
  String get holdMoney => 'पुष्टी पर्यंत पैसा थांबलेले';

  @override
  String get refundPolicy => 'रिफंड धोरण';

  @override
  String get fullRefundIfCancelled =>
      'प्रलंबित असताना रद्द केल्यावर पूर्ण रिफंड';

  @override
  String get partialRefund => 'कामगाराने मान्य केल्यानंतर भागशः रिफंड';

  @override
  String get noRefundAfterStart => 'काम सुरू झाल्यानंतर कोणताही रिफंड नाही';

  @override
  String get support => 'आधार';

  @override
  String get contactSupport => 'आधारशी संपर्क साधा';

  @override
  String get faq => 'FAQ';

  @override
  String get termsOfService => 'सेवा अटी';

  @override
  String get privacyPolicy => 'गोपनीयता धोरण';

  @override
  String get about => 'आमच्याबरोबरच';

  @override
  String get aboutKaamWala => 'कामवाला बद्दल';

  @override
  String get contactUs => 'आमच्याशी संपर्क साधा';

  @override
  String get email => 'ईमेल';

  @override
  String get phone => 'फोन';

  @override
  String get pune => 'पुणे';

  @override
  String get maharashtra => 'महाराष्ट्र';

  @override
  String get india => 'भारत';

  @override
  String get loading => 'लोड होत आहे...';

  @override
  String get pleaseWait => 'कृपया थांबा...';

  @override
  String get noInternet => 'इंटरनेट कनेक्शन नाही';

  @override
  String get tryAgain => 'पुन्हा प्रयत्न करा';

  @override
  String get somethingWentWrong => 'काहीच चूक झाले';

  @override
  String get unknownError => 'अज्ञात त्रुटी आली';

  @override
  String get success => 'यश';

  @override
  String get warning => 'चेतावणी';

  @override
  String get info => 'माहिती';

  @override
  String get yes => 'हो';

  @override
  String get no => 'नाही';

  @override
  String get ok => 'ठीक आहे';

  @override
  String get close => 'बंद करा';

  @override
  String get back => 'मागे';

  @override
  String get continueBtn => 'चालू ठेवा';

  @override
  String get finish => 'समाप्त';

  @override
  String get saveChanges => 'बदल सेव्ह करा';

  @override
  String get discardChanges => 'बदल टाळा';

  @override
  String get unsavedChanges =>
      'तुमच्याकडे सेव्ह न केलेले बदल आहेत. तुम्ही खरं बाहेर पडायचा का?';

  @override
  String get leave => 'जावा';

  @override
  String get stay => 'राहा';

  @override
  String get delete => 'हटवा';

  @override
  String get edit => 'संपादित करा';

  @override
  String get view => 'पहा';

  @override
  String get copy => 'कॉपी';

  @override
  String get copied => 'कॉपी झाले!';

  @override
  String get share => 'शेअर करा';

  @override
  String get download => 'डाउनलोड';

  @override
  String get print => 'प्रिंट';

  @override
  String get refresh => 'रिफ्रेश';

  @override
  String get searchHint => 'शोधा...';

  @override
  String get noResults => 'कोणतेही निकाल सापडले नाही';

  @override
  String get pullToRefresh => 'रिफ्रेश करिता खेचा';

  @override
  String get swipeToRefresh => 'रिफ्रेश करिता स्वाइप करा';

  @override
  String get lastUpdated => 'शेवटचा अपडेट';

  @override
  String get justNow => 'आता';

  @override
  String minutesAgo(Object minutes) {
    return '$minutes मिनिटेपूर्वी';
  }

  @override
  String hoursAgo(Object hours) {
    return '$hours तासपूर्वी';
  }

  @override
  String daysAgo(Object days) {
    return '$days दिवसपूर्वी';
  }

  @override
  String get today => 'आज';

  @override
  String get yesterday => 'काल';

  @override
  String get tomorrow => 'उद्या';

  @override
  String get thisWeek => 'या आठवड्यात';

  @override
  String get lastWeek => 'मागील आठवडा';

  @override
  String get thisMonth => 'या महिन्यात';

  @override
  String get lastMonth => 'मागील महिना';

  @override
  String get january => 'जानेवारी';

  @override
  String get february => 'फेब्रुवारी';

  @override
  String get march => 'मार्च';

  @override
  String get april => 'एप्रिल';

  @override
  String get may => 'मे';

  @override
  String get june => 'जून';

  @override
  String get july => 'जुलै';

  @override
  String get august => 'ऑगस्ट';

  @override
  String get september => 'सप्टेंबर';

  @override
  String get october => 'ऑक्टोबर';

  @override
  String get november => 'नोव्हेंबर';

  @override
  String get december => 'डिसेंबर';

  @override
  String get monday => 'सोमवार';

  @override
  String get tuesday => 'मंगळवार';

  @override
  String get wednesday => 'बुधवार';

  @override
  String get thursday => 'गुरुवार';

  @override
  String get friday => 'शुक्रवार';

  @override
  String get saturday => 'शनिवार';

  @override
  String get sunday => 'रविवार';

  @override
  String get am => 'सकाळी';

  @override
  String get pm => 'संध्याकाळी';

  @override
  String get rupee => '₹';

  @override
  String currencyFormat(Object amount) {
    return '₹$amount';
  }

  @override
  String get thousand => 'हजार';

  @override
  String get lakh => 'लाख';

  @override
  String get crore => 'कोटी';

  @override
  String get percent => '%';

  @override
  String ratingOutOf5(Object rating) {
    return '$rating/5';
  }

  @override
  String reviewsCount(Object count) {
    return '$count पुनरावलोकने';
  }

  @override
  String ratingCount(Object count) {
    return '$count रेटिंग';
  }

  @override
  String get highlyRated => 'अत्यधिक रेटेड';

  @override
  String get popular => 'लोकप्रिय';

  @override
  String get recommended => 'शिफारस केलेले';

  @override
  String get trending => 'ट्रेंडिंग';

  @override
  String get newItem => 'नवीन';

  @override
  String get featured => 'फीचर्ड';

  @override
  String get exclusive => 'एक्सक्लूसिव्ह';

  @override
  String get limitedTime => 'मर्यादित वेळ';

  @override
  String get offer => 'ऑफर';

  @override
  String get discount => 'सूट';

  @override
  String get coupon => 'कुपन';

  @override
  String get promoCode => 'प्रोमो कोड';

  @override
  String get applyCoupon => 'कुपन लागू करा';

  @override
  String get couponApplied => 'कुपन लागू';

  @override
  String get invalidCoupon => 'अवैध कुपन';

  @override
  String get couponExpired => 'कुपन संपले';

  @override
  String get freeBooking => 'मोफत बुकिंग';

  @override
  String get firstBookingFree => 'पहिली बुकिंग मोफत';

  @override
  String get referralBonus => 'रेफरल बोनस';

  @override
  String get inviteFriends => 'मित्रांना आमंत्रित करा';

  @override
  String get shareApp => 'अॅप शेअर करा';

  @override
  String get rateApp => 'अॅप रेट करा';

  @override
  String get feedback => 'प्रतिक्रिया';

  @override
  String get suggestFeature => 'फीचर सुचवा';

  @override
  String get reportBug => 'बग अहवाल करा';

  @override
  String get appVersion => 'अॅप संस्करण';

  @override
  String get buildNumber => 'बिल्ड नंबर';

  @override
  String get deviceInfo => 'डिव्हाइस माहिती';

  @override
  String get osVersion => 'OS संस्करण';

  @override
  String get networkInfo => 'नेटवर्क माहिती';

  @override
  String get debugInfo => 'डीबग माहिती';

  @override
  String get logs => 'लॉग्स';

  @override
  String get clearLogs => 'लॉग्स साफ करा';

  @override
  String get exportLogs => 'लॉग्स एक्सपोर्ट करा';

  @override
  String get crashReport => 'क्रॅश अहवाल';

  @override
  String get sendCrashReport => 'क्रॅश अहवाल पाठवा';

  @override
  String get analytics => 'एनालिटिक्स';

  @override
  String get events => 'इव्हेंट्स';

  @override
  String get users => 'वापरकर्ते';

  @override
  String get sessions => 'सत्र';

  @override
  String get retention => 'रिटेन्शन';

  @override
  String get conversion => 'रूपांतर';

  @override
  String get revenue => 'उत्पन्न';

  @override
  String get bookingsCount => 'बुकिंग्ज';

  @override
  String get workersCount => 'कामगार';

  @override
  String get activeUsers => 'सक्रिय वापरकर्ते';

  @override
  String get churnRate => 'चर्न दर';

  @override
  String get ltv => 'LTV';

  @override
  String get cac => 'CAC';

  @override
  String get roi => 'ROI';
}
