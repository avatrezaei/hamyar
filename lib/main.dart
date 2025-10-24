import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'background_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final service = FlutterBackgroundService();
  bool isRunning = await service.isRunning();
  if (!isRunning) {
    await startBackgroundService();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barbarg Driver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Vazir', // اگر فونت سفارشی دارید اضافه کنید
        primarySwatch: Colors.indigo,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  // وضعیت آنلاین بودن (در صورت نیاز به گسترش)
  final bool isOnline = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F8EFF), Color(0xFF3559B7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.handshake,
                    size: 70,
                    color: Colors.indigo.shade700,
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'به اپ همیار خوش آمدید',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  'سرویس شما به صورت خودکار فعال است.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 36),
                AnimatedOnlineStatus(isOnline: isOnline),
                SizedBox(height: 36),
                Text(
                  'شما می‌توانید برنامه را ببندید\nو همچنان درخواست‌ها را دریافت کنید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedOnlineStatus extends StatefulWidget {
  final bool isOnline;
  const AnimatedOnlineStatus({Key? key, required this.isOnline}) : super(key: key);

  @override
  State<AnimatedOnlineStatus> createState() => _AnimatedOnlineStatusState();
}

class _AnimatedOnlineStatusState extends State<AnimatedOnlineStatus> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.7, end: 1.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _animation,
          child: Icon(
            Icons.circle,
            color: widget.isOnline ? Colors.greenAccent : Colors.redAccent,
            size: 18,
          ),
        ),
        SizedBox(width: 8),
        Text(
          widget.isOnline ? 'آنلاین' : 'آفلاین',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}