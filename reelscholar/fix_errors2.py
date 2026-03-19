import re
import os

files = [
    "lib/screens/alerts_screen.dart",
    "lib/screens/login_screen.dart",
    "lib/screens/messages_screen.dart",
    "lib/screens/profile_screen.dart",
    "lib/screens/search_screen.dart",
    "lib/screens/splash_screen.dart",
    "lib/screens/upload_screen.dart",
    "lib/widgets/comments_sheet.dart",
    "lib/widgets/quiz_popup.dart",
    "lib/widgets/share_sheet.dart",
]

def fix_file(filepath):
    if not os.path.exists(filepath):
        print(f"SKIP: {filepath}")
        return

    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    changed = False
    new_lines = []

    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Check if this line has const and the next few lines have withValues
        if 'const ' in line:
            # Look ahead up to 5 lines for withValues
            window = ''.join(lines[i:min(i+6, len(lines))])
            if '.withValues(' in window:
                fixed = line.replace('const ', '', 1)
                if fixed != line:
                    new_lines.append(fixed)
                    changed = True
                    print(f"  Line {i+1}: removed const")
                    i += 1
                    continue
        
        new_lines.append(line)
        i += 1

    if changed:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        print(f"FIXED: {filepath}")
    else:
        print(f"OK: {filepath}")

print("Running aggressive const fix...\n")
for f in files:
    fix_file(f)
print("\nAll done! Run: flutter build apk --debug")