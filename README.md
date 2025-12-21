# ניהול זמן אוויר | Air-Time Manager

אפליקציית Flutter לניהול זמן אוויר של צוותים במשימות ואימונים. מותאמת לעברית (RTL) עם ארכיטקטורה local-first ותמיכה ב-Firebase.

## 🎯 תכונות עיקריות

### ✨ ניהול אירועים
- **יצירת אירועים חדשים** - הגדרת אירוע עם פרמטרים מותאמים אישית
- **ניהול פרמטרים** - זמן שטיפה מינימלי, לחץ מינימלי, סף התראה
- **מעקב בזמן אמת** - Stream-based עדכונים של כל הנתונים

### 👥 ניהול צוותים
- **הוספת צוותים דינמית** - יצירת צוותים חדשים תוך כדי משימה
- **הוספת לוחמים** - הוספת חברי צוות עם זמן אוויר אישי
- **State Machine** - מעבר בין שלבים: התחלה → הגעה → יציאה → שטיפה
- **כפתור ביטול (Undo)** - ביטול פעולה אחרונה לכל צוות

### 🧮 מחשבון בלון חמצן
- **חישוב מדויק** של זמן אוויר לפי נוסחה: \`זמן = (לחץ × נפח) / קצב צריכה\`
- **פרמטרים להזנה**:
  - לחץ בבלון (bar)
  - נפח הבלון (ליטר)
  - קצב צריכה (ליטר/דקה)
- **אינטגרציה** - כפתור מהיר בדיאלוג הוספת צוות/לוחם

### ⏱️ ניהול זמן
- **טיימר אוטומטי** - ספירה לאחור של זמן אוויר
- **עדכון כל שנייה** - תצוגה בזמן אמת
- **חישוב זמן יציאה** - חישוב אוטומטי של שעת יציאה נדרשת
- **פסי התקדמות** - ויזואליזציה של צריכת זמן אוויר

### 🔔 התראות
- **התראות אוטומטיות** - התראה כשצוות מתקרב לסיום זמן
- **ספירת התראות** - מעקב אחר מספר צוותים בסיכון
- **באנר חזותי** - התראה בולטת בראש המסך

### 📊 דוחות וסטטיסטיקות
- **טאב סיכום**:
  - פרטי אירוע (שם, תאריך, שעה)
  - סטטיסטיקות כלליות (צוותים, לוחמים, זמן אוויר)
  - אחוז שימוש עם ויזואליזציה
  
- **טאב צוותים**:
  - ביצועי כל צוות בנפרד
  - זמן כולל vs. שנוצל vs. נותר
  - פסי התקדמות לכל צוות
  
- **טאב יומן**:
  - רשימת כל הפעולות
  - מסודר לפי זמן (חדש לישן)
  - תיעוד מלא של האירוע

### 📱 Responsive Design
- **תמיכה מלאה בטאבלטים** - Layout side-by-side מעל 900px
- **מסכי טלפון** - Layout עם טאבים
- **כרטיסים מותאמים** - התאמה אוטומטית לרוחב מסך
- **גופנים דינמיים** - התאמת גודל לפי מסך

## 🏗️ ארכיטקטורה

### Repository Pattern
- \`AirTimeRepository\` - ממשק אחיד לגישה לנתונים
- \`InMemoryAirTimeRepository\` - מימוש מקומי לפיתוח ודמו
- \`FirestoreAirTimeRepository\` - מימוש Firebase מלא

### State Management
- **Stream-based** - Reactive updates עם StreamBuilder
- **AppScope** - Inherited Widget לגישה ל-repository
- **Local State** - StatefulWidget לניהול מצב UI

### FSM (Finite State Machine)
- \`StepFsm\` - ניהול מעברים בין שלבי משימה
- מעברים: \`null → start → arrive → exit → washing → start\`
- שליטה אוטומטית על הטיימר לפי שלב

## 🚀 הרצת האפליקציה

### בסביבת Dev Container

Flutter מותקן ב-\`/opt/flutter/bin/flutter\`.

### הרצה מומלצת (Web - יציב)

בנייה + הפעלת שרת סטטי:

\`\`\`bash
./tool/flutter build web
python3 -m http.server 8080 --directory build/web
\`\`\`

פתח את ה-URL של הפורט המועבר.

### הרצת פיתוח (Hot Reload)

\`\`\`bash
./tool/flutter run -d web-server --web-port=8080
\`\`\`

אם שינויים לא מופיעים, עשה refresh קשה (\`Ctrl+Shift+R\`).

## 🔥 Firebase

Firebase מוכן לשימוש אך כרגע פועל במצב local-first.

### קבצי תצורה קיימים:
- \`firebase.json\` - תצורת Firebase
- \`firestore.rules\` - חוקי אבטחה
- \`firestore.indexes.json\` - אינדקסים

### הגדרת Firebase (אופציונלי)

1. התקן Firebase CLI + FlutterFire CLI
2. הרץ \`flutterfire configure\` ליצירת \`lib/firebase_options.dart\`
3. Deploy rules:

\`\`\`bash
firebase deploy --only firestore:rules
\`\`\`

**הערה**: כרגע האפליקציה פועלת מצוין במצב local ללא צורך ב-Firebase.

## 📂 מבנה הפרויקט

\`\`\`
lib/
├── app/                    # תצורת אפליקציה
│   ├── app.dart           # MaterialApp ראשי
│   ├── app_scope.dart     # Inherited Widget
│   ├── theme/             # עיצוב ונושא
│   └── firebase/          # Firebase bootstrap
├── common/                # כלים משותפים
│   └── formatters/        # פורמט זמן ותאריכים
├── data/
│   ├── models/            # מודלים (Event, Team, Member, etc.)
│   └── repositories/      # Repository implementations
├── features/
│   ├── event/             # מסכי אירוע
│   │   ├── event_screen.dart
│   │   ├── create_event_screen.dart
│   │   └── event_selection_screen.dart
│   ├── teams/             # מסכי צוותים
│   │   ├── teams_screen.dart
│   │   └── widgets/       # כרטיסים ודיאלוגים
│   └── reports/           # דוחות וסטטיסטיקות
└── services/              # שירותים
    ├── step_fsm.dart      # State Machine
    └── alert_service.dart # התראות
\`\`\`

## 🛠️ טכנולוגיות

- **Flutter** - Framework
- **Dart** - שפת תכנות
- **Material Design 3** - עיצוב UI
- **Firebase** (אופציונלי) - Backend
  - Cloud Firestore - מסד נתונים
  - Firebase Auth - אימות
- **Stream-based architecture** - Reactive programming

## 📝 הערות פיתוח

### נתוני דמו
האפליקציה מגיעה עם נתוני דמו:
- 3 צוותים (אלפא, בראבו, צ'רלי)
- 4 לוחמים עם זמני אוויר שונים
- אירוע דמו פעיל

### זמנים
- כל הזמנים מוצגים בפורמט HH:MM:SS
- הזנת זמנים בדקות (UI פשוט)
- חישובים אוטומטיים של זמן יציאה

### Responsive
- Breakpoint טאבלטים: 900px
- Breakpoint כרטיסים צרים: 400px
- Breakpoint StatusCards: 720px

## 🎨 עיצוב

- **RTL מלא** - תמיכה מלאה בעברית
- **Material Design 3** - עיצוב מודרני
- **Dark/Light Theme Ready** - מוכן לשני מצבים
- **Accessible** - נגיש לכולם

## 📄 רישיון

MIT License

---

**מפותח עם ❤️ ב-Flutter**
