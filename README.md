# LumaDrama

A Flutter prototype for browsing and watching short dramas. It is a portfolio demo with local sample data and no payment or public comment service.

## Current features

- Home feed with vertical swipe between demo shows, horizontal swipe between categories, a quick drawer, and a compact seek bar.
- Series detail and episode playback; one playback session owns the active video player.
- Discover and My tabs stay on the same root route. Watch progress, saves, likes, and demo comments are stored locally.
- English and Simplified Chinese interface. Landscape fullscreen on Android and iOS; Android picture in picture uses the system API. iOS picture in picture is not implemented.
- One local video is reused for the demo shows and episodes. The catalog is sample data, not a library of real episodes.

## Local media setup

Drama artwork and video are **not included in this public repository**. Use your own media that you have permission to use, and place files at these paths before running or building:

```text
assets/media/demo_clip.mp4
assets/images/demo_poster.jpg
assets/images/stitch_signal_poster_clean.png
assets/images/stitch_city_poster_clean.png
assets/images/stitch_vengeance_poster_clean.png
assets/images/stitch_rain_scene.jpg
```

The paths are declared in `pubspec.yaml`; Flutter builds need all six files. The bundled catalog currently points every playable episode to `demo_clip.mp4`. Replace the sample titles and artwork before using the app for public content. The entire `assets/` directory is ignored by Git, so local media stays on your machine.

## Run

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Open the project in Android Studio to run on your own Android device. Android picture in picture and real device playback still need manual verification. No store purchase or publishing flow is part of this version.
