import re
import os

files = [
    "lib/screens/splash_screen.dart",
    "lib/screens/login_screen.dart",
    "lib/screens/search_screen.dart",
    "lib/screens/upload_screen.dart",
    "lib/screens/profile_screen.dart",
    "lib/screens/alerts_screen.dart",
    "lib/screens/messages_screen.dart",
    "lib/widgets/comments_sheet.dart",
    "lib/widgets/share_sheet.dart",
    "lib/widgets/quiz_popup.dart",
]

def fix_file(filepath):
    if not os.path.exists(filepath):
        print(f"SKIP: {filepath}")
        return

    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    changed = False
    new_lines = []

    for i, line in enumerate(lines):
        # Look at a window of current + next 3 lines
        window = ''.join(lines[i:min(i+4, len(lines))])
        
        # If AppColors appears nearby and this line has const, remove const
        if 'const ' in line and 'AppColors.' in window:
            fixed = line.replace('const ', '', 1)
            if fixed != line:
                new_lines.append(fixed)
                changed = True
                print(f"  Fixed line {i+1}")
                continue
        
        new_lines.append(line)

    if changed:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        print(f"✓ FIXED: {filepath}")
    else:
        print(f"  OK: {filepath}")

print("Fixing AppColors const errors...\n")
for f in files:
    print(f"Processing: {f}")
    fix_file(f)
    print()

print("=" * 50)
print("Done! Now run: flutter run")
