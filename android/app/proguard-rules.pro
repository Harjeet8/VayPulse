# Keep only reflection-based Flutter plugin entry points that R8 cannot infer.
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.common.** { *; }

# Preserve runtime annotations and generic signatures used by plugins.
-keepattributes RuntimeVisibleAnnotations,RuntimeInvisibleAnnotations,Signature
