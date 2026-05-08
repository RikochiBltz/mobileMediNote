# MediNote Mobile Application

## Overview
This project was developed as part of the PIDS - 4DS4 Engineering Program at **Esprit School of Engineering** (Academic Year 2025-2026).

MediNote Mobile is the Flutter client for the MediNote platform. It provides authenticated role-based access for administrators, delegates, and enterprise users, plus AI chat, report analysis, notifications, user engagement scoring, speech-to-text, text-to-speech, and inclusive chat support aligned with SDG 10.

Repository description:
MediNote mobile app developed at Esprit School of Engineering - Tunisia for PIDS 4DS4, Academic Year 2025-2026, built with Flutter, Spring Boot, and FastAPI.

Recommended GitHub topics:
`esprit-school-of-engineering`, `academic-project`, `esprit-pids`, `2025-2026`, `flutter`, `dart`, `mobile-app`, `medinote`

## Features
- JWT login, refresh, logout, and role-based startup routing.
- Mobile dashboards for admin, delegate, and enterprise roles.
- AI chatbot connected to the FastAPI orchestration service.
- Report analysis upload flow for PDF and image files.
- Engagement scoring and admin score visibility.
- Notification center and backend notification integration.
- Speech-to-text message input and text-to-speech answer playback.
- Inclusive mode for simpler, more accessible AI answers.

## Tech Stack

### Frontend
- Flutter
- Dart
- Material Design
- `speech_to_text`
- `flutter_tts`
- `file_picker`

### Backend
- Spring Boot authentication and business APIs
- FastAPI AI orchestration gateway
- MySQL database
- Ollama-compatible LLM services

## Architecture
```text
Flutter Mobile App
  |-- AuthService -> Spring Boot /api/auth/*
  |-- ChatService -> FastAPI /api/v1/chat
  |-- ReportAnalysisService -> FastAPI /api/v1/report-analysis
  |-- NotificationService -> Spring Boot notification APIs
  |-- EngagementService -> Spring Boot scoring APIs
```

## Contributors
- MediNote PI Team
- Esprit School of Engineering students, PIDS - 4DS4

## Academic Context
Developed at **Esprit School of Engineering - Tunisia**.

PIDS - 4DS4 | Academic Year 2025-2026

This repository follows the Esprit GitHub standardization rules for public academic project visibility: structured README, Esprit branding, academic naming convention, and project topics.

## Getting Started
1. Install Flutter and Android Studio.
2. Configure backend URLs in `lib/config/app_config.dart`.
3. Install dependencies:

```bash
flutter pub get
```

4. Run on Android:

```bash
flutter run
```

5. Build a debug APK:

```bash
flutter build apk --debug
```

## Acknowledgments
Thanks to **Esprit School of Engineering - Tunisia**, the PIDS academic team, and the supervisors supporting this PI project.
