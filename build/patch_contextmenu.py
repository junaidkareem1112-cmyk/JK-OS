JK = '/home/hatch/workspace/jk-os'

# privacy-install: git-gui + gitk packages + smoke
p = f'{JK}/privacy-install.sh'; s = open(p).read()
s = s.replace('persepolis aria2 uget"', 'persepolis aria2 uget git-gui gitk"')
old = 'aria2c --version >> $V 2>&1 | head -1'
assert old in s
s = s.replace(old, old + '''
[ -x /usr/lib/git-core/git-gui ] && echo "SMOKE PASS git-gui" >> $V || echo "SMOKE FAIL git-gui" >> $V
command -v gitk >/dev/null 2>&1 && echo "SMOKE PASS gitk" >> $V || echo "SMOKE FAIL gitk" >> $V''', 1)
open(p, 'w').write(s); print("privacy-install: git-gui/gitk hooked")

# systools-customize: uca.xml + helper + templates
p = f'{JK}/systools-customize.sh'; s = open(p).read()
add = r'''
# ---- Right-click menu (Thunar Custom Actions) ----
install -m755 "$JK/jk-context.py" "$R/usr/local/bin/jk-context"
mkdir -p "$SKEL/.config/Thunar"
cat > "$SKEL/.config/Thunar/uca.xml" <<'EOFU'
<?xml version="1.0" encoding="UTF-8"?>
<actions>
<action><icon>utilities-terminal</icon><name>Open in Terminal</name><unique-id>jk-term-1</unique-id><command>jk-context terminal %f</command><description>Is folder me Terminal kholein</description><patterns>*</patterns><directories/><files/></action>
<action><icon>utilities-terminal</icon><name>Open PowerShell Here</name><unique-id>jk-pwsh-1</unique-id><command>jk-context powershell %f</command><description>PowerShell yahan kholein</description><patterns>*</patterns><directories/><files/></action>
<action><icon>git</icon><name>Open Git GUI here</name><unique-id>jk-gui-1</unique-id><command>jk-context gitgui %f</command><description>Git GUI (repo ho to)</description><patterns>*</patterns><directories/></action>
<action><icon>utilities-terminal</icon><name>Open Git Bash here</name><unique-id>jk-bash-1</unique-id><command>jk-context gitbash %f</command><description>Git Bash terminal yahan</description><patterns>*</patterns><directories/><files/></action>
<action><icon>codium</icon><name>Open in Code Editor</name><unique-id>jk-code-1</unique-id><command>jk-context code %f</command><description>VSCodium me kholein</description><patterns>*</patterns><directories/><files/></action>
<action><icon>dialog-password</icon><name>Open as Administrator</name><unique-id>jk-admin-1</unique-id><command>jk-context admin %f</command><description>Admin (root) se kholein - password lagega</description><patterns>*</patterns><directories/><files/></action>
</actions>
EOFU
python3 -c "import xml.dom.minidom; xml.dom.minidom.parse('$SKEL/.config/Thunar/uca.xml')" && echo "uca.xml VALID" || echo "uca.xml INVALID"
# ---- Templates (New / Create Document) ----
mkdir -p "$SKEL/Templates"
: > "$SKEL/Templates/Text Document.txt"
printf '# Title\n\n' > "$SKEL/Templates/Markdown.md"
python3 - "$SKEL/Templates" <<'PYEOF'
import sys, zipfile, os
base = sys.argv[1]
def odf(path, mime):
    content = ('<?xml version="1.0" encoding="UTF-8"?>'
      '<office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" '
      'xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" '
      'xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" '
      'xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" office:version="1.2">'
      '<office:body>' + ('<office:text><text:p/></office:text>' if mime.endswith('text') else
      '<office:spreadsheet><table:table/></office:spreadsheet>' if mime.endswith('spreadsheet') else
      '<office:presentation><draw:page/></office:presentation>') + '</office:body></office:document-content>')
    manifest = ('<?xml version="1.0" encoding="UTF-8"?>'
      '<manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0">'
      f'<manifest:file-entry manifest:full-path="/" manifest:media-type="{mime}"/>'
      '<manifest:file-entry manifest:full-path="content.xml" manifest:media-type="text/xml"/></manifest:manifest>')
    with zipfile.ZipFile(path, 'w') as z:
        z.writestr(zipfile.ZipInfo('mimetype'), mime, compress_type=zipfile.ZIP_STORED)
        z.writestr('content.xml', content, compress_type=zipfile.ZIP_DEFLATED)
        z.writestr('META-INF/MANIFEST.MF', manifest, compress_type=zipfile.ZIP_DEFLATED)
odf(os.path.join(base, 'Word Document.odt'), 'application/vnd.oasis.opendocument.text')
odf(os.path.join(base, 'Spreadsheet.ods'), 'application/vnd.oasis.opendocument.spreadsheet')
odf(os.path.join(base, 'Presentation.odp'), 'application/vnd.oasis.opendocument.presentation')
print("ODF templates generated")
PYEOF
ls -la "$SKEL/Templates"
echo "context menu + templates done"
'''
s = s.replace('echo "=== SYSTOOLS CUSTOMIZE DONE ==="', add + '\necho "=== SYSTOOLS CUSTOMIZE DONE ==="')
open(p, 'w').write(s); print("systools: context menu + templates added")
