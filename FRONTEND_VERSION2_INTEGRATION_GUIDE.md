# Frontend Version2 Integration Guide

## Overview

This guide explains what changed in the backend and what the frontend needs to implement to integrate with Version2 (feedback-driven recommendations system).

**Current Status**: 
- ✅ Backend: Version2 fully implemented and tested (Phase 1-4 complete, Phase 5 all scenarios pass)
- 📋 Frontend: Currently on `V2-notifications` branch, working with old backend
- 🎯 Goal: Update frontend to work with Version2 backend

---

## Part 1: READ THIS FIRST - Current Frontend Architecture

### Current Version Overview

**Branch**: `V2-notifications`  
**Status**: ✅ Working (but outdated - uses old backend)  
**Framework**: Flutter (Dart)  
**Architecture**: MVC with service layer

### Key Files to Review

Read these files **in order** to understand current structure:

1. **[lib/main.dart](ai_food_app/lib/main.dart)** (30 lines)
   - App initialization
   - Theme setup
   - Navigation routing

2. **[lib/screens/onboarding_screen.dart](ai_food_app/lib/screens/onboarding_screen.dart)** (200-300 lines)
   - User profile collection
   - Dietary restrictions, allergies, preferences
   - Final onboarding step (currently shows "Start Finding Food" button)
   - **KEY CHANGE NEEDED**: Add loading state + auto-trigger after completion

3. **[lib/screens/home_screen.dart](ai_food_app/lib/screens/home_screen.dart)** (200-300 lines)
   - Main screen with "Find a Meal" button
   - Displays user profile summary
   - **KEY CHANGE NEEDED**: Add status polling + conditional button rendering

4. **[lib/screens/recommendation_results_screen.dart](ai_food_app/lib/screens/recommendation_results_screen.dart)** (400-500 lines)
   - Displays 5 recommendations with details
   - Feedback submission (like/dislike/ratings)
   - "Get More Meals" button
   - **KEY CHANGE NEEDED**: Add timer countdown after feedback + auto-trigger new generation

5. **[lib/services/recommendation_service.dart](ai_food_app/lib/services/recommendation_service.dart)** (200-300 lines)
   - API calls to backend
   - Recommendation fetching
   - Feedback submission
   - **KEY CHANGE NEEDED**: Add status polling method + generation trigger

6. **[lib/widgets/](ai_food_app/lib/widgets/)** (Various)
   - Custom widgets
   - **NEW WIDGET NEEDED**: CountdownButton (timer widget)

Read other files to make yourself fimiliar with the structure of the Frontend

### Current API Integration

**Old Backend Calls**:
```dart
// Current: Synchronous, user waits
POST /api/recommendations
  - User clicks button
  - 10-15 seconds wait
  - Returns 5 recommendations
  - Shows results

// Current: Feedback immediately blocked
POST /api/{recommendation_id}/feedback
  - Submits feedback
  - Must wait 1 hour before next request
  - No indication when next is available
```

---

## Part 2: What Changed in Backend (Version2)

### Backend Architecture Changes (Phases 1-4)

**Phase 1: Database Schema** ✅
```
7 NEW User fields added:
├── feedbackSummaryForEmbedding (TEXT) - 1-2 sentences for Stage 1
├── feedbackSummaryForLLM (TEXT) - 3-5 sentences for Stage 2 reasoning
├── feedbackSummaryLastUpdatedAt (DateTime) - Track update timing
├── recommendationGenerationStatus (String) - idle|summarizing|generating|ready
├── recommendationsReadyAt (DateTime) - When recommendations became available
├── nextAllowedGenerationAt (DateTime) - 1-hour gate after generation
└── recommendations (JSON) - Pre-computed 5 recommendations
```

**Phase 2: Feedback Summarization** ✅
```
NEW FEATURE: After 5 feedbacks, LLM creates summary
├── Input: Previous summary + 5 new feedback items
├── LLM generates: 2 summaries (embedding-optimized + detailed)
├── Stored in: User.feedbackSummaryForEmbedding/ForLLM
└── Effect: Next recommendations influenced by feedback history
```

**Phase 3: Auto-Generation System** ✅
```
NEW ENDPOINTS:
├── POST /api/user/complete-onboarding
│   └── Triggers async recommendation generation (fires after onboarding)
├── GET /api/recommendation-status
│   └── Returns: {status, recommendationsReadyAt, nextAllowedGenerationAt}
└── Async jobs run in background (non-blocking)

NEW STATUSES:
├── idle - No generation in progress
├── summarizing - Feedback summarization running (after 5+ feedbacks)
├── generating - Recommendation generation running
└── ready - Recommendations complete, user can view
```

**Phase 4: Edge Cases & Logging** ✅
```
Retry logic, error handling, comprehensive logging
All tested in Phase 5 - 100% pass rate ✅
```

### New Data Flow (Version2)

```
USER JOURNEY:

1. ONBOARDING
   └─ User completes profile
      └─ POST /api/user/complete-onboarding
         └─ Backend triggers async generation (fires-and-forgets)
            └─ Status: idle → summarizing/generating → ready

2. FRONTEND WAITS (with UI feedback)
   └─ GET /api/recommendation-status (every 3 seconds)
      └─ Shows loading spinner/message: "AI is crafting your meals..."
      └─ When status="ready": Auto-navigate to RecommendationResultsScreen

3. USER VIEWS PRE-COMPUTED RECOMMENDATIONS
   └─ 5 recommendations ALREADY GENERATED
      └─ NO WAIT (pre-computed during onboarding)

4. USER SUBMITS FEEDBACK
   └─ Submit feedback (like/dislike/ratings)
      └─ After 5 feedbacks accumulated:
         └─ Backend: Summarizes feedback + generates new recommendations
         └─ Frontend: Shows loading + countdown timer
         └─ After 1 hour: "Find a Meal" button enabled

5. USER CLICKS "FIND A MEAL" AGAIN
   └─ If within 1 hour: Timer countdown shown ("58 minutes remaining...")
   └─ If 1 hour passed: Fresh recommendations displayed
```

### Key Behavioral Changes

| Aspect | Old (Current) | New (Version2) |
|--------|---------------|----------------|
| **Recommendation Timing** | Waits for each request (10-15s) | Pre-computed (instant) |
| **User Wait Time** | Happens on "Find a Meal" click | Happens during onboarding (hidden) |
| **Feedback Effect** | Ignored by system | Drives recommendation updates |
| **Rate Limiting** | "Wait 1 hour" message only | Countdown timer + auto-enable |
| **UI Feedback** | Loading spinner | Loading spinner + status polling |
| **Consideration Set** | Cached (100 recipes reused) | Fresh (100 recipes per request) |
| **LLM Discovery** | Limited (rerank same 100) | Enhanced (discover from full pool) |

---

## Part 3: Frontend Changes Needed

### 3.1 New Endpoints Frontend Will Call

```dart
// ENDPOINT 1: Trigger onboarding completion
POST /api/user/complete-onboarding
  Response: {"status": "generation_started"}

// ENDPOINT 2: Poll for recommendation status
GET /api/recommendation-status
  Response: {
    "status": "idle" | "summarizing" | "generating" | "ready",
    "recommendationsReadyAt": "2026-04-02T15:30:00Z" or null,
    "nextAllowedGenerationAt": "2026-04-02T16:45:00Z" or null
  }

// ENDPOINT 3: (Unchanged) Get recommendations
GET /api/recommendations
  Response: [5 recommendations as before]

// ENDPOINT 4: (Unchanged) Submit feedback
POST /api/{recommendation_id}/feedback
  Payload: {"action": "liked", "rating": 5, ...}
  Response: {
    "status": "feedback_received",
    "nextAllowedGenerationAt": "2026-04-02T16:45:00Z"
  }
```

### 3.2 Modified Files

**FILE 1: `lib/screens/onboarding_screen.dart`**

**Current State**:
- Collects user profile fields
- Final screen has "Start Finding Food" button
- Button navigates to home_screen

**Changes Needed**:
```dart
// Add state variable
bool _isGeneratingRecommendations = false;

// On "Start Finding Food" button tap:
// OLD:
//   Navigator.pushReplacementNamed(context, '/home');

// NEW:
//   1. POST /api/user/complete-onboarding
//   2. Set _isGeneratingRecommendations = true
//   3. Show loading dialog: "AI is crafting your meals..."
//   4. Poll GET /api/recommendation-status every 3 seconds
//   5. When status="ready": Navigate to RecommendationResultsScreen
//   6. When status="idle": Navigate to HomeScreen

// Timeline: 2-3 seconds to show loading, then navigate (total ~5-10s)
```

**FILE 2: `lib/screens/home_screen.dart`**

**Current State**:
- Shows "Find a Meal" button
- Button calls /api/recommendations
- Shows loading spinner

**Changes Needed**:
```dart
// Add state variables
RecommendationStatus? _currentStatus;
Timer? _statusPollingTimer;

// Add lifecycle methods
@override
void initState() {
  super.initState();
  _startStatusPolling(); // Poll every 3 seconds
}

@override
void dispose() {
  _statusPollingTimer?.cancel();
  super.dispose();
}

// Add polling method
void _startStatusPolling() {
  _statusPollingTimer = Timer.periodic(Duration(seconds: 3), (_) async {
    final status = await recommendationService.checkStatus();
    setState(() {
      _currentStatus = status;
    });
    
    // If ready, navigate to recommendations
    if (status.status == "ready") {
      Navigator.pushNamed(context, '/recommendations');
    }
  });
}

// Modify "Find a Meal" button rendering
// OLD: Regular button always enabled
// NEW: 
//   if (status == "ready") {
//     Show button "✨ Find a Meal" (enabled)
//   } else if (status == "generating") {
//     Show button "🤖 AI is crafting meals..." (disabled, spinning)
//   } else if (nextAllowedGenerationAt in future) {
//     Show CountdownButton widget with remaining time
//   } else {
//     Show button "✨ Find a Meal" (enabled)
//   }
```

**FILE 3: `lib/screens/recommendation_results_screen.dart`**

**Current State**:
- Shows 5 recommendations
- Feedback submission (like/dislike/ratings)
- "Get More Meals" button (navigates back to home)

**Changes Needed**:
```dart
// Add state variables
bool _isSubmittingFeedback = false;
DateTime? _nextAllowedGenerationAt;

// After feedback submission:
// OLD: Just show "Feedback saved" message

// NEW:
//   1. POST /api/{recommendation_id}/feedback
//   2. If response contains nextAllowedGenerationAt:
//      └─ Save to SharedPreferences
//      └─ Show message: "Thanks! New meals will be available in 1 hour"
//   3. On "Find a Meal" button:
//      └─ Check: Is nextAllowedGenerationAt > now?
//      └─ If yes: Show countdown timer (instead of navigating)
//      └─ If no: Navigate back to home_screen

// Modify "Get More Meals" button rendering
//   if (_nextAllowedGenerationAt in future) {
//     Show CountdownButton (disabled during countdown)
//   } else {
//     Show "✨ Get More Meals" button (enabled)
//   }
```

**FILE 4: `lib/services/recommendation_service.dart`**

**Add New Methods**:
```dart
// NEW METHOD 1: Check recommendation status
Future<RecommendationStatus> checkStatus() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/recommendation-status'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  if (response.statusCode == 200) {
    return RecommendationStatus.fromJson(jsonDecode(response.body));
  }
  throw Exception('Failed to check status');
}

// NEW METHOD 2: Trigger onboarding completion
Future<void> completeOnboarding() async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/user/complete-onboarding'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  if (response.statusCode != 200) {
    throw Exception('Failed to trigger generation');
  }
}

// Modify existing submitFeedback to extract nextAllowedGenerationAt
Future<void> submitFeedback(String recommendationId, FeedbackData feedback) async {
  // ... existing code ...
  
  // NEW: Extract and return nextAllowedGenerationAt
  final jsonResponse = jsonDecode(response.body);
  return jsonResponse['nextAllowedGenerationAt'];
}
```

**FILE 5: `lib/models/` - New/Modified Models**

**Add New Model**: `recommendation_status.dart`
```dart
class RecommendationStatus {
  final String status; // "idle" | "summarizing" | "generating" | "ready"
  final DateTime? recommendationsReadyAt;
  final DateTime? nextAllowedGenerationAt;
  
  RecommendationStatus({
    required this.status,
    this.recommendationsReadyAt,
    this.nextAllowedGenerationAt,
  });
  
  factory RecommendationStatus.fromJson(Map<String, dynamic> json) {
    return RecommendationStatus(
      status: json['status'],
      recommendationsReadyAt: json['recommendationsReadyAt'] != null
          ? DateTime.parse(json['recommendationsReadyAt'])
          : null,
      nextAllowedGenerationAt: json['nextAllowedGenerationAt'] != null
          ? DateTime.parse(json['nextAllowedGenerationAt'])
          : null,
    );
  }
}
```

### 3.3 New Widget Required

**FILE: `lib/widgets/countdown_button.dart`** (NEW FILE)

```dart
// Purpose: Disabled button that shows countdown timer
// Shows: "⏱️ Next meal in 45:30" (minutes:seconds)
// Updates: Every second
// Re-enables: When countdown reaches zero

class CountdownButton extends StatefulWidget {
  final DateTime nextAvailableAt;
  final VoidCallback onReady;
  
  const CountdownButton({
    required this.nextAvailableAt,
    required this.onReady,
  });
  
  @override
  State<CountdownButton> createState() => _CountdownButtonState();
}

class _CountdownButtonState extends State<CountdownButton> {
  late Timer _timer;
  late Duration _remainingTime;
  
  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        _updateRemainingTime();
        if (_remainingTime.inSeconds <= 0) {
          _timer.cancel();
          widget.onReady(); // Call callback when ready
        }
      });
    });
  }
  
  void _updateRemainingTime() {
    _remainingTime = widget.nextAvailableAt.difference(DateTime.now());
  }
  
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;
    
    return ElevatedButton(
      onPressed: null, // Disabled
      child: Text(
        '⏱️ Next meal in $minutes:${seconds.toString().padLeft(2, '0')}',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
```

---

## Part 4: Step-by-Step Implementation Checklist

### Phase 1: Model & Service Updates (Day 1)

- [ ] Create `lib/models/recommendation_status.dart`
- [ ] Add `checkStatus()` method to recommendation_service.dart
- [ ] Add `completeOnboarding()` method to recommendation_service.dart
- [ ] Modify `submitFeedback()` to extract nextAllowedGenerationAt
- [ ] Update imports in dependent files

### Phase 2: New Widget (Day 1)

- [ ] Create `lib/widgets/countdown_button.dart`
- [ ] Test countdown logic with sample DateTime
- [ ] Add widget to pubspec.yaml if needed
- [ ] Verify UI appearance

### Phase 3: Onboarding Screen Updates (Day 2)

- [ ] Add state variables (_isGeneratingRecommendations)
- [ ] Add status polling method _startStatusPolling()
- [ ] Modify "Start Finding Food" button logic:
  - Call completeOnboarding()
  - Show loading dialog
  - Poll status every 3 seconds
  - Navigate when ready
- [ ] Handle error cases (generation fails)
- [ ] Test navigation flow

### Phase 4: Home Screen Updates (Day 2)

- [ ] Add state variables (_currentStatus, _statusPollingTimer)
- [ ] Implement initState with polling start
- [ ] Implement dispose with polling cleanup
- [ ] Add _startStatusPolling() method
- [ ] Modify "Find a Meal" button rendering logic
- [ ] Add status indicator UI (spinner, message, countdown)
- [ ] Handle auto-navigation when recommendations ready

### Phase 5: Recommendation Results Screen Updates (Day 3)

- [ ] Add state variables for feedback submission
- [ ] Modify feedback submission to extract nextAllowedGenerationAt
- [ ] Save nextAllowedGenerationAt to SharedPreferences
- [ ] Modify "Get More Meals" button rendering logic
- [ ] Implement countdown display
- [ ] Add auto-navigation when timer expires
- [ ] Show "Thanks! New meals available in 1 hour" message

### Phase 6: Testing & Debugging (Day 3-4)

- [ ] Test complete onboarding → auto-generation → navigation flow
- [ ] Test 5 feedback submission → summarization → new generation
- [ ] Test timer gate blocking
- [ ] Test error handling (network fails, API timeouts)
- [ ] Test edge cases (rapid button clicks, navigation back/forward)
- [ ] Performance testing (smooth UI during polling)

### Phase 7: Integration & Code Review (Day 4)

- [ ] Merge to main branch once complete
- [ ] Code review checklist
- [ ] Final testing
- [ ] Prepare for deployment

---

## Part 5: Git Workflow

```bash
# 1. CURRENT: Pull V2-notifications to main (and keep stable)
git checkout main
git pull origin V2-notifications
git commit -m "Merge V2-notifications to main: Stable baseline"
git push origin main


# 3. DEVELOP: Make all changes on  branch V2-notifications
# ... implement all changes above ...
# ... commit frequently: git commit -m "..."...

# 4. TEST: Thoroughly test against backend
# ... run all test scenarios ...


# 7. FINAL: After approval, merge to main
git checkout main
git merge V2-notifications
git push origin main
```

---

## Part 6: Success Criteria

✅ **Frontend is ready when**:

1. All new services/models created
2. All three screens (onboarding, home, results) updated
3. Countdown widget functional
4. Status polling working (3-second intervals)
5. Auto-navigation tested end-to-end
6. Timer gate blocking works
7. Feedback summarization trigger verified
8. Error handling for network failures
9. No hardcoded test data (uses real backend)
10. Passes all manual testing scenarios

---

## Part 7: Testing Scenarios (Manual)

### Scenario 1: Complete Onboarding Flow
```
1. Launch app
2. Complete onboarding form
3. Tap "Start Finding Food"
4. See loading dialog: "AI is crafting your meals..."
5. See spinner + status updates every ~3 seconds
6. After ~5-10 seconds: Auto-navigate to recommendations
7. See 5 pre-computed recommendations
✅ Expected: Smooth flow, no wait on "Find a Meal"
```

### Scenario 2: Feedback Submission + Timer
```
1. View recommendations
2. Submit feedback (like/dislike/ratings) on 3 recipes
3. See message: "Thanks! New meals available in 1 hour"
4. Tap "Find a Meal"
5. See countdown: "⏱️ Next meal in 59:45"
6. Wait a few seconds (countdown decreases)
✅ Expected: Timer counts down every second, blocks navigation
```

### Scenario 3: Timer Expiration
```
1. From Scenario 2, wait ~5-10 seconds
2. See countdown reach ~59:35
3. (Optionally) Force system time forward to test auto-enable
4. When countdown reaches 0: Button auto-enables
5. Can tap "Find a Meal" again
✅ Expected: Auto-enable works, new recommendations load
```

---

## Reference: Backend Documentation

If you need to understand backend in detail, see:
- `backend/VERSION2_IMPLEMENTATION_GUIDE.md` - Complete backend design
- `backend/PHASE5_TEST_EXECUTION_SUMMARY.md` - Test results (all pass ✅)
- `backend/BACKEND_CHAT_RESPONSE.md` - Decision summaries

---

## Support Documents

This guide assumes you'll:
1. **First**: Read the current frontend code (files listed in Part 1)
2. **Second**: Review this guide to understand Version2 changes
3. **Third**: Implement changes following the checklist (Part 4)
4. **Fourth**: Test against backend using scenarios

All changes are **isolated to frontend** - no backend changes needed.

---

**Status**: Ready for Frontend Implementation Chat ✅  
**Date**: April 2, 2026  
**Version**: V2 Integration Guide v1.0
