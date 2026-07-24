# Android multi-Engine lifecycle reproduction

This example reproduces the TradPlus plugin lifecycle conflict without Firebase,
push notifications, or an ad placement. `firebase_messaging` is only one way to
create the second `FlutterEngine`; it is not required to trigger the issue.

## Run

From the `example` directory, run:

```shell
flutter pub get
flutter run -t lib/multi_engine_repro.dart
```

On the Android device:

1. Confirm that **Original instance owns host Activity** is `true`.
2. Tap **Create secondary Engine**. The Android embedding automatically
   registers `TradplusFlutterPlugin` with this Engine even though it has no
   Activity.
3. Tap **Destroy secondary Engine**.

## Actual result with tradplus_sdk 1.2.8

The page records the original main-Engine instance after every step and only
reports success when its host Activity ownership follows this exact sequence:

```text
true -> true -> false
```

The last value becomes `false` while the main Flutter Activity is still visible.
The page reports:

```text
Bug reproduced: the secondary Engine detached the main Engine's TradPlus Activity.
```

Destroying the secondary Engine calls this sequence:

```text
TradplusFlutterPlugin.onDetachedFromEngine()
  -> TradPlusSdk.getInstance().detachPlugin()
     -> releaseAllAdObjects()
     -> clearContextReferences()
     -> sInstance = null
```

The plugin does not verify that the detached Engine owns the singleton state.
Consequently, detaching an Engine without an Activity releases state belonging
to the still-running main Engine.

## Expected result

Destroying a secondary Engine must not release ads, channels, or Activity state
owned by the main Engine. The original instance's host Activity ownership should
remain `true` until the main Flutter Activity or its Engine is detached.

## Why the reproduction does not start Dart on the second Engine

The conflict happens during automatic plugin registration in the
`FlutterEngine` constructor. Starting a Dart isolate is unnecessary; omitting it
makes the lifecycle failure deterministic and keeps the reproduction focused on
plugin ownership.
