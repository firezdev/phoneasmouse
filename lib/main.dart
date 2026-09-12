import 'dart:async';
import 'dart:convert';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:web_socket_client/web_socket_client.dart';

void main() {
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
            ),
            home: const HomePage(),
        );
    }
}

class HomePage extends StatefulWidget {
    const HomePage({super.key});

    @override
    State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
    late final WebSocket socket;
    static const double distance = 0.7;

    double yaw = 0.0;
    double pitch = 0.0;

    Timer? scroll_timer;
    final Stopwatch move_stopwatch = Stopwatch()..start();
    int last_microseconds = 0;

    @override
    void initState() {
        super.initState();
        socket = WebSocket(Uri.parse('ws://192.168.1.10:8000/ws'));
        gyroscopeEventStream(
            samplingPeriod: SensorInterval.gameInterval,
        ).listen((event) {
            final int now = move_stopwatch.elapsedMicroseconds;
            final double dt = (now - last_microseconds) / 1e6;
            last_microseconds = now;

            if (dt <= 0 || dt > 0.2) return;

            yaw += -event.z * dt;
            pitch += -event.x * dt;

            yaw = yaw.clamp(-1.3, 1.3);
            pitch = pitch.clamp(-1.3, 1.3);

            // A pointed ray lands at D*tan(angle), not D*angle. Without the
            // tangent the cursor lags further behind the further you aim.
            socket.send(json.encode({'action': 'move', 'x': 0.5 + distance * math.tan(pitch), 'z': 0.5 + distance * math.tan(yaw)}));
        });
    }

    void start_scroll(String state) {
        scroll_timer?.cancel();
        socket.send(json.encode({'action': 'scroll', 'state': state}));
        scroll_timer = Timer.periodic(
            const Duration(milliseconds: 50),
            (_) => socket.send(json.encode({'action': 'scroll', 'state': state}))
        );
    }

    void stop_scroll() {
        scroll_timer?.cancel();
        scroll_timer = null;
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            body: Column(
                children: [
                    Expanded(
                        flex: 2,
                        child: Row(
                            children: [
                                Expanded(
                                    flex: 3,
                                    child: Listener(
                                        onPointerDown: (_) => socket.send(json.encode({'action': 'left', 'state': 'down'})),
                                        onPointerUp: (_) => socket.send(json.encode({'action': 'left', 'state': 'up'})),
                                        onPointerCancel: (_) => socket.send(json.encode({'action': 'left', 'state': 'up'})),
                                        child: Container(
                                            decoration: BoxDecoration(
                                                border: Border(bottom: BorderSide(width: 3, color: Color(0xFFFFFFFF)), right: BorderSide(width: 3, color: Color(0xFFFFFFFF)))
                                            ),
                                            child: Material(
                                                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                                child: InkWell(onTap: () {})
                                            )
                                        )
                                    )
                                ),
                                Expanded(
                                    child: Listener(
                                        onPointerDown: (_) => socket.send(json.encode({'action': 'middle', 'state': 'down'})),
                                        onPointerUp: (_) => socket.send(json.encode({'action': 'middle', 'state': 'up'})),
                                        onPointerCancel: (_) => socket.send(json.encode({'action': 'middle', 'state': 'up'})),
                                        child: Container(
                                            decoration: BoxDecoration(
                                                border: Border(bottom: BorderSide(width: 3, color: Color(0xFFFFFFFF)), right: BorderSide(width: 3, color: Color(0xFFFFFFFF)))
                                            ),
                                            child: Material(
                                                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                                child: InkWell(onTap: () {})
                                            )
                                        )
                                    )
                                ),
                                Expanded(
                                    flex: 3,
                                    child: Listener(
                                        onPointerDown: (_) => socket.send(json.encode({'action': 'right', 'state': 'down'})),
                                        onPointerUp: (_) => socket.send(json.encode({'action': 'right', 'state': 'up'})),
                                        onPointerCancel: (_) => socket.send(json.encode({'action': 'right', 'state': 'up'})),
                                        child: Container(
                                            decoration: BoxDecoration(
                                                border: Border(bottom: BorderSide(width: 3, color: Color(0xFFFFFFFF)))
                                            ),
                                            child: Material(
                                                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                                child: InkWell(onTap: () {})
                                            )
                                        )
                                    )
                                )
                            ]
                        )
                    ),
                    Expanded(
                        flex: 3,
                        child: Center(
                            child: TextButton(
                                child: Text('Set center'),
                                onPressed: () {
                                    yaw = 0;
                                    pitch = 0;
                                }
                            )
                        )
                    )
                ]
            ),
            floatingActionButton: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                    Listener(
                        onPointerDown: (_) => start_scroll('up'),
                        onPointerCancel: (_) => stop_scroll(),
                        onPointerUp: (_) => stop_scroll(),
                        child: FloatingActionButton(
                            onPressed: () {},
                            child: Icon(Icons.arrow_upward),
                        )
                    ),
                    Listener(
                        onPointerDown: (_) => start_scroll('down'),
                        onPointerCancel: (_) => stop_scroll(),
                        onPointerUp: (_) => stop_scroll(),
                        child: FloatingActionButton(
                            onPressed: () {},
                            child: Icon(Icons.arrow_downward),
                        )
                    )
                ]
            )
        );
    }
}
