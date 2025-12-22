# תוכנית עבודה - MVP אפליקציית ניהול זמן אוויר

> 🎯 **פלטפורמה יעד**: טאבלטים (Tablet-First)  
> ⚡ **גישה**: MVP מהיר, ללא אינטגרציות חיצוניות  
> 📱 **פוקוס**: תפקוד מלא במצב Offline-First

## 📋 סיכום פערים - MVP מיקוד

## ✅ מצב נוכחי (נכון ל-2025-12-22)

מה שכבר יש לנו בפועל בקוד:

- ✅ Flutter + Material 3 + RTL (עברית) עם Theme בסיסי
- ✅ שתי תצוגות עיקריות: אירוע (Tabs: פרטי אירוע/צוותים) + מסך צוותים
- ✅ שכבת Repository עם Streams (Realtime) + מימוש In-Memory למצב ללא Firebase
- ✅ Firebase-ready: `firebase_core` + `firebase_auth` (anonymous) + `cloud_firestore` עם Persistence (Offline) + Seed Data
- ✅ מודלים קיימים: `Event`, `Team`, `Member`, `Parameters`, `EventStep`, `AirLog`, `EventSummary`
- ✅ חישובים: `AirTimeCalculator` כולל `safetyMarginBar = 50`
- 🟡 FSM/שלבים: קיימים שני נתיבים
  - Legacy (בשימוש באפליקציה): `EventStepType` עם 4 מצבים (start/arrive/exit/washing) + כפתור פעולה דינמי + Undo
  - חדש (קיים בקוד אך לא מחובר UI/Repo): `StepType` עם entry/arrival/exit/washStart/washEnd
- 🟡 רישום Steps/AirLogs: נכתב ל-Firestore ול-InMemory, אבל עדיין אין מודל מלא של roundNumber/מחיקת step אחרון ב-Undo

פערים מרכזיים ל-MVP לפי המסמך הזה:

- 🔴 FSM מלא “כניסה → הגעה → יציאה → תחילת שטיפה → סיום שטיפה → כניסה נוספת” מחובר מקצה לקצה (כרגע חלקי)
- 🔴 Tablet UI “Side-by-side תמיד” (כרגע Tabs; לא Layout ייעודי לטאבלט)
- 🟡 ולידציות UI/Firestore Rules (כרגע rules מאפשרים read/write לכל משתמש מחובר ללא בדיקות ערכים)
- 🟡 Offline Local persistence (SharedPreferences) / “אירוע קיים” (כרגע Firestore persistence + InMemory בלבד)
- 🟢 `consumptionHistory` לא קיים עדיין

לאחר ניתוח מול האפיון, זוהו התחומים הבאים לפי חשיבות ל-MVP:

### 🔴 קריטי למ-MVP (חובה)
1. ✅ **חישובים ונוסחאות** - נוסחאות עם מקדם ביטחון 50 bar
2. 🟡 **FSM מלא** - הרצף המלא קיים חלקית (Legacy פעיל; StepType מלא עדיין לא מחובר)
3. 🟡 **מודל נתונים** - קיימים `steps`, `airLogs` (חסר `consumptionHistory`)
4. 🟡 **Tablet UI** - UI עובד ומסודר, אך עדיין לא “Tablet layout” עם Side-by-side תמיד

### 🟡 חשוב (טוב שיהיה)
5. **Offline/Online** - טיפול בסנכרון בסיסי
6. **ולידציות** - מגבלות UI/DB
7. **צוות שטיפה** - מודל ייחודי

### 🟢 נחמד שיהיה (לא קריטי)
8. **סבבים נוספים** - כניסה חוזרת לזירה
9. **טקסטים והודעות** - הודעות מפורשות

### ⚪ דחוי ל-Phase 2 (לא עכשיו)
- ❌ אינטגרציה עם AskOne (אוטוקומפליט)
- ❌ רפליקציה ו-BI
- ❌ Data Connect
- ❌ אימות ת"ז מול מערכת חיצונית

---

## 🎯 תוכנית עבודה מוצעת - MVP מהיר

### Week 1: ליבה קריטית (5 ימי עבודה)

#### Day 1-2: מודל נתונים + חישובים
**מטרה**: תשתית נתונים וחישובים מדויקים

**משימות**:
- [x] **D1.1**: הוספת מודל `Parameters` למחלקה
  ```dart
  class Parameters {
    final Duration defaultWashingTime; // 5 min
    final Duration minWashingTime;     // 3 min
    final int safetyMarginBar;         // 50 bar
    final int defaultConsumptionRate;  // 100 L/min
    final int washingTeamRate;         // 70 L/min
  }
  ```

- [x] **D1.2**: הוספת `Step`/Steps model + אוסף
  ```dart
  class Step {
    final String id;
    final StepType type; // enum: entry, arrival, exit, washStart, washEnd
    final DateTime timestamp;
    final String? teamId;
    final String? govId;
  }
  ```

- [x] **D1.3**: הוספת `AirLog` model + אוסף
  ```dart
  class AirLog {
    final String id;
    final String stepId;
    final String? teamId;
    final String? govId;
    final int pressureBar; // 0-300
    final DateTime sampleTime;
  }
  ```

- [x] **D1.4**: שירות חישובים מדויק
  ```dart
  class AirTimeCalculator {
    // timeLeft = washingTime - (volume × (pressure - 50)) / consumption
    Duration calculateTimeLeft({...});
    
    // requiredExit = now + timeLeftUpdated
    DateTime calculateRequiredExit({...});
  }
  ```

- [x] **D1.5**: עדכון Repository עם אוספים חדשים

**תוצר**: מודל נתונים מלא + חישובים מדויקים

---

#### Day 3: FSM מלא + Undo
**מטרה**: מכונת מצבים מלאה עם Undo

**משימות**:
- [ ] **D3.1**: חיבור `StepFsm` מלא (entry/arrival/exit/washStart/washEnd) מקצה לקצה (UI + Repo + Firestore)
  ```dart
  enum TeamState {
    idle,           // לא פעיל
    entry,          // כניסה לזירה
    arrival,        // הגעה למוקד
    exit,           // יציאה מהמוקד
    washStart,      // תחילת שטיפה
    washEnd,        // סיום שטיפה (חוזר ל-entry)
  }
  ```

- [x] **D3.2**: Undo - החזרת שלב אחד אחורה (מימוש קיים)
  - הערה: כרגע Undo לא מוחק Step אחרון מהיסטוריה; מחזיר מצב באמצעות snapshot/undo fields
  - מחיקת Step האחרון
  - איפוס שדות זמן
  - חישוב מחדש של טיימר
  
- [x] **D3.3**: כפתור דינמי בממשק (Label משתנה לפי Step)
  - טקסט משתנה: "כניסה לזירה" → "הגעה למוקד" → "יציאה" → ...
  - אייקון משתנה
  - צבע משתנה (ירוק → כתום → אדום)

- [x] **D3.4**: רישום Steps + AirLogs בסיסי
  - כל מעבר מצב נשמר
  - timestamp + teamId + state

**תוצר**: FSM מלא עם Undo

---

#### Day 4-5: Tablet UI + UX
**מטרה**: ממשק מותאם לטאבלט עם חוויית משתמש מלוטשת

**משימות**:
- [ ] **D4.1**: Tablet Layout אופטימלי (Side-by-side תמיד לטאבלט)
  - רזולוציה יעד: 1024×768 (iPad) ומעלה
  - Side-by-side תמיד (לא טאבים)
  - מסך מלא לכרטיסי צוותים
  - טקסט גדול וברור (18-24px)

- [ ] **D4.2**: גריד מותאם לטאבלט
  ```dart
  GridView.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: constraints.maxWidth > 1200 ? 3 : 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
    ),
  )
  ```

- [ ] **D4.3**: כרטיס צוות מוגדל (טיימר/כפתורים גדולים באמת)
  - גופן ענק לטיימר (48-72px)
  - כפתורים גדולים (60×60)
  - רווחים נדיבים
  - צבעים ברורים

- [ ] **D4.4**: התראות חזותיות לפי ספים (אזהרה/אדום)
  - צהוב: 5 דקות אחרונות
  - אדום: זמן סיום אוויר
  - אנימציה בולטת
  - כפתור "אישור" גדול

- [ ] **D4.5**: טסטים על טאבלט (ריספונסיביות/לנדסקייפ)
  - Chrome DevTools - iPad Pro
  - Responsive עד 1366×1024
  - מצב לנדסקייפ ופורטרייט

**תוצר**: UI מלא לטאבלט

---

### Week 2: שכלול ותכונות נוספות (5 ימי עבודה)

#### Day 6-7: ולידציות + Offline בסיסי
**מטרה**: ולידציות חזקות ועבודה אופליין

**משימות**:
- [ ] **D6.1**: מגבלות נתונים
  - לחץ: 50-330 (UI), 0-300 (DB)
  - זמן שטיפה: מינימום 3 דקות
  - נפח: 6.8 או 9 ליטר בלבד

- [ ] **D6.2**: Firestore Rules
  ```javascript
  allow write: if request.resource.data.pressureBar >= 0 
                && request.resource.data.pressureBar <= 300;
  allow write: if request.resource.data.washingTime >= 3;
  ```

- [ ] **D6.3**: Offline-First בסיסי
  - שמירה לוקאלית בכל שינוי (SharedPreferences)
  - "אירוע קיים" - המשך/חדש
  - אייקון מצב חיבור

- [ ] **D6.4**: אינדקסים
  ```json
  {
    "collectionGroup": "steps",
    "fields": [
      {"fieldPath": "teamId", "order": "ASCENDING"},
      {"fieldPath": "timestamp", "order": "DESCENDING"}
    ]
  }
  ```

**תוצר**: ולידציות + Offline בסיסי

---

#### Day 8-9: צוות שטיפה + סבבים
**מטרה**: תכונות ייחודיות נוספות

**משימות**:
- [ ] **D8.1**: צוות שטיפה
  ```dart
  class WashingTeam extends Team {
    final int consumptionRate = 70; // ברירת מחדל
    bool isWashing = false;
    
    void startWashing() { ... }
    void stopWashing() { ... }
  }
  ```

- [ ] **D8.2**: כפתור Start/Stop לשטיפה
  - טוגל בין התחלה לעצירה
  - טיימר נפרד
  - התראה אדומה ב-5 דקות

- [ ] **D8.3**: כניסה נוספת (Round 2)
  - שדות זהות ננעלים
  - ציוד מועתק
  - לחץ + checks נדרשים מחדש
  - כפתור חוזר ל"כניסה לזירה"

- [ ] **D8.4**: שמירת היסטוריה
  - `roundNumber` בכל Step
  - קישור בין סבבים
  - תצוגה בדוח

**תוצר**: צוות שטיפה + סבבים

---

#### Day 10: פוליש וטסטים
**מטרה**: ליטוש אחרון + בדיקות

**משימות**:
- [ ] **D10.1**: שיפורי UX
  - התראות צבעוניות (צהוב/אדום)
  - אנימציות חלקות
  - Haptic feedback (אם נתמך)
  - "לוחם עם לחץ נמוך" - חיווי ברור

- [ ] **D10.2**: טקסטים והודעות
  - כל ההודעות בעברית
  - טקסטי שגיאה מפורשים
  - הנחיות למשתמש

- [ ] **D10.3**: טסטים מקיפים
  - Unit tests לחישובים
  - Widget tests לממשק
  - טסט על טאבלט אמיתי/סימולטור

- [ ] **D10.4**: README + תיעוד
  - עדכון README עם כל התכונות
  - מדריך שימוש מהיר
  - Screenshots

**תוצר**: MVP מוכן להצגה! 🎉

---

## 📊 מטריקות הצלחה ל-MVP

### Week 1 - ליבה (Must Have)
- ✅ מודל נתונים: Steps, AirLogs, Parameters (חסר consumptionHistory)
- ✅ חישובים: נוסחה עם SafetyMargin=50
- 🟡 FSM: Undo + כפתור דינמי קיים, אבל FSM מלא 5-שלבים (washStart/washEnd) עדיין לא מחובר
- 🟡 Tablet UI: עובד וקריא, אבל עדיין לא Layout “Side-by-side תמיד”

### Week 2 - שכלול (Nice to Have)
- ⬜ ולידציות: Firestore Rules + בדיקות UI לערכים
- 🟡 Offline: Firestore persistence קיים; Local persistence (SharedPreferences) עדיין לא
- ⬜ צוות שטיפה: מודל/התנהגות ייעודית
- 🟡 סבבים: לוגיקת “כניסה נוספת” קיימת ברמת StepType, עדיין לא מחוברת ל-flow הראשי
- ⬜ פוליש: התראות/אנימציות/טסטים מתקדמים

### MVP Success Criteria
- 🟡 רץ על טאבלט (Chrome/Safari) — דורש אימות ידני + התאמות Layout
- 🟡 עובד אופליין — InMemory + Firestore persistence, חסר Local persistence “אירוע קיים”
- ✅ חישובים מדויקים (כולל margin 50)
- 🟡 FSM מלא עם Undo — Undo קיים, FSM מלא עדיין WIP
- ✅ UI ברור וקריא (RTL)
- ✅ נתונים נשמרים ב-Firestore (כאשר Firebase מוגדר)

---

## 🎯 סדר עדיפויות - MVP First

### 🔴 Must Have - Week 1 (קריטי)
1. ✅ מודל נתונים + חישובים (D1-2)
2. ✅ FSM מלא + Undo (D3)
3. ✅ Tablet UI (D4-5)

### 🟡 Should Have - Week 2 (חשוב)
4. ⭐ ולידציות + Offline בסיסי (D6-7)
5. ⭐ צוות שטיפה + סבבים (D8-9)
6. ⭐ פוליש + טסטים (D10)

### ⚪ Not Now (דחוי ל-Phase 2)
- ❌ אימות ת"ז אוטומטי (קליטה ידנית בינתיים)
- ❌ אינטגרציה AskOne (אוטוקומפליט)
- ❌ Data Connect + BI
- ❌ Cloud Functions
- ❌ דוחות מתקדמים

---

## 💬 החלטות שהתקבלו

1. ✅ **פלטפורמה**: טאבלטים (Tablet-First)
2. ✅ **Timeline**: 2 שבועות (10 ימי עבודה)
3. ✅ **Scope**: MVP מהיר ללא אינטגרציות חיצוניות
4. ✅ **Offline**: מלא - Local-First
5. ✅ **אימותים**: ידני בשלב זה (לא AskOne)
6. ✅ **Deployment**: Web בלבד

## ✨ מה הלאה?

### פעולות הבאות (הכי חשוב → פחות חשוב)

1. **לאחד FSM ולהשתמש ב-StepType בכל האפליקציה**
  - להחליף את `Team.currentStep` ל-`StepType?` (או להחזיק שני שדות זמנית למיגרציה)
  - לעדכן UI כך שהכפתור/מצב ירוץ לפי `StepType` (כולל washStart/washEnd)
  - לעדכן Firestore schema ל-step type החדש + roundNumber

2. **Undo “אמיתי” על היסטוריית Steps (אם זה דרוש ל-MVP)**
  - החלטה: האם Undo מוחק את ה-Step האחרון מה-collection או רק מסמן/משחזר מצב
  - אם מוחקים: לשמור `lastStepId` בקבוצת team כדי למחוק/לשחזר בטרנזקציה

3. **Tablet Layout (Side-by-side) בלי לשבור UI קיים**
  - במסכים רחבים: להצמיד Event panel + Teams panel ביחד
  - במסכים צרים: להשאיר Tabs כפי שהוא

4. **ולידציות (UI + Firestore Rules + Indexes)**
  - Rules: לחץ 0..300, זמן שטיפה מינימום 3 דקות, נפח בלון רק 6.8/9
  - indexes: steps לפי teamId+createdAt, airLogs לפי teamId+createdAt

5. **Offline Local persistence (SharedPreferences) ל-"אירוע קיים"**
  - לשמור `currentEventId` + snapshot מינימלי
  - להציע "המשך אירוע" בעת פתיחה

---

## 📝 הערות

- כל ספרינט כולל זמן לבדיקות ותיקון באגים
- מומלץ code review אחרי כל משימה
- יש לעדכן README בסוף כל פאזה
- מומלץ demo למנהלים בסוף כל פאזה
