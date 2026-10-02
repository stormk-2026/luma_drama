# LumaDrama

[简体中文](README.md) | **English**

LumaDrama is a Flutter short-drama playback prototype for international audiences, exploring immersive viewing, discovery, and continuous episode playback on mobile. It is currently a personal portfolio project using free demo content.

## Features

- **Immersive home feed:** portrait playback; swipe vertically to switch dramas and horizontally to change categories. Supports seeking and landscape fullscreen playback.
- **Episode playback:** start from a drama's detail page, watch episodes sequentially, choose an episode, and resume from locally saved progress.
- **Discovery and profile:** browse, search, and inspect drama details; view watch history, favorites, and liked content from the profile page.
- **Interaction and languages:** local demo comments, system sharing, and English and Simplified Chinese interfaces.
- **Picture in picture:** Android system picture-in-picture integration; iOS picture in picture is not implemented yet.

## Implementation

Built with Flutter, Provider, and `video_player`. Playback sessions centrally manage player lifecycles. Watch progress and demo interaction data are stored on the device. Home, discovery, and profile share a root page that preserves their state when switching tabs.

## Current limitations

The drama catalog and episodes are demo data; several dramas currently reuse the same test video. Demo images and videos are not included in the public repository. There is no real content service, payment system, or public commenting feature. Android physical-device interactions are still undergoing acceptance checks.
