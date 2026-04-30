// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'AnonChat';

  @override
  String get welcomeBack => 'Bon retour !';

  @override
  String get loginSubtitle => 'Connectez-vous pour accéder à votre espace.';

  @override
  String get username => 'Pseudo';

  @override
  String get password => 'Mot de passe';

  @override
  String get login => 'Se connecter';

  @override
  String get noAccount => 'Pas de compte ? S\'inscrire';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get alreadyAccount => 'Déjà un compte ? Se connecter';

  @override
  String get fieldRequired => 'Ce champ est requis';

  @override
  String get min3chars => 'Minimum 3 caractères';

  @override
  String get min6chars => 'Minimum 6 caractères';

  @override
  String get invalidChars => 'Caractères invalides (lettres, chiffres, _ . - uniquement)';

  @override
  String get passwordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String helloUser(String username) {
    return 'Bonjour, $username 👋';
  }

  @override
  String get homeSubtitle => 'Partagez votre lien et recevez des messages anonymes.';

  @override
  String get yourLink => 'VOTRE LIEN';

  @override
  String get shareLink => 'Partager mon lien';

  @override
  String get viewConversations => 'Mes conversations';

  @override
  String get linkCopied => 'Lien copié !';

  @override
  String get shareMessage => 'Envoie-moi un message anonyme 🔒';

  @override
  String get anonymityInfo => 'Les visiteurs restent anonymes pour vous. Vous ne voyez pas leur identité.';

  @override
  String get conversations => 'Conversations';

  @override
  String get noConversations => 'Aucune conversation pour l\'instant.';

  @override
  String get noConversationsHint => 'Partagez votre lien pour recevoir des messages.';

  @override
  String get refresh => 'Rafraîchir';

  @override
  String get retry => 'Réessayer';

  @override
  String get online => 'En ligne';

  @override
  String get anonymous => 'Anonyme';

  @override
  String get typing => 'En train d\'écrire...';

  @override
  String get messagePlaceholder => 'Message...';

  @override
  String get noMessages => 'Aucun message pour l\'instant';

  @override
  String get noMessagesHint => 'Soyez le premier à écrire !';

  @override
  String get settings => 'Paramètres';

  @override
  String get appearance => 'Apparence';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get language => 'Langue';

  @override
  String get account => 'Compte';

  @override
  String get myChatLink => 'Mon lien de chat';

  @override
  String get session => 'Session';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get logoutConfirmTitle => 'Se déconnecter ?';

  @override
  String get logoutConfirmBody => 'Vous serez redirigé vers la page de connexion.';

  @override
  String get cancel => 'Annuler';

  @override
  String get activeAccount => 'Compte actif';

  @override
  String get version => 'AnonChat v1.0.0';
}
