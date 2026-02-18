// lib/core/services/language_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  
  // Supported languages
  static const Map<String, Map<String, String>> languages = {
    'en': {'name': 'English', 'nativeName': 'English', 'flag': '🇬🇧'},
    'fr': {'name': 'French', 'nativeName': 'Français', 'flag': '🇫🇷'},
    'rw': {'name': 'Kinyarwanda', 'nativeName': 'Ikinyarwanda', 'flag': '🇷🇼'},
  };
  
  // Save selected language
  static Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }
  
  // Get selected language
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'en';
  }
  
  // Get translation
  static String translate(String key, String languageCode) {
    return _translations[languageCode]?[key] ?? 
           _translations['en']?[key] ?? 
           key;
  }
  
  // ========================================
  // COMPLETE TRANSLATIONS
  // ========================================
  static const Map<String, Map<String, String>> _translations = {
    
    // ========================================
    // ENGLISH
    // ========================================
    'en': {
      // Navigation
      'home': 'Home',
      'bookings': 'Bookings',
      'my_rides': 'My Rides',
      'wallet': 'Wallet',
      'more': 'More',
      
      // Auth
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'username': 'Username',
      'phone': 'Phone Number',
      'phone_number': 'Phone Number',
      'logout': 'Logout',
      'welcome_back': 'Welcome Back',
      'create_account': 'Create Account',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      
      // Roles
      'passenger': 'Passenger',
      'driver': 'Driver',
      'select_role': 'Select Role',
      
      // Home Screen
      'welcome': 'Welcome',
      'search_rides': 'Search Rides',
      'available_rides': 'Available Rides',
      'no_rides_available': 'No rides available yet',
      'create_ride': 'Create Ride',
      'my_bookings': 'My Bookings',
      
      // Booking & Rides
      'book_ride': 'Book Ride',
      'from': 'From',
      'to': 'To',
      'destination': 'Destination',
      'departure': 'Departure',
      'departure_time': 'Departure Time',
      'seats': 'Seats',
      'seats_available': 'seats available',
      'price': 'Price',
      'price_per_seat': 'Price per Seat',
      'book_now': 'Book Now',
      'book': 'Book',
      'schedule_ride': 'Schedule Ride',
      'track_ride': 'Track Ride',
      'start_location': 'Start Location',
      'available_seats': 'Available Seats',
      'total_price': 'Total Price',
      'select_seats': 'Select Seats',
      'how_many_seats': 'How many seats do you want to book?',
      'confirm': 'Confirm',
      'confirm_booking': 'Confirm Booking',
      
      // Status
      'pending': 'Pending',
      'confirmed': 'Confirmed',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'rejected': 'Rejected',
      'active': 'Active',
      'status': 'Status',
      
      // Wallet
      'add_money': 'Add Money',
      'withdraw': 'Withdraw',
      'balance': 'Balance',
      'total_earnings': 'Total Earnings',
      'total_spent': 'Total Spent',
      'recent_transactions': 'Recent Transactions',
      'no_transactions': 'No transactions yet',
      'transaction_history': 'Transaction History',
      'amount': 'Amount',
      'payment_method': 'Payment Method',
      'withdraw_money': 'Withdraw Money',
      
      // Chat & Messages
      'chat': 'Chat',
      'type_message': 'Type a message...',
      'send': 'Send',
      'messages': 'Messages',
      'no_messages': 'No messages yet',
      'chat_with_driver': 'Chat with Driver',
      'chat_with_passenger': 'Chat with Passenger',
      
      // Profile & Settings
      'edit_profile': 'Edit Profile',
      'my_ratings': 'My Ratings',
      'settings': 'Settings',
      'help_support': 'Help & Support',
      'about': 'About ISHARE',
      'terms': 'Terms of Service',
      'privacy': 'Privacy Policy',
      'language': 'Language',
      'notifications': 'Notifications',
      'push_notifications': 'Push Notifications',
      'email_notifications': 'Email Notifications',
      'sms_notifications': 'SMS Notifications',
      'location_services': 'Location Services',
      'dark_mode': 'Dark Mode',
      'change_password': 'Change Password',
      'delete_account': 'Delete Account',
      
      // Scheduling
      'schedule_for': 'Schedule For',
      'schedule_type': 'Schedule Type',
      'daily': 'Daily',
      'weekend': 'Weekend',
      'monthly': 'Monthly',
      'select_days': 'Select Days',
      'start_date': 'Start Date',
      'end_date': 'End Date',
      'repeat': 'Repeat',
      'one_time': 'One-time Ride',
      'recurring': 'Recurring Rides',
      
      // Tracking & Safety
      'live_tracking': 'Live Tracking',
      'track_live': 'Track Live',
      'sos': 'SOS',
      'emergency': 'Emergency',
      'emergency_contacts': 'Emergency Contacts',
      'sos_activated': 'SOS ACTIVATED',
      'call_police': 'Call Police',
      'share_location': 'Share Location',
      'add_contact': 'Add Contact',
      'call': 'Call',
      
      // Actions
      'save': 'Save',
      'cancel': 'Cancel',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'remove': 'Remove',
      'update': 'Update',
      'search': 'Search',
      'filter': 'Filter',
      'apply': 'Apply',
      'close': 'Close',
      'accept': 'Accept',
      'reject': 'Reject',
      'complete': 'Complete',
      
      // Common
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'failed': 'Failed',
      'please_wait': 'Please wait...',
      'retry': 'Retry',
      'refresh': 'Refresh',
      'view_all': 'View All',
      'see_more': 'See More',
      'show_less': 'Show Less',
      
      // Messages & Alerts
      'booking_successful': 'Booking successful!',
      'ride_created': 'Ride created successfully!',
      'profile_updated': 'Profile updated successfully!',
      'are_you_sure': 'Are you sure?',
      'cannot_undo': 'This action cannot be undone',
      'something_went_wrong': 'Something went wrong',
      'try_again': 'Try again',
      'no_data': 'No data available',
      'coming_soon': 'Coming soon!',
    },
    
    // ========================================
    // FRENCH (FRANÇAIS)
    // ========================================
    'fr': {
      // Navigation
      'home': 'Accueil',
      'bookings': 'Réservations',
      'my_rides': 'Mes Trajets',
      'wallet': 'Portefeuille',
      'more': 'Plus',
      
      // Auth
      'login': 'Connexion',
      'register': 'S\'inscrire',
      'email': 'Email',
      'password': 'Mot de passe',
      'username': 'Nom d\'utilisateur',
      'phone': 'Téléphone',
      'phone_number': 'Numéro de téléphone',
      'logout': 'Déconnexion',
      'welcome_back': 'Bon retour',
      'create_account': 'Créer un compte',
      'dont_have_account': "Vous n'avez pas de compte?",
      'already_have_account': 'Vous avez déjà un compte?',
      
      // Roles
      'passenger': 'Passager',
      'driver': 'Conducteur',
      'select_role': 'Sélectionner le rôle',
      
      // Home Screen
      'welcome': 'Bienvenue',
      'search_rides': 'Rechercher des trajets',
      'available_rides': 'Trajets disponibles',
      'no_rides_available': 'Aucun trajet disponible',
      'create_ride': 'Créer un trajet',
      'my_bookings': 'Mes réservations',
      
      // Booking & Rides
      'book_ride': 'Réserver un trajet',
      'from': 'De',
      'to': 'À',
      'destination': 'Destination',
      'departure': 'Départ',
      'departure_time': 'Heure de départ',
      'seats': 'Places',
      'seats_available': 'places disponibles',
      'price': 'Prix',
      'price_per_seat': 'Prix par place',
      'book_now': 'Réserver maintenant',
      'book': 'Réserver',
      'schedule_ride': 'Planifier un trajet',
      'track_ride': 'Suivre le trajet',
      'start_location': 'Lieu de départ',
      'available_seats': 'Places disponibles',
      'total_price': 'Prix total',
      'select_seats': 'Sélectionner les places',
      'how_many_seats': 'Combien de places voulez-vous réserver?',
      'confirm': 'Confirmer',
      'confirm_booking': 'Confirmer la réservation',
      
      // Status
      'pending': 'En attente',
      'confirmed': 'Confirmé',
      'completed': 'Terminé',
      'cancelled': 'Annulé',
      'rejected': 'Rejeté',
      'active': 'Actif',
      'status': 'Statut',
      
      // Wallet
      'add_money': 'Ajouter de l\'argent',
      'withdraw': 'Retirer',
      'balance': 'Solde',
      'total_earnings': 'Gains totaux',
      'total_spent': 'Total dépensé',
      'recent_transactions': 'Transactions récentes',
      'no_transactions': 'Aucune transaction',
      'transaction_history': 'Historique des transactions',
      'amount': 'Montant',
      'payment_method': 'Mode de paiement',
      'withdraw_money': 'Retirer de l\'argent',
      
      // Chat & Messages
      'chat': 'Chat',
      'type_message': 'Tapez un message...',
      'send': 'Envoyer',
      'messages': 'Messages',
      'no_messages': 'Aucun message',
      'chat_with_driver': 'Discuter avec le conducteur',
      'chat_with_passenger': 'Discuter avec le passager',
      
      // Profile & Settings
      'edit_profile': 'Modifier le profil',
      'my_ratings': 'Mes notes',
      'settings': 'Paramètres',
      'help_support': 'Aide et support',
      'about': 'À propos d\'ISHARE',
      'terms': 'Conditions d\'utilisation',
      'privacy': 'Politique de confidentialité',
      'language': 'Langue',
      'notifications': 'Notifications',
      'push_notifications': 'Notifications push',
      'email_notifications': 'Notifications par email',
      'sms_notifications': 'Notifications SMS',
      'location_services': 'Services de localisation',
      'dark_mode': 'Mode sombre',
      'change_password': 'Changer le mot de passe',
      'delete_account': 'Supprimer le compte',
      
      // Scheduling
      'schedule_for': 'Planifier pour',
      'schedule_type': 'Type de planification',
      'daily': 'Quotidien',
      'weekend': 'Week-end',
      'monthly': 'Mensuel',
      'select_days': 'Sélectionner les jours',
      'start_date': 'Date de début',
      'end_date': 'Date de fin',
      'repeat': 'Répéter',
      'one_time': 'Trajet unique',
      'recurring': 'Trajets récurrents',
      
      // Tracking & Safety
      'live_tracking': 'Suivi en direct',
      'track_live': 'Suivre en direct',
      'sos': 'SOS',
      'emergency': 'Urgence',
      'emergency_contacts': 'Contacts d\'urgence',
      'sos_activated': 'SOS ACTIVÉ',
      'call_police': 'Appeler la police',
      'share_location': 'Partager la localisation',
      'add_contact': 'Ajouter un contact',
      'call': 'Appeler',
      
      // Actions
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'ok': 'OK',
      'yes': 'Oui',
      'no': 'Non',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'add': 'Ajouter',
      'remove': 'Retirer',
      'update': 'Mettre à jour',
      'search': 'Rechercher',
      'filter': 'Filtrer',
      'apply': 'Appliquer',
      'close': 'Fermer',
      'accept': 'Accepter',
      'reject': 'Rejeter',
      'complete': 'Terminer',
      
      // Common
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',
      'failed': 'Échoué',
      'please_wait': 'Veuillez patienter...',
      'retry': 'Réessayer',
      'refresh': 'Actualiser',
      'view_all': 'Voir tout',
      'see_more': 'Voir plus',
      'show_less': 'Voir moins',
      
      // Messages & Alerts
      'booking_successful': 'Réservation réussie!',
      'ride_created': 'Trajet créé avec succès!',
      'profile_updated': 'Profil mis à jour!',
      'are_you_sure': 'Êtes-vous sûr?',
      'cannot_undo': 'Cette action est irréversible',
      'something_went_wrong': 'Quelque chose s\'est mal passé',
      'try_again': 'Réessayer',
      'no_data': 'Aucune donnée disponible',
      'coming_soon': 'Bientôt disponible!',
    },
    
    // ========================================
    // KINYARWANDA
    // ========================================
    'rw': {
      // Navigation
      'home': 'Ahabanza',
      'bookings': 'Aho natumije',
      'my_rides': 'Ingendo zanjye',
      'wallet': 'Amafaranga',
      'more': 'Ibindi',
      
      // Auth
      'login': 'Injira',
      'register': 'Iyandikishe',
      'email': 'Imeyili',
      'password': 'Ijambo ryibanga',
      'username': 'Izina',
      'phone': 'Telephone',
      'phone_number': 'Numero ya telephone',
      'logout': 'Sohoka',
      'welcome_back': 'Turakwakira',
      'create_account': 'Fungura konti',
      'dont_have_account': 'Nta konti ufite?',
      'already_have_account': 'Ufite konti?',
      
      // Roles
      'passenger': 'Umugenzi',
      'driver': 'Umushoferi',
      'select_role': 'Hitamo uruhare',
      
      // Home Screen
      'welcome': 'Murakaza neza',
      'search_rides': 'Shakisha ingendo',
      'available_rides': 'Ingendo zihari',
      'no_rides_available': 'Nta ngendo zihari',
      'create_ride': 'Shiraho urugendo',
      'my_bookings': 'Aho natumije',
      
      // Booking & Rides
      'book_ride': 'Tuma urugendo',
      'from': 'Kuva',
      'to': 'Kugera',
      'destination': 'Aho ugana',
      'departure': 'Igihe',
      'departure_time': 'Igihe cyo kugenda',
      'seats': 'Imyanya',
      'seats_available': 'imyanya irahari',
      'price': 'Igiciro',
      'price_per_seat': 'Igiciro cyumwanya',
      'book_now': 'Tuma ubu',
      'book': 'Tuma',
      'schedule_ride': 'Tegura urugendo',
      'track_ride': 'Kurikirana urugendo',
      'start_location': 'Aho utangira',
      'available_seats': 'Imyanya irahari',
      'total_price': 'Igiciro cyose',
      'select_seats': 'Hitamo imyanya',
      'how_many_seats': 'Ni imyanya ingahe ushaka?',
      'confirm': 'Emeza',
      'confirm_booking': 'Emeza gutumiza',
      
      // Status
      'pending': 'Birategerejwe',
      'confirmed': 'Byemejwe',
      'completed': 'Byarangiye',
      'cancelled': 'Byahagaritswe',
      'rejected': 'Byanze',
      'active': 'Birakora',
      'status': 'Uko bimeze',
      
      // Wallet
      'add_money': 'Ongeramo amafaranga',
      'withdraw': 'Kuramo amafaranga',
      'balance': 'Amafaranga asigaye',
      'total_earnings': 'Amafaranga yose',
      'total_spent': 'Amafaranga yakoresheje',
      'recent_transactions': 'Ibikorwa byaherutse',
      'no_transactions': 'Nta bikorwa',
      'transaction_history': 'Amateka yibikorwa',
      'amount': 'Amafaranga',
      'payment_method': 'Uburyo bwo kwishyura',
      'withdraw_money': 'Kuramo amafaranga',
      
      // Chat & Messages
      'chat': 'Ganira',
      'type_message': 'Andika ubutumwa...',
      'send': 'Ohereza',
      'messages': 'Ubutumwa',
      'no_messages': 'Nta butumwa',
      'chat_with_driver': 'Ganira numushoferi',
      'chat_with_passenger': 'Ganira numugenzi',
      
      // Profile & Settings
      'edit_profile': 'Hindura umwirondoro',
      'my_ratings': 'Amanota yanjye',
      'settings': 'Igenamiterere',
      'help_support': 'Ubufasha',
      'about': 'Ibyerekeye ISHARE',
      'terms': 'Amabwiriza',
      'privacy': 'Ibanga',
      'language': 'Ururimi',
      'notifications': 'Imenyesha',
      'push_notifications': 'Imenyesha zikora',
      'email_notifications': 'Imenyesha kuri imeyili',
      'sms_notifications': 'Imenyesha kuri SMS',
      'location_services': 'Serivisi yaho uriho',
      'dark_mode': 'Umuyaga wumukara',
      'change_password': 'Hindura ijambo ryibanga',
      'delete_account': 'Siba konti',
      
      // Scheduling
      'schedule_for': 'Tegura kuri',
      'schedule_type': 'Ubwoko bwo gutegura',
      'daily': 'Buri munsi',
      'weekend': 'Wikendi',
      'monthly': 'Buri kwezi',
      'select_days': 'Hitamo iminsi',
      'start_date': 'Itariki yo gutangira',
      'end_date': 'Itariki yo kurangiza',
      'repeat': 'Subiramo',
      'one_time': 'Urugendo rumwe',
      'recurring': 'Ingendo zisubiramo',
      
      // Tracking & Safety
      'live_tracking': 'Gukurikirana mu gihe nyacyo',
      'track_live': 'Kurikirana live',
      'sos': 'SOS',
      'emergency': 'Akaga',
      'emergency_contacts': 'Abo wahamagara mugihe cyakaga',
      'sos_activated': 'SOS YAKOZE',
      'call_police': 'Hamagara polisi',
      'share_location': 'Sangiza aho uriho',
      'add_contact': 'Ongeraho uwahamagara',
      'call': 'Hamagara',
      
      // Actions
      'save': 'Bika',
      'cancel': 'Hagarika',
      'ok': 'Yego',
      'yes': 'Yego',
      'no': 'Oya',
      'delete': 'Siba',
      'edit': 'Hindura',
      'add': 'Ongeraho',
      'remove': 'Kuraho',
      'update': 'Kugira nshya',
      'search': 'Shakisha',
      'filter': 'Shyungura',
      'apply': 'Koresha',
      'close': 'Funga',
      'accept': 'Emera',
      'reject': 'Anga',
      'complete': 'Kurangiza',
      
      // Common
      'loading': 'Birategerejwe...',
      'error': 'Ikosa',
      'success': 'Byagenze neza',
      'failed': 'Byanze',
      'please_wait': 'Tegereza...',
      'retry': 'Ongera ugerageze',
      'refresh': 'Kugira nshya',
      'view_all': 'Reba byose',
      'see_more': 'Reba byinshi',
      'show_less': 'Reba bike',
      
      // Messages & Alerts
      'booking_successful': 'Gutumiza byagenze neza!',
      'ride_created': 'Urugendo rwarakozwe!',
      'profile_updated': 'Umwirondoro wahindutse!',
      'are_you_sure': 'Urabizi neza?',
      'cannot_undo': 'Ntushobora kubisubiza',
      'something_went_wrong': 'Hari icyaananiye',
      'try_again': 'Ongera ugerageze',
      'no_data': 'Nta makuru',
      'coming_soon': 'Bizaza vuba!',
    },
  };
}