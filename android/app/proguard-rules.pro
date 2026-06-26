# Flutter
-dontwarn io.flutter.**
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ZEGO Express Engine — plugin dispatches Dart calls via reflection on
# ZegoExpressEngineMethodHandler; R8 must not rename or strip these classes.
-keep class com.zego.** { *; }
-keep class im.zego.** { *; }
-keepclassmembers class im.zego.zego_express_engine.internal.ZegoExpressEngineMethodHandler {
    public static *;
}
-keepclassmembers class im.zego.zego_express_engine.ZegoExpressEnginePlugin {
    *;
}
