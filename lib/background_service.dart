import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:dio/dio.dart';
import 'dart:async';

// متغیر سراسری سوکت و deviceId
IO.Socket? _globalSocket;
String? _globalDeviceId;

/// دریافت یا ساخت deviceId ثابت و ذخیره در SharedPreferences
Future<String> getOrCreateDeviceId() async {
  final random = DateTime.now().microsecondsSinceEpoch.remainder(1000000);
  return "phone_$random";
}

Future<bool> startBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(),
  );

  return await service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // جلوگیری از ساخت مجدد سوکت
  if (_globalSocket != null) {
    print("⚠️ سوکت قبلاً ساخته شده و فعال است.");
    return;
  }

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "سرویس فعال است",
      content: "اپلیکیشن شما در بک‌گراند اجرا می‌شود",
    );
  }

  // deviceId یکتا و ثابت (در هر اجرا از SharedPreferences)
  _globalDeviceId ??= await getOrCreateDeviceId();
  final String deviceId = _globalDeviceId!;
  final Dio dio = Dio();

  _globalSocket = IO.io(
    'http://94.101.178.60:5000',
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .setReconnectionAttempts(999999)
        .setReconnectionDelay(5000)
        .build(),
  );

  final socket = _globalSocket!;

  // اتصال به سرور
  socket.onConnect((_) {
    print("✅ Connected to server (BG)");
    socket.emit('device_online', {"device_id": deviceId, "status": "ONLINE"});

    // Heartbeat هر ۳۰ ثانیه
    Timer.periodic(Duration(seconds: 30), (_) {
      if (socket.connected) {
        socket.emit('heartbeat', {"device_id": deviceId});
        print("💓 Heartbeat sent (BG)");
      } else {
        print("⚠ سوکت قطع است، تلاش برای اتصال مجدد...");
      }
    });
  });

  // دریافت درخواست سرور
  socket.on('register_barbarg', (data) async {
    String url = data['url'];
    String method = (data['method'] ?? 'POST').toUpperCase();
    Map<String, dynamic> headers = Map<String, dynamic>.from(
      data['headers'] ?? {},
    );
    dynamic body = data['body'];

    print("📥 BG Request from server => $url");

    try {
      final Response response;
      if (method == "POST") {
        response = await dio.post(
          url,
          data: body,
          options: Options(headers: headers),
        );
      } else {
        response = await dio.get(url, options: Options(headers: headers));
      }

      socket.emit('register_barbarg_result', {
        "device_id": deviceId,
        "result": {"status_code": response.statusCode, "data": response.data},
      });
    } catch (e) {
      socket.emit('register_barbarg_result', {
        "device_id": deviceId,
        "result": {"error": e.toString()},
      });
    }
  });

  socket.onDisconnect((_) {
    print("⚠ Disconnected from server (BG)");
  });

  socket.onError((data) {
    print("❌ Socket error: $data");
  });
}
