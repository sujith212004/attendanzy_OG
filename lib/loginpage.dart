import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:shared_preferences/shared_preferences.dart';
import 'homepage.dart';
import 'changepassword.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isPasswordVisible = false;
  int _selectedRoleIndex = 0; // 0 for User, 1 for Staff
  mongo.Db? _db;
  bool _isLoading = false;

  final String mongoUri =
      "mongodb+srv://digioptimized:digi123@cluster0.iuajg.mongodb.net/attendance_DB?retryWrites=true&w=majority";

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _db?.close();
    super.dispose();
  }

  Future<void> _initializeDatabase() async {
    try {
      print('Connecting to MongoDB...');
      _db = await mongo.Db.create(mongoUri);
      await _db!.open();
      print('Connected to MongoDB');
    } catch (e) {
      print('Failed to connect to MongoDB: $e');
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final name = prefs.getString('name');

    if (email != null && name != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => HomePage(
                name: name,
                email: email,
                profile: {},
                isStaff: false,
              ),
        ),
      );
    }
  }

  void _login() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String selectedRole = _selectedRoleIndex == 0 ? 'User' : 'Staff';

    if (email.isNotEmpty && password.isNotEmpty) {
      try {
        final String collectionName =
            selectedRole == 'Staff' ? 'Staff' : 'profile';
        final collection = _db!.collection(collectionName);

        final user = await collection.findOne({
          "College Email": {"\$regex": "^$email\$", "\$options": "i"},
          "Password": password,
        });

        setState(() {
          _isLoading = false;
        });

        if (user != null) {
          print('User found: $user'); // Debug print
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', email);
          await prefs.setString('name', user["Name"]);

          // Redirect to password change page only for users (not staff) on first login
          if (selectedRole == 'User' && user['firstLogin'] == true) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ChangePasswordPage(
                      email: email,
                      db: _db,
                      collectionName: collectionName,
                      isStaff: selectedRole == 'Staff',
                    ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => HomePage(
                      name: user["Name"],
                      email: user["College Email"],
                      profile: user,
                      isStaff: selectedRole == 'Staff',
                    ),
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage =
                'Invalid credentials. Please check your email and password.';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to connect to the database.';
        });
        print('Login Error: $e');
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please fill in all fields.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD194), Color(0xFF70E1F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Login to continue',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  _emailController,
                  'College Email',
                  Icons.email_outlined,
                ),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 20),
                _buildRoleToggleButtons(),
                const SizedBox(height: 10),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : _buildLoginButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          prefixIcon: Icon(icon, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Password',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRoleToggleButtons() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(2, (index) {
          final isSelected = _selectedRoleIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRoleIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? const Color.fromARGB(255, 199, 205, 3)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: const Color.fromARGB(
                                255,
                                174,
                                144,
                                8,
                              ).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : [],
                ),
                child: Center(
                  child: Text(
                    index == 0 ? 'User' : 'Staff',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLoginButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _login,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          decoration: BoxDecoration(
            color:
                _isLoading
                    ? const Color.fromARGB(255, 222, 200, 100)
                    : const Color.fromARGB(255, 190, 166, 7),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _isLoading
                ? 'Logging in...'
                : 'Login as ${_selectedRoleIndex == 0 ? 'User' : 'Staff'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
