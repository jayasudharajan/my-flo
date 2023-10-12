-keep class com.hivemq.spi.** { *; }
-keep class * implements com.hivemq.spi.** { *; }
-keep class * extends com.hivemq.spi.** { *; }
-keep class * implements com.hivemq.spi.callback.registry.CallbackRegistry { *; }

-keepclasseswithmembers class * {
    @com.hivemq.spi.** *;
}

-keep class com.hivemq.spi.annotations.** { *; }
-dontwarn com.hivemq.spi.**

-keep class com.hivemq.spi.callback.registry.CallbackRegistry { *; }
-keepclasseswithmembers class com.hivemq.spi.callback.registry.CallbackRegistry { *; }
