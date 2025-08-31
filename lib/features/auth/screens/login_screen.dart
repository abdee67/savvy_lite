import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 70, left: 50, right: 50),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    kToolbarHeight -
                    200,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // const Spacer(),
                  const Text(
                    'Welcome!',
                    style: TextStyle(
                      color: Color.fromARGB(255, 21, 88, 136),
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'to your daily compnainon',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color.fromARGB(255, 15, 90, 143),
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color.fromARGB(255, 12, 71, 114)),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 12, 71, 114),
                        ),
                        // borderSide: BorderSide(color: Colors.black, width: 2),
                      ),
                      labelText: 'Username',
                      suffixIcon: Icon(
                        Icons.person,
                        color: Color.fromARGB(255, 12, 71, 114),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    obscureText: _obscureText,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color.fromARGB(255, 12, 71, 114)),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 0, 34, 58),
                        ),
                        // borderSide: BorderSide(color: Colors.black, width: 2),
                      ),
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Color.fromARGB(255, 12, 71, 114),
                        ),
                        onPressed: () {
                          _obscureText = !_obscureText;
                          setState(() {
                            _obscureText = _obscureText;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle login logic here
                        Navigator.pushNamed(context, '/salesScreen');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(
                          255,
                          12,
                          71,
                          114,
                        ), // Button color
                        foregroundColor: Colors.white, // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      // Handle forgot password logic here
                      Navigator.pushNamed(context, '/forgot-password');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Color.fromARGB(255, 12, 71, 114),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ), // Padding
                    ),

                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Color.fromARGB(255, 12, 71, 114),
                          fontSize: 16,
                          // fontWeight: FontWeight.bold,
                        ),
                        children: const [
                          TextSpan(text: 'Forgot Password?'),
                          TextSpan(
                            text: ' Reset',
                            style: TextStyle(
                              color: Color.fromARGB(255, 12, 71, 114),
                              fontStyle: FontStyle.italic,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle registration logic here
                        Navigator.pushNamed(context, '/register');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(
                          255,
                          12,
                          71,
                          114,
                        ), // Button color
                        foregroundColor: Colors.white, // Text color
                        padding: const EdgeInsets.symmetric(), // Padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  //  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
