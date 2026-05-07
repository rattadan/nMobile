# nMobile - the world's most secure private and group messenger

"The decisions we make about communication security today will determine the kind of society we live in tomorrow."
                                 — Dr. Whitfield Diffie, co-creator of public key cryptography and advisor to NKN

## 📱 **Download nMobile 2026 Edition**

### **🚀 Quick Download - APK (161MB)**
**[**📥 Download nMobile 2026 Edition APK**](https://nride.network/wp-content/uploads/nMobile.apk)**

*Latest version with enhanced onboarding, public group discovery, and modern UI*

---

## 🆕 2026 Edition Features

This enhanced version includes significant improvements to the onboarding experience and user interface:

### ✨ Enhanced Onboarding Experience

- **🔤 BIP39 Word Editing**: Interactive seedphrase word editing with real-time validation
- **👤 Profile Setup**: Material Design username and avatar setup immediately after wallet creation
- **🔗 Address Display**: Shows both NKN and EVM addresses derived from your seedphrase
- **� Public Group Discovery**: Decentralized public group discovery using NKN broadcast messaging
- **📸 Group Avatar Support**: Upload and manage group avatars for better visual identification
- **� Modern UI**: Light grey heading text and improved visual hierarchy throughout the app
- **📱 Streamlined Flow**: Simplified wallet creation process focused on security and usability

### 🖼️ App Screenshots

#### Welcome Screen
![Welcome Screen](screenshots/Screenshot%20from%202026-02-17%2017-54-13.png)

#### Seedphrase Generation with Word Editing
![Seedphrase Editing](screenshots/Screenshot%20from%202026-02-17%2017-54-19.png)

#### Address Display
![Address Display](screenshots/Screenshot%20from%202026-02-17%2017-54-26.png)

#### PIN Setup
![PIN Setup](screenshots/Screenshot%20from%202026-02-17%2017-54-33.png)

#### Profile Setup
![Profile Setup](screenshots/Screenshot%20from%202026-02-17%2017-55-01.png)

#### Avatar Selection
![Avatar Selection](screenshots/Screenshot%20from%202026-02-17%2017-55-49.png)

#### Complete Setup
![Complete Setup](screenshots/Screenshot%20from%202026-02-17%2017-58-00.png)

#### Public Group Creation with Avatar
![Public Group Creation](screenshots/Screenshot%20from%202026-02-17%2018-01-29.png)

#### Public Group Discovery
![Public Group Discovery](screenshots/Screenshot%20from%202026-02-17%2018-01-42.png)

---

For more detail: 

https://forum.nkn.org/t/nmobile-the-trusted-chat/2358



## Getting Started

https://forum.nkn.org/t/nmobile-pre-beta-community-testing-and-simple-guide/2012


## Dependencies

* Flutter sdk: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
* golang (>= 1.18.0): [https://golang.org/dl/](https://golang.org/dl/)
* gomobile: [https://pkg.go.dev/golang.org/x/mobile/cmd/gomobile](https://pkg.go.dev/golang.org/x/mobile/cmd/gomobile)
> Android need NDK (>= 21.x) [https://developer.android.com/studio/projects/install-ndk](https://developer.android.com/studio/projects/install-ndk)

## Build

### build application icon
```
$ flutter pub run flutter_launcher_icons:main
```

### Golib

> Every time you modify go code, you need to recompile.

gomobile will generate dependencies for android and ios. `Android` is `nkn.aar` and `nkn-sources.jar`, `iOS` is `Nkn.xcframework`.

```
$ cd golib
```

* Build `Android` dependencies

```
$ make android
```

* Build `iOS` dependencies

```
$ make ios
```

## Flutter

* Updating package dependencies

```
$ flutter pub get
```

* If it is `iOS`, you also need to run the following command for update `iOS` dependencies

```
$ cd ios
$ pod install
```

### Run the app in device

> [https://flutter.dev/docs/get-started/test-drive](https://flutter.dev/docs/get-started/test-drive)

```
$ flutter run
```

### Generate intl using plugin

* Using Flutter Intl plugin for generate intl files: [https://plugins.jetbrains.com/plugin/13666-flutter-intl](https://plugins.jetbrains.com/plugin/13666-flutter-intl)

## Account & Wallet Onboarding (2026 Edition)

### Enhanced First-Time Registration

The 2026 edition provides a completely redesigned onboarding experience:

1. **🌟 Welcome Screen** - Clean, focused interface to begin wallet creation
2. **🔤 Seedphrase Generation** - Automatic BIP39 seedphrase generation with:
   - Interactive word editing capabilities
   - Real-time BIP39 validation
   - Copy-to-clipboard functionality
   - NKN and EVM address display
3. **🔐 PIN Setup** - Secure PIN creation for wallet protection
4. **👤 Profile Setup** - Personalize your chat identity:
   - Username selection with Material Design input fields
   - Avatar upload and cropping
   - Skip option for later setup
5. **🎉 Complete Setup** - Ready to start chatting with your new identity

### Key Onboarding Features

- **🔤 BIP39 Word Editing**: Tap any word (1-11) to edit from the complete BIP39 wordlist
- **🔗 Address Generation**: See both NKN and EVM addresses derived from your seedphrase
- **👤 Material Design Profile**: Modern input fields for username and avatar setup
- **🎨 Enhanced UI**: Light grey headings and improved visual hierarchy
- **🔒 Security First**: Proper wallet integration with account management system

### Using Your Own Account (Import a Wallet)

- If you prefer to use your own account, you can import an existing wallet at any time.
- Open the app and go to: Settings → Account → Import Wallet.
- Follow the on-screen steps to complete the import.
- After import, your wallet becomes your active account.

### Notes

- Your keys are stored locally on your device. Make sure you back them up safely.
- The enhanced onboarding ensures proper wallet integration with the internal account management system.
- Profile setup is optional but recommended for the best chat experience.
- If you import a wallet, ensure you're in a private, secure environment.

## 🌐 Public Group Discovery System

### Decentralized Group Discovery

nMobile 2026 edition introduces a revolutionary decentralized public group discovery system using NKN's native broadcast messaging capabilities:

#### 🔍 How It Works

1. **Dedicated Discovery Channel**: Uses a special `publicGroups` topic for group announcements
2. **Periodic Broadcasting**: Apps automatically broadcast known public groups every 10 minutes
3. **Distributed Knowledge**: Each app maintains and shares its knowledge base of public groups
4. **TTL Management**: Messages are designed to outlast the NKN message TTL for persistence

#### 📡 Broadcast Protocol

- **Automatic Announcements**: New public groups are automatically announced to the network
- **Knowledge Sharing**: Apps share their discovered groups with others
- **Continuous Discovery**: The system runs continuously in the background
- **No Central Server**: Completely decentralized - no single point of failure

#### 🎯 Features

- **Real-time Discovery**: Find new public groups as they're created
- **Category Filtering**: Groups organized by categories (General, Tech, Education, etc.)
- **Group Avatars**: Visual identification with custom group images
- **Subscriber Count**: See how many members are in each group
- **Group Descriptions**: Detailed information about each group's purpose

#### 🛠️ Technical Implementation

- **NKN Broadcast Messaging**: Leverages NKN's native broadcast capabilities
- **Message Format**: Structured JSON format for group information
- **Duplicate Prevention**: Intelligent deduplication to avoid spam
- **Graceful Degradation**: System continues working even with partial connectivity

#### 🔐 Privacy & Security

- **Opt-in Only**: Only public groups are discoverable, private groups remain hidden
- **No Tracking**: No central server tracks user behavior
- **Decentralized**: No single entity controls the discovery process
- **User Control**: Users choose which groups to join

This system creates a vibrant, self-sustaining ecosystem of public groups that grows organically as more users join and create communities.

---

## 📱 **Download & Installation**

### **🚀 Direct APK Download**
**[**📥 Download nMobile 2026 Edition APK**](https://nride.network/nMobile_2026edition.apk)**

- **File Size**: 161MB
- **Version**: 2026 Edition
- **Features**: Enhanced onboarding, public group discovery, modern UI
- **Requirements**: Android 5.0+ (API 21+)

### 📲 **Installation Instructions**

1. **Download** the APK from the link above
2. **Enable Unknown Sources** in your Android settings:
   - Go to Settings → Security → Enable "Install from Unknown Sources"
3. **Install** the downloaded APK
4. **Launch** nMobile and complete the enhanced onboarding process

### 🔐 **Security Note**
This APK is the official build from the nMobile development team with all the 2026 edition enhancements. Always verify the source when downloading mobile applications.

---
