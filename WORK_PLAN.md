# תוכנית עבודה - MVP אפליקציית ניהול זמן אוויר

> 🎯 **פלטפורמה יעד**: טאבלטים (Tablet-First)  
> ⚡ **גישה**: MVP מהיר, ללא אינטגרציות חיצוניות  
> 📱 **פוקוס**: תפקוד מלא במצב Offline-First

## 📋 סיכום פערים - MVP מיקוד

לאחר ניתוח מול האפיון, זוהו התחומים הבאים לפי חשיבות ל-MVP:

### 🔴 קריטי למ-MVP (חובה)
1. **חישובים ונוסחאות** - נוסחאות עם מקדם ביטחון 50 bar
2. **FSM מלא** - רצף שלבים מדויק: כניסה → הגעה → יציאה → שטיפה → כניסה נוספת
3. **מודל נתונים** - אוספים: steps, airLogs, consumptionHistory
4. **Tablet UI** - מותאם מלא לטאבלטים, layout אופטימלי

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
- [ ] **D1.1**: הוספת מודל `Parameters` למחלקה
  ```dart
  class Parameters {
    final Duration defaultWashingTime; // 5 min
    final Duration minWashingTime;     // 3 min
    final int safetyMarginBar;         // 50 bar
    final int defaultConsumptionRate;  // 100 L/min
    final int washingTeamRate;         // 70 L/min
  }
  ```

- [ ] **D1.2**: הוספת `Step` model + אוסף
  ```dart
  class Step {
    final String id;
    final StepType type; // enum: entry, arrival, exit, washStart, washEnd
    final DateTime timestamp;
    final String? teamId;
    final String? govId;
  }
  ```

- [ ] **D1.3**: הוספת `AirLog` model + אוסף
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

- [ ] **D1.4**: שירות חישובים מדויק
  ```dart
  class AirTimeCalculator {
    // timeLeft = washingTime - (volume × (pressure - 50)) / consumption
    Duration calculateTimeLeft({...});
    
    // requiredExit = now + timeLeftUpdated
    DateTime calculateRequiredExit({...});
  }
  ```

- [ ] **D1.5**: עדכון Repository עם אוספים חדשים

**תוצר**: מודל נתונים מלא + חישובים מדויקים

---

#### Day 3: FSM מלא + Undo
**מטרה**: מכונת מצבים מלאה עם Undo

**משימות**:
- [ ] **D3.1**: עדכון `StepFsm` - שלבים מלאים
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

- [ ] **D3.2**: Undo - החזרת שלב
  - מחיקת Step האחרון
  - איפוס שדות זמן
  - חישוב מחדש של טיימר
  
- [ ] **D3.3**: כפתור דינמי בממשק
  - טקסט משתנה: "כניסה לזירה" → "הגעה למוקד" → "יציאה" → ...
  - אייקון משתנה
  - צבע משתנה (ירוק → כתום → אדום)

- [ ] **D3.4**: רישום Steps אוטומטי
  - כל מעבר מצב נשמר
  - timestamp + teamId + state

**תוצר**: FSM מלא עם Undo

---

#### Day 4-5: Tablet UI + UX
**מטרה**: ממשק מותאם לטאבלט עם חוויית משתמש מלוטשת

**משימות**:
- [ ] **D4.1**: Tablet Layout אופטימלי
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

- [ ] **D4.3**: כרטיס צוות מוגדל
  - גופן ענק לטיימר (48-72px)
  - כפתורים גדולים (60×60)
  - רווחים נדיבים
  - צבעים ברורים

- [ ] **D4.4**: התראות חזותיות
  - צהוב: 5 דקות אחרונות
  - אדום: זמן סיום אוויר
  - אנימציה בולטת
  - כפתור "אישור" גדול

- [ ] **D4.5**: טסטים על טאבלט
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
- ✅ מודל נתונים: Steps, AirLogs, Parameters
- ✅ חישובים: נוסחה עם SafetyMargin=50
- ✅ FSM: 6 שלבים מלאים + Undo
- ✅ Tablet UI: Layout מותאם, טקסט גדול, כפתורים גדולים

### Week 2 - שכלול (Nice to Have)
- ✅ ולידציות: 50-330 UI, 0-300 DB
- ✅ Offline: שמירה לוקאלית + אירוע קיים
- ✅ צוות שטיפה: Consumption=70, Start/Stop
- ✅ סבבים: כניסה נוספת
- ✅ פוליש: התראות, אנימציות, טסטים

### MVP Success Criteria
- ✅ רץ על טאבלט (Chrome/Safari)
- ✅ עובד אופליין מלא
- ✅ חישובים מדויקים
- ✅ FSM מלא עם Undo
- ✅ UI ברור וקריא
- ✅ נתונים נשמרים ב-Firestore

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

### תחילת עבודה
בוא נתחיל עם **Day 1-2: מודל נתונים + חישובים**?

אני יכול:
1. 🚀 **להתחיל לקודד** - ליצור את Models, Repository, Calculator
2. 📝 **לפרט יותר** - לפרק משימה ספציפית לתתי-משימות
3. 🎨 **UI Mockup** - ליצור דוגמת UI לטאבלט

**מה תעדיף?**

---

## 📝 הערות

- כל ספרינט כולל זמן לבדיקות ותיקון באגים
- מומלץ code review אחרי כל משימה
- יש לעדכן README בסוף כל פאזה
- מומלץ demo למנהלים בסוף כל פאזה
