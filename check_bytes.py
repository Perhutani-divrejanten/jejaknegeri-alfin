with open('article/berita17-f.html', 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()
    if '�' in content:
        print("Found � in content")
        pos = content.find('�')
        print(f"At position {pos}: {repr(content[pos-10:pos+10])}")
    else:
        print("No � found")