import 'package:flutter/material.dart';
import '../widgets/pixel_button.dart';
import 'game_config_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/main_menu_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // User Profile Info (Top Right)
          if (user != null)
            Positioned(
              top: 20,
              right: 20,
              child: FutureBuilder<Map<String, dynamic>?>(
                future: authService.getProfileData(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final profile = snapshot.data!;
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        border: Border.all(color: Colors.yellow[700]!, width: 2),
                      ),
                      child: Row(
                        children: [
                          if (profile['avatar_url'] != null)
                            CircleAvatar(
                              backgroundImage: NetworkImage(profile['avatar_url']),
                              radius: 15,
                            ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                profile['username'] ?? 'Jugador',
                                style: const TextStyle(fontSize: 10, color: Colors.white),
                              ),
                              Text(
                                'XP: ${profile['xp']} | Galeones: ${profile['galeones']}',
                                style: TextStyle(fontSize: 8, color: Colors.yellow[700]),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white, size: 16),
                            onPressed: () => authService.signOut(),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

          // Menu Content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Game Title
                  Text(
                    'PIXEL REALM STRATEGY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.yellow[700],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: const [
                        Shadow(color: Colors.black, offset: Offset(4, 4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  if (authService.isLoading)
                    const CircularProgressIndicator(color: Colors.yellow)
                  else
                    // Buttons in a Row for Landscape - Visible for everyone for now
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PixelButton(
                          text: 'JUGAR',
                          color: Colors.green[800]!,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const GameConfigScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 30),
                        PixelButton(
                          text: 'TIENDA',
                          color: Colors.blue[800]!,
                          onPressed: () {
                            // Navigate to Shop
                          },
                        ),
                        const SizedBox(width: 30),
                        PixelButton(
                          text: 'COLECCIÓN',
                          color: Colors.purple[800]!,
                          onPressed: () {
                            // Navigate to Collection
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Version footer
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Text(
              'v1.0.0 Alpha',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
