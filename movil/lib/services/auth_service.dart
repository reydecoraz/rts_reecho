import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  late final FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final SupabaseClient _supabase = Supabase.instance.client;

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthService() {
    if (Firebase.apps.isNotEmpty) {
      _auth = FirebaseAuth.instance;
      _auth!.authStateChanges().listen((User? user) {
        _user = user;
        notifyListeners();
      });
    } else {
      _auth = null;
      debugPrint('AuthService: Firebase not initialized, running in guest/limited mode.');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (_auth == null) {
        throw Exception('Firebase is not initialized. Cannot sign in.');
      }
      final UserCredential userCredential = await _auth!.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        await _syncProfile(user);
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    if (_auth != null) {
      await _auth!.signOut();
    }
  }

  Future<void> _syncProfile(User firebaseUser) async {
    // We check if a profile exists in Supabase for this user.
    // Since we are using Firebase Auth, we'll try to use the Firebase UID.
    // Note: If the Supabase profiles.id is a UUID, this might fail if Firebase UID is not a valid UUID.
    // However, in this schema, profiles.id is 'text'.
    
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', firebaseUser.uid)
        .maybeSingle();

    if (response == null) {
      // Create new profile
      await _supabase.from('profiles').insert({
        'id': firebaseUser.uid,
        'username': firebaseUser.displayName ?? 'Player_${firebaseUser.uid.substring(0, 5)}',
        'avatar_url': firebaseUser.photoURL,
        'galeones': 0,
        'gemas': 0,
        'xp': 0,
        'total_matches': 0,
        'wins': 0,
      });
    }
  }
  
  // Method to get user data from Supabase
  Future<Map<String, dynamic>?> getProfileData() async {
    if (_user == null) return null;
    return await _supabase
        .from('profiles')
        .select()
        .eq('id', _user!.uid)
        .maybeSingle();
  }
}
