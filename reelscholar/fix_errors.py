import re
import os

# All files with invalid_constant errors
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
        print(f"SKIP (not found): {filepath}")
        return

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # Fix 1: Remove const from BoxDecoration containing withValues
    # Pattern: const BoxDecoration( ... withValues ...
    content = re.sub(r'const (BoxDecoration\()', r'\1', content)
    
    # Fix 2: Remove const from Border.all containing withValues
    content = re.sub(r'const (Border\.all\()', r'\1', content)
    
    # Fix 3: Remove const from BorderSide containing withValues  
    content = re.sub(r'const (BorderSide\()', r'\1', content)

    # Fix 4: The main fix — find lines with withValues and remove const before widget constructors
    lines = content.split('\n')
    fixed_lines = []
    
    for i, line in enumerate(lines):
        if '.withValues(' in line and 'const ' in line:
            # Remove const keyword from this line
            fixed_line = line.replace('const ', '', 1)
            fixed_lines.append(fixed_line)
            if fixed_line != line:
                print(f"  Fixed line {i+1}: removed const")
        else:
            fixed_lines.append(line)
    
    content = '\n'.join(fixed_lines)

    # Fix 5: splash_screen specific - const_with_non_constant_argument
    # Remove const from AlwaysStoppedAnimation with withValues
    content = re.sub(
        r'const (AlwaysStoppedAnimation<Color>\([^)]*\.withValues[^)]*\))',
        r'\1',
        content
    )

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"FIXED: {filepath}")
    else:
        print(f"NO CHANGES: {filepath}")

print("Fixing invalid_constant errors...\n")
for filepath in files:
    fix_file(filepath)

print("\nDone! Now run: flutter build apk --debug")