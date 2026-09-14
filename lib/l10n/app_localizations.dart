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
      'purchases': 'Achats',
      'invoices': 'Factures',
      'payments': 'Paiements',
      'stock': 'Stock',
      'operatorStock': 'Mon stock',
      'loadingOrders': 'Bons de chargement',
      'expenses': 'Charges',
      'printers': 'Imprimantes',
      'section_home': 'Accueil',
      'section_commerce': 'Commerce',
      'section_operations': 'Opérations',
      'section_management': 'Gestion',
      'section_account': 'Compte',
      'search': 'Rechercher',
      'loadMore': 'Charger la suite',
      'forbiddenMessage':
          'Vous n’avez pas l’autorisation d’accéder à cette rubrique.',
      'accessDenied': 'Accès refusé',
      'logoutConfirm': 'Voulez-vous vous déconnecter ?',
      'cancel': 'Annuler',
      'reference': 'Référence',
      'quantity': 'Quantité',
      'price': 'Prix',
      'phone': 'Téléphone',
      'address': 'Adresse',
      'customerType': 'Type de client',
      'client': 'Client',
      'supplier': 'Fournisseur',
      'total': 'Total',
      'date': 'Date',
      'status': 'Statut',
      'model': 'Modèle',
      'connection': 'Connexion',
      'paperWidth': 'Largeur papier',
      'configured': 'Configurée',
      'notConfigured': 'Non configurée',
      'loaded': 'Chargé',
      'sold': 'Vendu',
      'remaining': 'Restant',
      'returned': 'Retourné',
      'operator': 'Opérateur',
      'noDefaultPrinter': 'Aucune imprimante active par défaut.',
      'apiError': 'Impossible de charger les données.',
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
      'purchases': 'المشتريات',
      'invoices': 'الفواتير',
      'payments': 'المدفوعات',
      'stock': 'المخزون',
      'operatorStock': 'مخزوني',
      'loadingOrders': 'سندات التحميل',
      'expenses': 'المصاريف',
      'printers': 'الطابعات',
      'section_home': 'الرئيسية',
      'section_commerce': 'التجارة',
      'section_operations': 'العمليات',
      'section_management': 'الإدارة',
      'section_account': 'الحساب',
      'search': 'بحث',
      'loadMore': 'تحميل المزيد',
      'forbiddenMessage': 'ليس لديك إذن للوصول إلى هذا القسم.',
      'accessDenied': 'تم رفض الوصول',
      'logoutConfirm': 'هل تريد تسجيل الخروج؟',
      'cancel': 'إلغاء',
      'reference': 'المرجع',
      'quantity': 'الكمية',
      'price': 'السعر',
      'phone': 'الهاتف',
      'address': 'العنوان',
      'customerType': 'نوع العميل',
      'client': 'العميل',
      'supplier': 'المورد',
      'total': 'الإجمالي',
      'date': 'التاريخ',
      'status': 'الحالة',
      'model': 'الطراز',
      'connection': 'الاتصال',
      'paperWidth': 'عرض الورق',
      'configured': 'مهيأة',
      'notConfigured': 'غير مهيأة',
      'loaded': 'المحمّل',
      'sold': 'المباع',
      'remaining': 'المتبقي',
      'returned': 'المرتجع',
      'operator': 'المشغل',
      'noDefaultPrinter': 'لا توجد طابعة افتراضية نشطة.',
      'apiError': 'تعذر تحميل البيانات.',
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
      'purchases': 'Purchases',
      'invoices': 'Invoices',
      'payments': 'Payments',
      'stock': 'Stock',
      'operatorStock': 'My stock',
      'loadingOrders': 'Loading orders',
      'expenses': 'Expenses',
      'printers': 'Printers',
      'section_home': 'Home',
      'section_commerce': 'Commerce',
      'section_operations': 'Operations',
      'section_management': 'Management',
      'section_account': 'Account',
      'search': 'Search',
      'loadMore': 'Load more',
      'forbiddenMessage': 'You are not allowed to access this section.',
      'accessDenied': 'Access denied',
      'logoutConfirm': 'Do you want to sign out?',
      'cancel': 'Cancel',
      'reference': 'Reference',
      'quantity': 'Quantity',
      'price': 'Price',
      'phone': 'Phone',
      'address': 'Address',
      'customerType': 'Customer type',
      'client': 'Client',
      'supplier': 'Supplier',
      'total': 'Total',
      'date': 'Date',
      'status': 'Status',
      'model': 'Model',
      'connection': 'Connection',
      'paperWidth': 'Paper width',
      'configured': 'Configured',
      'notConfigured': 'Not configured',
      'loaded': 'Loaded',
      'sold': 'Sold',
      'remaining': 'Remaining',
      'returned': 'Returned',
      'operator': 'Operator',
      'noDefaultPrinter': 'No active default printer.',
      'apiError': 'Unable to load data.',
    },
  };
  String _get(String key) =>
      _values[locale.languageCode]?[key] ?? _values['fr']![key]!;
  String text(String key) => _get(key);
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
