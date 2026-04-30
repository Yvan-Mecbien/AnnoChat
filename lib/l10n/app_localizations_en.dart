// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AnonChat';

  @override
  String get welcomeBack => 'Welcome back!';

  @override
  String get loginSubtitle => 'Log in to access your space.';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get login => 'Log in';

  @override
  String get noAccount => 'No account? Sign up';

  @override
  String get createAccount => 'Create account';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get alreadyAccount => 'Already have an account? Log in';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get min3chars => 'Minimum 3 characters';

  @override
  String get min6chars => 'Minimum 6 characters';

  @override
  String get invalidChars => 'Invalid characters (letters, numbers, _ . - only)';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String helloUser(String username) {
    return 'Hello, $username 👋';
  }

  @override
  String get homeSubtitle => 'Share your link and receive anonymous messages.';

  @override
  String get yourLink => 'YOUR LINK';

  @override
  String get shareLink => 'Share my link';

  @override
  String get viewConversations => 'My conversations';

  @override
  String get linkCopied => 'Link copied!';

  @override
  String get shareMessage => 'Send me an anonymous message 🔒';

  @override
  String get anonymityInfo => 'Visitors stay anonymous to you. You cannot see their identity.';

  @override
  String get conversations => 'Conversations';

  @override
  String get noConversations => 'No conversations yet.';

  @override
  String get noConversationsHint => 'Share your link to receive messages.';

  @override
  String get refresh => 'Refresh';

  @override
  String get retry => 'Retry';

  @override
  String get online => 'Online';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get typing => 'Typing...';

  @override
  String get messagePlaceholder => 'Message...';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get noMessagesHint => 'Be the first to write!';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get language => 'Language';

  @override
  String get account => 'Account';

  @override
  String get myChatLink => 'My chat link';

  @override
  String get session => 'Session';

  @override
  String get logout => 'Log out';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmBody => 'You will be redirected to the login page.';

  @override
  String get cancel => 'Cancel';

  @override
  String get activeAccount => 'Active account';

  @override
  String get version => 'AnonChat v1.0.0';
}
