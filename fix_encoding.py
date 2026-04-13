import os
import glob

# Find all .html files recursively
for filepath in glob.glob('**/*.html', recursive=True):
    with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
        content = f.read()
    # Replace � with space
    content = content.replace('�', ' ')
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Processed {filepath}")