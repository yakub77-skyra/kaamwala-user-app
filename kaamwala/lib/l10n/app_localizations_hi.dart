// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'कामवाला';

  @override
  String get appNamePartner => 'कामवाला पार्टनर';

  @override
  String get home => 'होम';

  @override
  String get search => 'खोजें';

  @override
  String get bookings => 'बुकिंग्स';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get earnings => 'कमाई';

  @override
  String get login => 'लॉगिन';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get enterPhoneNumber => 'अपना फोन नंबर दर्ज करें';

  @override
  String get sendOTP => 'OTP भेजें';

  @override
  String get otp => 'OTP';

  @override
  String get enterOTP => 'OTP दर्ज करें';

  @override
  String get verifyOTP => 'OTP सत्यापित करें';

  @override
  String get resendOTP => 'OTP फिर से भेजें';

  @override
  String resendIn(Object seconds) {
    return '$seconds सेकंड में फिर से भेजें';
  }

  @override
  String get name => 'नाम';

  @override
  String get enterName => 'अपना नाम दर्ज करें';

  @override
  String get city => 'शहर';

  @override
  String get selectCity => 'अपना शहर चुनें';

  @override
  String get roleSelection => 'आप कौन हैं?';

  @override
  String get customer => 'मुझे काम करने वाला चाहिए';

  @override
  String get worker => 'मैं काम करने वाला हूँ';

  @override
  String get bookWorker => 'काम करने वाला बुक करें';

  @override
  String get whatWork => 'आपको क्या काम चाहिए?';

  @override
  String get describeWork => 'काम का वर्णन करें...';

  @override
  String get when => 'कब?';

  @override
  String get date => 'तारीख';

  @override
  String get timeSlot => 'समय स्लॉट';

  @override
  String get where => 'कहाँ?';

  @override
  String get address => 'पता';

  @override
  String get enterAddress => 'पूरा पता दर्ज करें';

  @override
  String get jobEstimate => 'काम का अनुमान';

  @override
  String get bookingFee => 'बुकिंग शुल्क (वापसी योग्य)';

  @override
  String get finalPriceNote =>
      'अंतिम कीमत काम शुरू होने से पहले काम करने वाले के साथ तय होती है।';

  @override
  String payAndBook(Object amount) {
    return '₹$amount देकर बुक करें';
  }

  @override
  String get creatingBooking => 'बुकिंग बनाई जा रही है...';

  @override
  String get cancelAnytime => 'पेंडिंग रहने पर कभी भी कैंसिल करें = पूरा रिफंड';

  @override
  String get myBookings => 'मेरी बुकिंग्स';

  @override
  String get noBookings => 'अभी तक कोई बुकिंग नहीं';

  @override
  String get bookingDetail => 'बुकिंग विवरण';

  @override
  String get workerDetails => 'काम करने वाले का विवरण';

  @override
  String get status => 'स्थिति';

  @override
  String get pending => 'पेंडिंग';

  @override
  String get accepted => 'स्वीकृत';

  @override
  String get traveling => 'आ रहे हैं';

  @override
  String get arrived => 'पहुँच गए';

  @override
  String get inProgress => 'चल रहा है';

  @override
  String get completed => 'पूरा हुआ';

  @override
  String get cancelled => 'रद्द';

  @override
  String get declined => 'अस्वीकृत';

  @override
  String get cancelBooking => 'बुकिंग रद्द करें';

  @override
  String get confirmCancel => 'क्या आप वाकई इस बुकिंग को रद्द करना चाहते हैं?';

  @override
  String get yesCancel => 'हाँ, रद्द करें';

  @override
  String get noKeep => 'नहीं, रखें';

  @override
  String get chat => 'चैट';

  @override
  String get message => 'संदेश';

  @override
  String get send => 'भेजें';

  @override
  String get typeMessage => 'संदेश टाइप करें...';

  @override
  String get rateReview => 'रेटिंग और समीक्षा';

  @override
  String get rating => 'रेटिंग';

  @override
  String get review => 'समीक्षा';

  @override
  String get submitReview => 'समीक्षा जमा करें';

  @override
  String get addPhotos => 'फोटो/वीडियो जोड़ें (वैकल्पिक)';

  @override
  String get gallery => 'गैलरी';

  @override
  String get camera => 'कैमरा';

  @override
  String get maxPhotos => 'अधिकतम 5 फोटो/वीडियो अनुमत';

  @override
  String get uploadFailed => 'मीडिया अपलोड करने में विफल';

  @override
  String get searchWorkers => 'नाम से खोजें';

  @override
  String get sortBy => 'क्रमबद्ध करें';

  @override
  String get topRated => 'सबसे ज्यादा रेटिंग';

  @override
  String get priceLowHigh => 'कीमत: कम से ज्यादा';

  @override
  String get priceHighLow => 'कीमत: ज्यादा से कम';

  @override
  String get nearestFirst => 'सबसे नज़दीकी पहले';

  @override
  String get enableLocation => 'दूरी के लिए लोकेशन चालू करें';

  @override
  String get availableNow => 'अभी उपलब्ध';

  @override
  String distance(Object distance) {
    return '$distance किमी दूर';
  }

  @override
  String fromPrice(Object price) {
    return '₹$price से शुरू';
  }

  @override
  String get verified => 'सत्यापित';

  @override
  String get newWorker => 'नया';

  @override
  String noWorkersFound(Object category) {
    return 'कोई $category नहीं मिला';
  }

  @override
  String get tryDifferentCategory =>
      'अलग श्रेणी आज़माएँ या बाद में देखें - नए काम करने वाले रोज़ जुड़ते हैं।';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get help => 'सहायता और FAQ';

  @override
  String get language => 'भाषा';

  @override
  String get english => 'अंग्रेज़ी';

  @override
  String get hindi => 'हिंदी';

  @override
  String get marathi => 'मराठी';

  @override
  String get version => 'संस्करण';

  @override
  String get emergency => 'आपातकाल';

  @override
  String get urgent => 'तत्काल';

  @override
  String get urgentTag => 'तत्काल - 30 मिनट में चाहिए';

  @override
  String get favorites => 'पसंदीदा';

  @override
  String get addToFavorites => 'पसंदीदा में जोड़ें';

  @override
  String get removeFromFavorites => 'पसंदीदा से हटाएं';

  @override
  String get jobHistory => 'काम का इतिहास';

  @override
  String get downloadReceipt => 'रसीद डाउनलोड करें';

  @override
  String get shareBooking => 'बुकिंग शेयर करें';

  @override
  String get shareViaWhatsApp => 'WhatsApp से शेयर करें';

  @override
  String get workerOnTheWay => 'काम करने वाला रास्ते में है!';

  @override
  String get workerArrived => 'काम करने वाला पहुँच गया';

  @override
  String get workStarted => 'काम शुरू हुआ';

  @override
  String get jobCompleted => 'काम पूरा हुआ';

  @override
  String get confirmCompletion => 'पूरा होने की पुष्टि करें';

  @override
  String get tipWorker => 'काम करने वाले को टिप दें';

  @override
  String get tipAmount => 'टिप राशि';

  @override
  String get thankYou => 'धन्यवाद!';

  @override
  String get error => 'त्रुटि';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get offline => 'आप ऑफलाइन हैं';

  @override
  String get checkConnection => 'इंटरनेट कनेक्शन जाँचें और पुनः प्रयास करें';

  @override
  String get serverError => 'सर्वर से संपर्क नहीं हो सका';

  @override
  String get permissionDenied => 'अनुमति अस्वीकृत';

  @override
  String get locationPermission => 'दूरी क्रम के लिए लोकेशन अनुमति चाहिए';

  @override
  String get cameraPermission => 'फोटो के लिए कैमरा अनुमति चाहिए';

  @override
  String get storagePermission => 'मीडिया के लिए स्टोरेज अनुमति चाहिए';

  @override
  String get workerDashboard => 'डैशबोर्ड';

  @override
  String get newJobs => 'नए काम';

  @override
  String get activeJobs => 'चल रहे काम';

  @override
  String get completedJobs => 'पूरे हुए काम';

  @override
  String get earningsToday => 'आज की कमाई';

  @override
  String get earningsWeek => 'इस हफ्ते';

  @override
  String get earningsMonth => 'इस महीने';

  @override
  String get acceptJob => 'स्वीकार करें';

  @override
  String get declineJob => 'अस्वीकार करें';

  @override
  String get startTraveling => 'यात्रा शुरू करें';

  @override
  String get markArrived => 'पहुँचे के रूप में चिह्नित करें';

  @override
  String get startWork => 'काम शुरू करें';

  @override
  String get completeWork => 'काम पूरा करें';

  @override
  String get shareLocation => 'लाइव लोकेशन शेयर करें';

  @override
  String get stopSharingLocation => 'लोकेशन शेयर करना बंद करें';

  @override
  String get locationShared => 'ग्राहक के साथ लोकेशन शेयर की गई';

  @override
  String get locationStopped => 'लोकेशन शेयर करना बंद किया गया';

  @override
  String get workerProfile => 'काम करने वाले की प्रोफाइल';

  @override
  String get editProfile => 'प्रोफाइल संपादित करें';

  @override
  String get availability => 'उपलब्धता';

  @override
  String get available => 'उपलब्ध';

  @override
  String get notAvailable => 'उपलब्ध नहीं';

  @override
  String get skills => 'कौशल';

  @override
  String get bio => 'बायो';

  @override
  String get priceRange => 'कीमत सीमा';

  @override
  String get minPrice => 'न्यूनतम कीमत';

  @override
  String get maxPrice => 'अधिकतम कीमत';

  @override
  String get portfolio => 'पोर्टफोलियो';

  @override
  String get addPhoto => 'फोटो जोड़ें';

  @override
  String get aadharFront => 'आधार फ्रंट';

  @override
  String get aadharBack => 'आधार बैक';

  @override
  String get submitForApproval => 'अनुमोदन के लिए जमा करें';

  @override
  String get underReview => 'समीक्षा में';

  @override
  String get approved => 'अनुमोदित';

  @override
  String get rejected => 'अस्वीकृत';

  @override
  String get rejectionReason => 'अस्वीकृति का कारण';

  @override
  String get paymentSetup => 'भुगतान सेटअप';

  @override
  String get upiId => 'UPI ID';

  @override
  String get bankAccount => 'बैंक खाता';

  @override
  String get ifsc => 'IFSC';

  @override
  String get accountHolder => 'खाताधारक';

  @override
  String get save => 'सेव करें';

  @override
  String get adminConsole => 'एडमिन कंसोल';

  @override
  String get pendingWorkers => 'पेंडिंग काम करने वाले';

  @override
  String get approveWorker => 'काम करने वाले को अनुमोदित करें';

  @override
  String get rejectWorker => 'काम करने वाले को अस्वीकार करें';

  @override
  String get wrongApp => 'गलत ऐप';

  @override
  String wrongAppMessage(Object role) {
    return 'यह ऐप केवल $role के लिए है। कृपया सही ऐप डाउनलोड करें।';
  }

  @override
  String get downloadCustomerApp => 'कामवाला (ग्राहक) डाउनलोड करें';

  @override
  String get downloadWorkerApp =>
      'कामवाला पार्टनर (काम करने वाला) डाउनलोड करें';

  @override
  String get onboardingTitle => 'कामवाला में आपका स्वागत है';

  @override
  String get onboardingSubtitle => 'सत्यापित काम करने वाले। तुरंत बुकिंग।';

  @override
  String get onboardingPartnerSubtitle => 'आपके पास काम पाएँ। रोज़ कमाएँ।';

  @override
  String get skip => 'छोड़ें';

  @override
  String get next => 'आगे';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get confirmCompletionTitle => 'काम पूरा होने की पुष्टि';

  @override
  String get confirmCompletionMessage =>
      'क्या काम करने वाले ने काम आपकी संतुष्टि के अनुसार पूरा किया?';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get ratingSubmitted => 'रेटिंग जमा की गई!';

  @override
  String get thankYouForRating => 'आपकी प्रतिक्रिया के लिए धन्यवाद।';

  @override
  String get paymentSuccess => 'भुगतान सफल';

  @override
  String get paymentFailed => 'भुगतान विफल';

  @override
  String get orderCreated => 'ऑर्डर बनाया गया';

  @override
  String get refundInitiated => 'रिफंड शुरू';

  @override
  String get refundProcessing => 'रिफंड प्रोसेस हो रहा है...';

  @override
  String get payoutPending => 'पेआउट पेंडिंग';

  @override
  String get payoutProcessing => 'पेआउट प्रोसेस हो रहा है';

  @override
  String get payoutSuccess => 'पेआउट सफल';

  @override
  String get payoutFailed => 'पेआउट विफल';

  @override
  String get liveLocation => 'लाइव लोकेशन';

  @override
  String get workerLocation => 'काम करने वाले की लोकेशन';

  @override
  String get yourLocation => 'आपकी लोकेशन';

  @override
  String get tracking => 'ट्रैकिंग...';

  @override
  String get stopTracking => 'ट्रैकिंग बंद करें';

  @override
  String get jobDescription => 'काम का विवरण';

  @override
  String get bookingRef => 'बुकिंग संदर्भ';

  @override
  String get bookingDate => 'बुकिंग तारीख';

  @override
  String get bookingTime => 'बुकिंग समय';

  @override
  String get workerName => 'काम करने वाले का नाम';

  @override
  String get clientName => 'ग्राहक का नाम';

  @override
  String get callWorker => 'काम करने वाले को कॉल करें';

  @override
  String get callClient => 'ग्राहक को कॉल करें';

  @override
  String get viewOnMap => 'मानचित्र पर देखें';

  @override
  String get directions => 'दिशा-निर्देश';

  @override
  String get shareLocationWithWorker => 'काम करने वाले के साथ लोकेशन शेयर करें';

  @override
  String get workerWillSeeYourLocation => 'काम करने वाला आपकी लोकेशन देखेगा';

  @override
  String get bookingPhotos => 'बुकिंग फोटो';

  @override
  String get viewPhotos => 'फोटो देखें';

  @override
  String get noPhotos => 'कोई फोटो अपलोड नहीं';

  @override
  String get photoUploaded => 'फोटो अपलोड किया गया';

  @override
  String get videoUploaded => 'वीडियो अपलोड किया गया';

  @override
  String get mediaUploaded => 'मीडिया अपलोड किया गया';

  @override
  String get selectMedia => 'फोटो/वीडियो चुनें';

  @override
  String get takePhoto => 'फोटो लें';

  @override
  String get chooseFromGallery => 'गैलरी से चुनें';

  @override
  String get remove => 'हटाएं';

  @override
  String get clearAll => 'सभी हटाएं';

  @override
  String get done => 'हो गया';

  @override
  String get apply => 'लागू करें';

  @override
  String get filter => 'फिल्टर';

  @override
  String get clearFilters => 'फिल्टर साफ़ करें';

  @override
  String get category => 'श्रेणी';

  @override
  String get allCategories => 'सभी श्रेणियाँ';

  @override
  String get plumber => 'प्लंबर';

  @override
  String get electrician => 'इलेक्ट्रीशियन';

  @override
  String get painter => 'पेंटर';

  @override
  String get carpenter => 'कारपेंटर';

  @override
  String get workerList => 'काम करने वाले';

  @override
  String get topRatedNearYou => 'आपके पास सबसे ज्यादा रेटिंग';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String get bookAgain => 'फिर से बुक करें';

  @override
  String get recentlyBooked => 'हाल ही में बुक किया';

  @override
  String get favoriteWorkers => 'पसंदीदा काम करने वाले';

  @override
  String get noFavorites => 'अभी तक कोई पसंदीदा काम करने वाला नहीं';

  @override
  String get addWorkersToFavorites =>
      'उनकी प्रोफाइल से काम करने वालों को पसंदीदा में जोड़ें';

  @override
  String get recurringBooking => 'आवर्ती बुकिंग';

  @override
  String get scheduleRecurring => 'आवर्ती सेवा शेड्यूल करें';

  @override
  String get frequency => 'आवृत्ति';

  @override
  String get weekly => 'साप्ताहिक';

  @override
  String get monthly => 'मासिक';

  @override
  String get quarterly => 'त्रैमासिक';

  @override
  String get custom => 'कस्टम';

  @override
  String get servicePackages => 'सेवा पैकेज';

  @override
  String get packageDetails => 'पैकेज विवरण';

  @override
  String get bookPackage => 'पैकेज बुक करें';

  @override
  String get warranty => 'वारंटी';

  @override
  String get warrantyPeriod => 'वारंटी अवधि';

  @override
  String get days30 => '30 दिन';

  @override
  String get days90 => '90 दिन';

  @override
  String get days180 => '180 दिन';

  @override
  String get guarantee => 'गारंटी';

  @override
  String get workGuarantee => 'काम की गारंटी';

  @override
  String get emergencySurcharge => 'आपातकालीन अधिभार';

  @override
  String get extraForUrgent => 'तत्काल सेवा के लिए अतिरिक्त';

  @override
  String get multiWorkerBooking => 'बहु-काम करने वाला बुकिंग';

  @override
  String get addAnotherWorker => 'एक और काम करने वाला जोड़ें';

  @override
  String get bundleDiscount => 'बंडल छूट';

  @override
  String get structuredQuote => 'संरचित कोटेशन';

  @override
  String get sendQuote => 'कोटेशन भेजें';

  @override
  String get acceptQuote => 'कोटेशन स्वीकार करें';

  @override
  String get rejectQuote => 'कोटेशन अस्वीकार करें';

  @override
  String get quoteAmount => 'कोटेशन राशि';

  @override
  String get quoteDetails => 'कोटेशन विवरण';

  @override
  String get negotiatePrice => 'कीमत पर बातचीत करें';

  @override
  String get finalPrice => 'अंतिम कीमत';

  @override
  String get agreedPrice => 'सहमत कीमत';

  @override
  String get priceAgreed => 'कीमत सहमत';

  @override
  String get paymentAfterWork => 'काम के बाद भुगतान';

  @override
  String get payAfterConfirmation => 'पुष्टि के बाद भुगतान करें';

  @override
  String get holdMoney => 'पुष्टि होने तक पैसा रुका हुआ';

  @override
  String get refundPolicy => 'रिफंड नीति';

  @override
  String get fullRefundIfCancelled => 'पेंडिंग रहने पर रद्द करने पर पूरा रिफंड';

  @override
  String get partialRefund =>
      'काम करने वाले के स्वीकार करने के बाद आंशिक रिफंड';

  @override
  String get noRefundAfterStart => 'काम शुरू होने के बाद कोई रिफंड नहीं';

  @override
  String get support => 'सहायता';

  @override
  String get contactSupport => 'सहायता से संपर्क करें';

  @override
  String get faq => 'FAQ';

  @override
  String get termsOfService => 'सेवा की शर्तें';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get about => 'हमारे बारे में';

  @override
  String get aboutKaamWala => 'कामवाला के बारे में';

  @override
  String get contactUs => 'संपर्क करें';

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
  String get loading => 'लोड हो रहा है...';

  @override
  String get pleaseWait => 'कृपया प्रतीक्षा करें...';

  @override
  String get noInternet => 'इंटरनेट कनेक्शन नहीं';

  @override
  String get tryAgain => 'फिर से कोशिश करें';

  @override
  String get somethingWentWrong => 'कुछ गलत हो गया';

  @override
  String get unknownError => 'अज्ञात त्रुटि हुई';

  @override
  String get success => 'सफलता';

  @override
  String get warning => 'चेतावनी';

  @override
  String get info => 'जानकारी';

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';

  @override
  String get ok => 'ठीक है';

  @override
  String get close => 'बंद करें';

  @override
  String get back => 'वापस';

  @override
  String get continueBtn => 'जारी रखें';

  @override
  String get finish => 'समाप्त';

  @override
  String get saveChanges => 'बदलाव सेव करें';

  @override
  String get discardChanges => 'बदलाव छोड़ें';

  @override
  String get unsavedChanges =>
      'आपके पास अनसेव बदलाव हैं। क्या आप वाकई छोड़ना चाहते हैं?';

  @override
  String get leave => 'छोड़ें';

  @override
  String get stay => 'रहें';

  @override
  String get delete => 'हटाएं';

  @override
  String get edit => 'संपादित करें';

  @override
  String get view => 'देखें';

  @override
  String get copy => 'कॉपी';

  @override
  String get copied => 'कॉपी हो गया!';

  @override
  String get share => 'शेयर करें';

  @override
  String get download => 'डाउनलोड';

  @override
  String get print => 'प्रिंट';

  @override
  String get refresh => 'रिफ्रेश';

  @override
  String get searchHint => 'खोजें...';

  @override
  String get noResults => 'कोई परिणाम नहीं मिला';

  @override
  String get pullToRefresh => 'रिफ्रेश करने के लिए खींचें';

  @override
  String get swipeToRefresh => 'रिफ्रेश करने के लिए स्वाइप करें';

  @override
  String get lastUpdated => 'आखिरी अपडेट';

  @override
  String get justNow => 'अभी';

  @override
  String minutesAgo(Object minutes) {
    return '$minutes मिनट पहले';
  }

  @override
  String hoursAgo(Object hours) {
    return '$hours घंटे पहले';
  }

  @override
  String daysAgo(Object days) {
    return '$days दिन पहले';
  }

  @override
  String get today => 'आज';

  @override
  String get yesterday => 'कल';

  @override
  String get tomorrow => 'कल';

  @override
  String get thisWeek => 'इस हफ्ते';

  @override
  String get lastWeek => 'पिछला हफ्ता';

  @override
  String get thisMonth => 'इस महीने';

  @override
  String get lastMonth => 'पिछला महीना';

  @override
  String get january => 'जनवरी';

  @override
  String get february => 'फरवरी';

  @override
  String get march => 'मार्च';

  @override
  String get april => 'अप्रैल';

  @override
  String get may => 'मई';

  @override
  String get june => 'जून';

  @override
  String get july => 'जुलाई';

  @override
  String get august => 'अगस्त';

  @override
  String get september => 'सितंबर';

  @override
  String get october => 'अक्टूबर';

  @override
  String get november => 'नवंबर';

  @override
  String get december => 'दिसंबर';

  @override
  String get monday => 'सोमवार';

  @override
  String get tuesday => 'मंगलवार';

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
  String get am => 'पूर्वाह्न';

  @override
  String get pm => 'अपराह्न';

  @override
  String get rupee => '₹';

  @override
  String currencyFormat(Object amount) {
    return '₹$amount';
  }

  @override
  String get thousand => 'हज़ार';

  @override
  String get lakh => 'लाख';

  @override
  String get crore => 'करोड़';

  @override
  String get percent => '%';

  @override
  String ratingOutOf5(Object rating) {
    return '$rating/5';
  }

  @override
  String reviewsCount(Object count) {
    return '$count समीक्षाएं';
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
  String get recommended => 'अनुशंसित';

  @override
  String get trending => 'ट्रेंडिंग';

  @override
  String get newItem => 'नया';

  @override
  String get featured => 'फीचर्ड';

  @override
  String get exclusive => 'एक्सक्लूसिव';

  @override
  String get limitedTime => 'सीमित समय';

  @override
  String get offer => 'ऑफर';

  @override
  String get discount => 'छूट';

  @override
  String get coupon => 'कूपन';

  @override
  String get promoCode => 'प्रोमो कोड';

  @override
  String get applyCoupon => 'कूपन लागू करें';

  @override
  String get couponApplied => 'कूपन लागू';

  @override
  String get invalidCoupon => 'अमान्य कूपन';

  @override
  String get couponExpired => 'कूपन समाप्त';

  @override
  String get freeBooking => 'मुफ्त बुकिंग';

  @override
  String get firstBookingFree => 'पहली बुकिंग मुफ्त';

  @override
  String get referralBonus => 'रेफरल बोनस';

  @override
  String get inviteFriends => 'दोस्तों को आमंत्रित करें';

  @override
  String get shareApp => 'ऐप शेयर करें';

  @override
  String get rateApp => 'ऐप रेट करें';

  @override
  String get feedback => 'प्रतिक्रिया';

  @override
  String get suggestFeature => 'फीचर सुझाएं';

  @override
  String get reportBug => 'बग रिपोर्ट करें';

  @override
  String get appVersion => 'ऐप संस्करण';

  @override
  String get buildNumber => 'बिल्ड नंबर';

  @override
  String get deviceInfo => 'डिवाइस जानकारी';

  @override
  String get osVersion => 'OS संस्करण';

  @override
  String get networkInfo => 'नेटवर्क जानकारी';

  @override
  String get debugInfo => 'डीबग जानकारी';

  @override
  String get logs => 'लॉग्स';

  @override
  String get clearLogs => 'लॉग्स साफ़ करें';

  @override
  String get exportLogs => 'लॉग्स एक्सपोर्ट करें';

  @override
  String get crashReport => 'क्रैश रिपोर्ट';

  @override
  String get sendCrashReport => 'क्रैश रिपोर्ट भेजें';

  @override
  String get analytics => 'एनालिटिक्स';

  @override
  String get events => 'इवेंट्स';

  @override
  String get users => 'उपयोगकर्ता';

  @override
  String get sessions => 'सत्र';

  @override
  String get retention => 'रिटेंशन';

  @override
  String get conversion => 'रूपांतरण';

  @override
  String get revenue => 'राजस्व';

  @override
  String get bookingsCount => 'बुकिंग्स';

  @override
  String get workersCount => 'काम करने वाले';

  @override
  String get activeUsers => 'सक्रिय उपयोगकर्ता';

  @override
  String get churnRate => 'चर्न दर';

  @override
  String get ltv => 'LTV';

  @override
  String get cac => 'CAC';

  @override
  String get roi => 'ROI';
}
