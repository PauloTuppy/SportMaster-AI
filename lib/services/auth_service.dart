import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Estado atual do usuário
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Usuário atual
  User? get currentUser => _auth.currentUser;
  
  // Registro com email e senha
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, Map<String, dynamic> userData) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Criar perfil do usuário no Firestore
      await _createUserProfile(userCredential.user!.uid, userData);
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Login com email e senha
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Login com Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Login cancelado pelo usuário');
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Verificar se é um novo usuário
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserProfile(userCredential.user!.uid, {
          'name': userCredential.user?.displayName,
          'email': userCredential.user?.email,
          'photo_url': userCredential.user?.photoURL,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      
      return userCredential;
    } catch (e) {
      throw Exception('Erro no login com Google: $e');
    }
  }
  
  // Logout
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
  
  // Criar perfil do usuário no Firestore
  Future<void> _createUserProfile(String uid, Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(uid).set({
      ...userData,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
  
  // Atualizar dados do usuário