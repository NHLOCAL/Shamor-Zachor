# הפצת Windows

בעת יצירת תג חדש ב-GitHub, תהליך ה-CI יוצר שתי חבילות ל-Windows:

- `shamor-vezachor-<version>-windows-setup.exe` - מתקין רגיל בעברית, מבוסס Inno Setup.
- `shamor-vezachor-<version>-windows-portable.zip` - גרסה ניידת ללא התקנה. יש לחלץ את הקובץ ולהריץ את `ShamorVezachor.exe`.

## מתקין Inno Setup

קובץ ההגדרות נמצא ב-`installer/windows/shamor-vezachor.iss`.

מאפייני המתקין:

- שפת ברירת המחדל היא עברית, עם תמיכה גם באנגלית.
- התקנה ללא הרשאות מנהל לתיקיית המשתמש: `%LOCALAPPDATA%\Programs\Shamor Vezachor`.
- יצירת קיצור דרך בתפריט ההתחלה.
- אפשרות בחירה ליצירת קיצור דרך בשולחן העבודה.
- הפעלת האפליקציה בסיום ההתקנה.

## בדיקה מקומית של המתקין

לאחר בניית Windows מקומית:

```powershell
cd src
flutter build windows --release
cd ..

choco install innosetup --no-progress --yes
& "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe" `
  "installer\windows\shamor-vezachor.iss" `
  "/DMyAppVersion=0.0.0-local" `
  "/DMyAppSourceDir=$PWD\src\build\windows\x64\runner\Release" `
  "/DMyAppOutputDir=$PWD" `
  "/DMyAppOutputBaseFilename=windows-setup"
```

הפלט המקומי יהיה `windows-setup.exe`.
