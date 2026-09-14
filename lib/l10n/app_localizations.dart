import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);
  final Locale locale;
  static const supportedLocales = [Locale('fr'), Locale('ar'), Locale('en')];
  static const delegate = _AppLocalizationsDelegate();
  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const _values = <String, Map<String, String>>{
    'fr': {
      'app': 'EL AMINE',
      'login': 'Connexion',
      'username': 'Nom d’utilisateur',
      'password': 'Mot de passe',
      'signIn': 'Se connecter',
      'dashboard': 'Tableau de bord',
      'profile': 'Mon profil',
      'logout': 'Déconnexion',
      'retry': 'Réessayer',
      'loading': 'Chargement…',
      'empty': 'Aucune donnée disponible',
      'revenue': 'Chiffre d’affaires',
      'sales': 'Ventes',
      'basket': 'Panier moyen',
      'netProfit': 'Bénéfice net',
      'products': 'Produits',
      'clients': 'Clients',
      'suppliers': 'Fournisseurs',
      'welcome': 'Bienvenue',
      'sessionExpired': 'Votre session a expiré. Reconnectez-vous.',
      'required': 'Ce champ est obligatoire.',
      'language': 'Langue',
    },
    'ar': {
      'app': 'الأمين',
      'login': 'تسجيل الدخول',
      'username': 'اسم المستخدم',
      'password': 'كلمة المرور',
      'signIn': 'دخول',
      'dashboard': 'لوحة القيادة',
      'profile': 'ملفي الشخصي',
      'logout': 'تسجيل الخروج',
      'retry': 'إعادة المحاولة',
      'loading': 'جار التحميل…',
      'empty': 'لا توجد بيانات',
      'revenue': 'رقم الأعمال',
      'sales': 'المبيعات',
      'basket': 'متوسط السلة',
      'netProfit': 'صافي الربح',
      'products': 'المنتجات',
      'clients': 'العملاء',
      'suppliers': 'الموردون',
      'welcome': 'مرحباً',
      'sessionExpired': 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.',
      'required': 'هذا الحقل مطلوب.',
      'language': 'اللغة',
    },
    'en': {
      'app': 'EL AMINE',
      'login': 'Sign in',
      'username': 'Username',
      'password': 'Password',
      'signIn': 'Sign in',
      'dashboard': 'Dashboard',
      'profile': 'My profile',
      'logout': 'Sign out',
      'retry': 'Retry',
      'loading': 'Loading…',
      'empty': 'No data available',
      'revenue': 'Revenue',
      'sales': 'Sales',
      'basket': 'Average basket',
      'netProfit': 'Net profit',
      'products': 'Products',
      'clients': 'Clients',
      'suppliers': 'Suppliers',
      'welcome': 'Welcome',
      'sessionExpired': 'Your session expired. Please sign in again.',
      'required': 'This field is required.',
      'language': 'Language',
    },
  };
  String _get(String key) =>
      _values[locale.languageCode]?[key] ?? _values['fr']![key]!;
  String get app => _get('app');
  String get login => _get('login');
  String get username => _get('username');
  String get password => _get('password');
  String get signIn => _get('signIn');
  String get dashboard => _get('dashboard');
  String get profile => _get('profile');
  String get logout => _get('logout');
  String get retry => _get('retry');
  String get loading => _get('loading');
  String get empty => _get('empty');
  String get revenue => _get('revenue');
  String get sales => _get('sales');
  String get basket => _get('basket');
  String get netProfit => _get('netProfit');
  String get products => _get('products');
  String get clients => _get('clients');
  String get suppliers => _get('suppliers');
  String get welcome => _get('welcome');
  String get sessionExpired => _get('sessionExpired');
  String get required => _get('required');
  String get language => _get('language');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) =>
      {'fr', 'ar', 'en'}.contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
