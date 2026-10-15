# Livocal - Google Play Data Safety & App Store Privacy Specification

**Document Version:** 1.0.0  
**Effective Date:** October 2026  
**Application Name:** Livocal  
**Package ID (Android):** `com.livocal.app`  
**Bundle ID (iOS):** `com.livocal.app`  
**Hosted Privacy Policy:** `https://livocal-relay.onrender.com/privacy-policy`  
**Support & Data Protection:** `support@livocal.app`

---

## 1. Executive Summary & Security Architecture

Livocal is a secure cross-lingual communication platform offering realtime messaging, WebRTC peer-to-peer voice calling, and zero-retention AI speech translation powered by Google Gemini Live.

### Core Security Guarantees:
* **Encryption in Transit:** All traffic between client applications and backend relays operates over **TLS 1.3** and **WSS**. Peer-to-peer voice media is secured using **DTLS-SRTP**.
* **Zero-Retention Voice Translation:** During cross-lingual calls, microphone PCM16 audio chunks are streamed through an authenticated, volatile in-memory gateway to Google Gemini Live API. **Audio frames are never written to disk, never logged, and never retained for AI model training.**
* **Intelligent Same-Language Bypass:** When both participants share the same spoken language, the Gemini Live AI interpreter is automatically bypassed for 100% direct peer-to-peer WebRTC audio streaming.
* **Zero Address Book Harvesting:** Device contacts are never scraped, uploaded, or sold. Friend discovery matches phone numbers using normalized, hashed lookups against Firestore registered accounts.
* **Hardware-Backed PIN Protection:** Two-Step Verification PINs are stored securely in hardware Keystore (Android) / Keychain (iOS) with exponential brute-force backoff and lockout protection.
* **Full Data Erasure:** Users can permanently delete individual messages, clear chat histories, or execute complete account erasure via **Settings > Account > Delete my account**.

---

## 2. Google Play Console Data Safety Questionnaire Answers

Use the exact responses below when completing the Google Play Console Data Safety declaration:

### 2.1 Overview & Security Practices
| Question | Answer | Details / Justification |
| :--- | :--- | :--- |
| **Does your app collect or share any user data?** | **Yes** | Phone number (auth), profile (name/avatar), user-generated messages and voice notes. |
| **Is all user data collected by your app encrypted in transit?** | **Yes** | Enforced via TLS 1.3, HTTPS, WSS, and DTLS-SRTP. |
| **Do you provide a way for users to request that their data is deleted?** | **Yes** | In-app self-service via `Settings > Account > Delete my account`. |
| **Is your app committed to following Play Families policy?** | **No** | Target audience is 13+ / general communication. |
| **Has your app been independently validated against a global security standard (MASA)?** | Optional / In progress | Complies with OWASP MASVS Level 1. |

---

### 2.2 Data Types Collected, Purpose, and Handling

#### A. Personal Info
| Field | Collected? | Shared? | Processing Type | Purpose | Deletion Mechanism |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Name** | Yes | No | Ephemeral / Stored | App functionality, Account management | Account deletion or Profile edit |
| **Phone number** | Yes | No | Ephemeral / Stored | Account auth (Firebase SMS OTP), Call routing | Account deletion |
| **User IDs** | Yes | No | Stored | Account management, Scoped storage authorization | Account deletion |

#### B. Messages
| Field | Collected? | Shared? | Processing Type | Purpose | Deletion Mechanism |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **In-app messages** | Yes | No | Stored (Encrypted) | App functionality (User communication) | Delete for me, Delete for everyone, Clear chats |

#### C. Photos and Videos
| Field | Collected? | Shared? | Processing Type | Purpose | Deletion Mechanism |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Photos** | Yes | No | Stored (Scoped) | User communication, Profile avatars, Statuses | Delete message, Auto-purge (Statuses: 24h) |
| **Videos** | Yes | No | Stored (Scoped) | User communication, Statuses | Delete message, Auto-purge (Statuses: 24h) |

#### D. Audio Files
| Field | Collected? | Shared? | Processing Type | Purpose | Deletion Mechanism |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Voice / Sound recordings** | Yes | No | Ephemeral (Call Audio) / Stored (Voice Notes) | Real-time speech translation, Voice messaging | Calls: Ephemeral RAM only. Notes: User delete. |

> [!NOTE]
> **Ephemeral Processing Exception for Voice Calls:** Spoken audio processed during active Gemini Live calls meets Google Play's definition of "ephemeral processing" because it is transmitted in real-time, processed in volatile memory only, and not retained on persistent storage longer than necessary to service the live translation request.

#### E. Contacts
| Field | Collected? | Shared? | Processing Type | Purpose | Deletion Mechanism |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Contacts** | Yes | No | Ephemeral Match | App functionality (Friend discovery) | Not stored permanently on server |

#### F. Device or Other Identifiers
| Field | Collected? | Shared? | Processing Type | Purpose | Deletion Mechanism |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FCM Push Token** | Yes | No | Stored | App functionality (Incoming call wakeup & chat alerts) | Cleared on logout / account deletion |

---

## 3. Apple App Store Privacy Nutrition Labels

When submitting Livocal to App Store Connect, configure App Privacy as follows:

### 3.1 Data Used to Track You
* **None** — Livocal does not track users across apps and websites owned by other companies.

### 3.2 Data Linked to You
* **Contact Info:** Phone Number, Name
* **User Content:** Photos or Videos, Audio Data, Customer Support Messages
* **Identifiers:** User ID, Device ID (Push Token)

### 3.3 Data Not Linked to You
* **Diagnostics:** Crash Data (Firebase Crashlytics for native & Flutter crash monitoring), Performance Metrics

---

## 4. Android Runtime Permissions Justification

| Permission | Reason for Request | User Facing Notice |
| :--- | :--- | :--- |
| `android.permission.RECORD_AUDIO` | Real-time speech translation and voice notes | "For online voice chat and live speech translation" |
| `android.permission.CAMERA` | Capturing photos/videos for chat and status updates | "To take photo for user profile and statuses" |
| `android.permission.READ_CONTACTS` | Discovering which friends are registered on Livocal | "To identify friends registered on Livocal" |
| `android.permission.POST_NOTIFICATIONS` | Alerting users of incoming calls and chat messages | "To notify you of incoming calls and messages" |
| `android.permission.USE_FULL_SCREEN_INTENT` | Waking device screen for incoming voice calls | Required for WhatsApp/CallKit-style call notifications |

---

## 5. User Data Deletion Policy & Procedure

Livocal respects privacy rights globally (including GDPR, CCPA, and Google Play Data Safety requirements):

1. **Self-Service Account Erasure:**  
   Users can navigate to `Settings > Account > Delete my account`.  
   Upon confirmation:
   * Firebase Authentication user record is deleted.
   * Cloud Firestore profile, contact associations, and status records are deleted.
   * Firebase Storage scoped attachments and avatars are deleted.
   * Local Isar database and SharedPreferences are completely wiped.

2. **Manual Deletion Requests:**  
   Users who no longer have access to their device may email `support@livocal.app` with proof of phone number ownership. Deletion requests are processed within 14 business days.
