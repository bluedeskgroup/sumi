import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @createStory.
  ///
  /// In en, this message translates to:
  /// **'Create Story'**
  String get createStory;

  /// No description provided for @selectMediaForStory.
  ///
  /// In en, this message translates to:
  /// **'Select media for your story'**
  String get selectMediaForStory;

  /// No description provided for @galleryImage.
  ///
  /// In en, this message translates to:
  /// **'Image from Gallery'**
  String get galleryImage;

  /// No description provided for @cameraImage.
  ///
  /// In en, this message translates to:
  /// **'Image from Camera'**
  String get cameraImage;

  /// No description provided for @galleryVideo.
  ///
  /// In en, this message translates to:
  /// **'Video from Gallery'**
  String get galleryVideo;

  /// No description provided for @cameraVideo.
  ///
  /// In en, this message translates to:
  /// **'Video from Camera'**
  String get cameraVideo;

  /// No description provided for @profile_reward_points.
  ///
  /// In en, this message translates to:
  /// **'Reward Points'**
  String get profile_reward_points;

  /// No description provided for @profile_days_remaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days remaining'**
  String profile_days_remaining(int days);

  /// No description provided for @profile_subscription_status.
  ///
  /// In en, this message translates to:
  /// **'Subscription Status'**
  String get profile_subscription_status;

  /// No description provided for @profile_free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get profile_free;

  /// No description provided for @profile_default_name.
  ///
  /// In en, this message translates to:
  /// **'Sumi User'**
  String get profile_default_name;

  /// No description provided for @profile_manage_account.
  ///
  /// In en, this message translates to:
  /// **'Manage your account and profile'**
  String get profile_manage_account;

  /// No description provided for @profile_transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get profile_transactions;

  /// No description provided for @profile_transactions_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your transaction history'**
  String get profile_transactions_subtitle;

  /// No description provided for @profile_my_cards.
  ///
  /// In en, this message translates to:
  /// **'My Cards'**
  String get profile_my_cards;

  /// No description provided for @profile_my_cards_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your saved cards'**
  String get profile_my_cards_subtitle;

  /// No description provided for @profile_my_points.
  ///
  /// In en, this message translates to:
  /// **'My Points'**
  String get profile_my_points;

  /// No description provided for @profile_my_points_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Check your points balance'**
  String get profile_my_points_subtitle;

  /// No description provided for @profile_share_and_earn.
  ///
  /// In en, this message translates to:
  /// **'Share and Earn'**
  String get profile_share_and_earn;

  /// No description provided for @profile_share_and_earn_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Get rewards for inviting friends'**
  String get profile_share_and_earn_subtitle;

  /// No description provided for @profile_my_profile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profile_my_profile;

  /// No description provided for @profile_my_profile_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get profile_my_profile_subtitle;

  /// No description provided for @profile_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profile_language;

  /// No description provided for @profile_language_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Change the application language'**
  String get profile_language_subtitle;

  /// No description provided for @profile_my_addresses.
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get profile_my_addresses;

  /// No description provided for @profile_my_addresses_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your shipping addresses'**
  String get profile_my_addresses_subtitle;

  /// No description provided for @profile_sign_out.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profile_sign_out;

  /// No description provided for @profile_sign_out_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get profile_sign_out_subtitle;

  /// No description provided for @dialog_choose_language.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get dialog_choose_language;

  /// No description provided for @dialog_arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get dialog_arabic;

  /// No description provided for @dialog_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get dialog_english;

  /// No description provided for @loadVideosFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load videos.'**
  String get loadVideosFailed;

  /// No description provided for @videosPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videosPageTitle;

  /// No description provided for @noVideosAvailable.
  ///
  /// In en, this message translates to:
  /// **'No videos available yet.'**
  String get noVideosAvailable;

  /// No description provided for @noMorePosts.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the end!'**
  String get noMorePosts;

  /// No description provided for @skipButton.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipButton;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Discover Beauty Services'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Description.
  ///
  /// In en, this message translates to:
  /// **'Find the best beauty salons, makeup artists, and more, all in one place.'**
  String get onboardingPage1Description;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Shop for Your Favorite Products'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Description.
  ///
  /// In en, this message translates to:
  /// **'Explore a wide range of beauty products and get them delivered to your doorstep.'**
  String get onboardingPage2Description;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Join the Community'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Description.
  ///
  /// In en, this message translates to:
  /// **'Share your experiences, get advice, and connect with other beauty lovers.'**
  String get onboardingPage3Description;

  /// No description provided for @startButton.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get startButton;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Your Language'**
  String get selectLanguage;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'You need to be logged in to see this content.'**
  String get loginRequired;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @sumiServices.
  ///
  /// In en, this message translates to:
  /// **'Sumi Services'**
  String get sumiServices;

  /// No description provided for @jobVacancies.
  ///
  /// In en, this message translates to:
  /// **'Job Vacancies'**
  String get jobVacancies;

  /// No description provided for @popularCommunityPosts.
  ///
  /// In en, this message translates to:
  /// **'Popular Community Posts'**
  String get popularCommunityPosts;

  /// No description provided for @viewMore.
  ///
  /// In en, this message translates to:
  /// **'View More'**
  String get viewMore;

  /// No description provided for @sumiSpecialOffers.
  ///
  /// In en, this message translates to:
  /// **'Sumi Special Offers'**
  String get sumiSpecialOffers;

  /// No description provided for @featuredOffers.
  ///
  /// In en, this message translates to:
  /// **'Featured Offers'**
  String get featuredOffers;

  /// No description provided for @sumiCards.
  ///
  /// In en, this message translates to:
  /// **'Sumi Cards'**
  String get sumiCards;

  /// No description provided for @cannotLoadServices.
  ///
  /// In en, this message translates to:
  /// **'Cannot load services.'**
  String get cannotLoadServices;

  /// No description provided for @cannotLoadVideos.
  ///
  /// In en, this message translates to:
  /// **'Cannot load videos.'**
  String get cannotLoadVideos;

  /// No description provided for @cannotLoadPopularPosts.
  ///
  /// In en, this message translates to:
  /// **'Cannot load popular posts.'**
  String get cannotLoadPopularPosts;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @failedToUpdateLikeStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update like status.'**
  String get failedToUpdateLikeStatus;

  /// No description provided for @sharePost.
  ///
  /// In en, this message translates to:
  /// **'Share Post'**
  String get sharePost;

  /// No description provided for @shareComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Sharing feature is coming soon!'**
  String get shareComingSoon;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePost;

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post?'**
  String get deleteConfirmation;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @postDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted successfully.'**
  String get postDeleted;

  /// No description provided for @failedToDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete post.'**
  String get failedToDeletePost;

  /// No description provided for @editPost.
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get editPost;

  /// No description provided for @editComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Editing feature is coming soon!'**
  String get editComingSoon;

  /// No description provided for @reportPost.
  ///
  /// In en, this message translates to:
  /// **'Report Post'**
  String get reportPost;

  /// No description provided for @reportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Reporting feature is coming soon!'**
  String get reportComingSoon;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @failedToLoadPost.
  ///
  /// In en, this message translates to:
  /// **'Failed to load post details.'**
  String get failedToLoadPost;

  /// No description provided for @loginToComment.
  ///
  /// In en, this message translates to:
  /// **'Please log in to comment.'**
  String get loginToComment;

  /// No description provided for @failedToAddComment.
  ///
  /// In en, this message translates to:
  /// **'Failed to add comment.'**
  String get failedToAddComment;

  /// No description provided for @postDetailsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postDetailsPageTitle;

  /// No description provided for @postNotFound.
  ///
  /// In en, this message translates to:
  /// **'Post not found.'**
  String get postNotFound;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @noRecents.
  ///
  /// In en, this message translates to:
  /// **'No Recents'**
  String get noRecents;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment!'**
  String get noCommentsYet;

  /// No description provided for @addContent.
  ///
  /// In en, this message translates to:
  /// **'Please add content or media to your post.'**
  String get addContent;

  /// No description provided for @postCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Post created successfully!'**
  String get postCreatedSuccess;

  /// No description provided for @postCreatedFail.
  ///
  /// In en, this message translates to:
  /// **'Failed to create post:'**
  String get postCreatedFail;

  /// No description provided for @createPostPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPostPageTitle;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @videoOption.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoOption;

  /// No description provided for @communityPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityPageTitle;

  /// No description provided for @featuredPosts.
  ///
  /// In en, this message translates to:
  /// **'Featured Posts'**
  String get featuredPosts;

  /// No description provided for @recentPosts.
  ///
  /// In en, this message translates to:
  /// **'Recent Posts'**
  String get recentPosts;

  /// No description provided for @allPosts.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allPosts;

  /// No description provided for @textPosts.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textPosts;

  /// No description provided for @imagePosts.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get imagePosts;

  /// No description provided for @videoPosts.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videoPosts;

  /// No description provided for @noFeaturedPosts.
  ///
  /// In en, this message translates to:
  /// **'No featured posts yet.'**
  String get noFeaturedPosts;

  /// No description provided for @noPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts here yet. Be the first to post!'**
  String get noPosts;

  /// No description provided for @otpFailedToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in: '**
  String get otpFailedToSignIn;

  /// No description provided for @otpInvalidCodeError.
  ///
  /// In en, this message translates to:
  /// **'The code you entered is invalid.'**
  String get otpInvalidCodeError;

  /// No description provided for @otpAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Number'**
  String get otpAppBarTitle;

  /// No description provided for @otpPageInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to'**
  String get otpPageInstruction;

  /// No description provided for @otpVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerifyButton;

  /// No description provided for @otpDidNotReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive a code?'**
  String get otpDidNotReceiveCode;

  /// No description provided for @otpResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get otpResendCode;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in'**
  String get otpResendIn;

  /// No description provided for @loginVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification Failed:'**
  String get loginVerificationFailed;

  /// No description provided for @loginTagline1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Sumi!'**
  String get loginTagline1;

  /// No description provided for @loginTagline2.
  ///
  /// In en, this message translates to:
  /// **'Your one-stop destination for beauty and elegance.'**
  String get loginTagline2;

  /// No description provided for @loginPhoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get loginPhoneNumberLabel;

  /// No description provided for @loginContinueWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with Phone'**
  String get loginContinueWithPhone;

  /// No description provided for @loginOrDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get loginOrDivider;

  /// No description provided for @loginContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginContinueWithGoogle;

  /// No description provided for @helpCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenterTitle;

  /// No description provided for @helpCenterHowCanWeHelp.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get helpCenterHowCanWeHelp;

  /// No description provided for @helpCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t find what you were looking for? Contact our support!'**
  String get helpCenterSubtitle;

  /// No description provided for @openNewTicket.
  ///
  /// In en, this message translates to:
  /// **'Open New Ticket'**
  String get openNewTicket;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @aboutUsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn about Sumi\'s story'**
  String get aboutUsSubtitle;

  /// No description provided for @sumiServicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Various marketing and advertising services'**
  String get sumiServicesSubtitle;

  /// No description provided for @affiliateMarketing.
  ///
  /// In en, this message translates to:
  /// **'Affiliate Marketing'**
  String get affiliateMarketing;

  /// No description provided for @affiliateMarketingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell your friend and get rewards'**
  String get affiliateMarketingSubtitle;

  /// No description provided for @joinUs.
  ///
  /// In en, this message translates to:
  /// **'Join Us'**
  String get joinUs;

  /// No description provided for @joinUsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join our team'**
  String get joinUsSubtitle;

  /// No description provided for @ourAgents.
  ///
  /// In en, this message translates to:
  /// **'Our Agents'**
  String get ourAgents;

  /// No description provided for @ourAgentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find our agents'**
  String get ourAgentsSubtitle;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @faqSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore services and answers to FAQs'**
  String get faqSubtitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How we collect and use your data'**
  String get privacyPolicySubtitle;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @termsAndConditionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Protecting rights and legal framework'**
  String get termsAndConditionsSubtitle;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @shareAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell friends and get rewards'**
  String get shareAppSubtitle;

  /// No description provided for @supportTicketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Support Tickets'**
  String get supportTicketsTitle;

  /// No description provided for @supportTicketsHint.
  ///
  /// In en, this message translates to:
  /// **'Tickets are available for 24 hours, then they will be closed...'**
  String get supportTicketsHint;

  /// No description provided for @noSupportTickets.
  ///
  /// In en, this message translates to:
  /// **'No support tickets.'**
  String get noSupportTickets;

  /// No description provided for @openNewTicketTitle.
  ///
  /// In en, this message translates to:
  /// **'Open New Ticket'**
  String get openNewTicketTitle;

  /// No description provided for @ticketSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get ticketSubject;

  /// No description provided for @ticketSubjectRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the subject'**
  String get ticketSubjectRequired;

  /// No description provided for @ticketMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get ticketMessage;

  /// No description provided for @ticketMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the message'**
  String get ticketMessageRequired;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @walletAndRewardPoints.
  ///
  /// In en, this message translates to:
  /// **'Wallet & Reward Points'**
  String get walletAndRewardPoints;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @sar.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get sar;

  /// No description provided for @withdrawBalance.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Balance'**
  String get withdrawBalance;

  /// No description provided for @rewardPoints.
  ///
  /// In en, this message translates to:
  /// **'Reward Points'**
  String get rewardPoints;

  /// No description provided for @yourRewardPoints.
  ///
  /// In en, this message translates to:
  /// **'Your Reward Points'**
  String get yourRewardPoints;

  /// No description provided for @paymentCards.
  ///
  /// In en, this message translates to:
  /// **'Payment Cards'**
  String get paymentCards;

  /// No description provided for @topUpWallet.
  ///
  /// In en, this message translates to:
  /// **'Top Up Wallet'**
  String get topUpWallet;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @purchaseOrders.
  ///
  /// In en, this message translates to:
  /// **'Purchase Orders'**
  String get purchaseOrders;

  /// No description provided for @trackShipping.
  ///
  /// In en, this message translates to:
  /// **'Track purchase orders and shipping.'**
  String get trackShipping;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @browseFavorites.
  ///
  /// In en, this message translates to:
  /// **'Browse categories and add your favorite offers here'**
  String get browseFavorites;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @yourReviews.
  ///
  /// In en, this message translates to:
  /// **'Your reviews on recent bookings.'**
  String get yourReviews;

  /// No description provided for @topUpAmount.
  ///
  /// In en, this message translates to:
  /// **'Top Up Amount'**
  String get topUpAmount;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @withdrawalAmount.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal Amount'**
  String get withdrawalAmount;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment successful!'**
  String get paymentSuccessful;

  /// No description provided for @insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance.'**
  String get insufficientBalance;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Your recent transactions this month'**
  String get recentTransactions;

  /// No description provided for @transactionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled and amount returned to your wallet'**
  String get transactionCancelled;

  /// No description provided for @transactionCost.
  ///
  /// In en, this message translates to:
  /// **'SAR booking cost'**
  String get transactionCost;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @bookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'You cancelled the booking on Wednesday'**
  String get bookingCancelled;

  /// No description provided for @refundProcessed.
  ///
  /// In en, this message translates to:
  /// **'100 SAR refunded to wallet and 10 SAR cancellation fee deducted'**
  String get refundProcessed;

  /// No description provided for @bookingPaid.
  ///
  /// In en, this message translates to:
  /// **'Appointment booking payment made'**
  String get bookingPaid;

  /// No description provided for @bookingCost.
  ///
  /// In en, this message translates to:
  /// **'SAR booking cost'**
  String get bookingCost;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
