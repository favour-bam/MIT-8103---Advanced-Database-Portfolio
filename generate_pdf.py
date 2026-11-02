#!/usr/bin/env python3
import re
import subprocess
import os

md_path = "Bamishaye_Favour_Final_Report.md"
html_path = "Bamishaye_Favour_Final_Report.html"
pdf_path = "Bamishaye_Favour_Final_Report.pdf"

with open(md_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

html_lines = []
in_table = False
in_code = False

for line in lines:
    line = line.rstrip("\n")
    
    # Code block
    if line.startswith("```"):
        if in_code:
            html_lines.append("</pre>")
            in_code = False
        else:
            html_lines.append("<pre>")
            in_code = True
        continue
    
    if in_code:
        html_lines.append(line.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))
        continue

    # Tables
    if "|" in line:
        if not in_table:
            html_lines.append("<table>")
            in_table = True
        
        # Header / separator
        cells = [c.strip() for c in line.split("|")[1:-1]]
        if all(re.match(r"^:?-+:?$", c) for c in cells):
            continue
        
        row_tag = "th" if "Module" in line or "Criteria" in line or "Assigned" in line else "td"
        row_html = "<tr>" + "".join(f"<{row_tag}>{c}</{row_tag}>" for c in cells) + "</tr>"
        # bolding in cells
        row_html = re.sub(r"\*\*(.*?)\*\*", r"<strong>\1</strong>", row_html)
        html_lines.append(row_html)
        continue
    else:
        if in_table:
            html_lines.append("</table>")
            in_table = False

    if not line.strip():
        continue

    # Headings
    if line.startswith("# "):
        html_lines.append(f"<h1>{line[2:]}</h1>")
    elif line.startswith("## "):
        html_lines.append(f"<h2>{line[3:]}</h2>")
    elif line.startswith("### "):
        html_lines.append(f"<h3>{line[4:]}</h3>")
    elif line.startswith("---"):
        html_lines.append("<hr/>")
    elif line.startswith("- "):
        content = re.sub(r"\*\*(.*?)\*\*", r"<strong>\1</strong>", line[2:])
        content = re.sub(r"`(.*?)`", r"<code>\1</code>", content)
        html_lines.append(f"<li>{content}</li>")
    elif re.match(r"^\d+\.\s", line):
        content = re.sub(r"^\d+\.\s", "", line)
        content = re.sub(r"\*\*(.*?)\*\*", r"<strong>\1</strong>", content)
        content = re.sub(r"`(.*?)`", r"<code>\1</code>", content)
        html_lines.append(f"<p class='numbered'><strong>{line.split('.')[0]}.</strong> {content}</p>")
    else:
        content = re.sub(r"\*\*(.*?)\*\*", r"<strong>\1</strong>", line)
        content = re.sub(r"`(.*?)`", r"<code>\1</code>", content)
        content = re.sub(r"\[(.*?)\]\((.*?)\)", r"<a href='\2'>\1</a>", content)
        html_lines.append(f"<p>{content}</p>")

if in_table:
    html_lines.append("</table>")

styled_html = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>MIT 8103 Final Synthesis Report - Bamishaye Favour</title>
<style>
  @page {{
    size: A4;
    margin: 18mm 16mm 18mm 16mm;
  }}
  body {{
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    font-size: 10pt;
    line-height: 1.45;
    color: #1a202c;
    margin: 0;
    padding: 0;
  }}
  h1 {{
    font-size: 17pt;
    color: #1a365d;
    border-bottom: 2px solid #2b6cb0;
    padding-bottom: 4px;
    margin-top: 0;
    margin-bottom: 8px;
  }}
  h2 {{
    font-size: 12.5pt;
    color: #2b6cb0;
    border-bottom: 1px solid #cbd5e0;
    padding-bottom: 3px;
    margin-top: 14px;
    margin-bottom: 6px;
    page-break-after: avoid;
  }}
  h3 {{
    font-size: 10.5pt;
    color: #2d3748;
    margin-top: 10px;
    margin-bottom: 4px;
    page-break-after: avoid;
  }}
  p {{
    margin: 4px 0;
  }}
  .numbered {{
    margin: 3px 0 3px 12px;
  }}
  table {{
    width: 100%;
    border-collapse: collapse;
    margin: 8px 0;
    font-size: 8.5pt;
    page-break-inside: avoid;
  }}
  th, td {{
    border: 1px solid #cbd5e0;
    padding: 4px 6px;
    text-align: left;
    vertical-align: top;
  }}
  th {{
    background-color: #ebf8ff;
    color: #2b6cb0;
    font-weight: 600;
  }}
  pre {{
    background-color: #f7fafc;
    border: 1px solid #e2e8f0;
    border-radius: 4px;
    padding: 6px;
    font-family: Menlo, Monaco, Consolas, monospace;
    font-size: 7.5pt;
    line-height: 1.25;
    overflow-x: auto;
    margin: 6px 0;
    page-break-inside: avoid;
  }}
  code {{
    font-family: Menlo, Monaco, Consolas, monospace;
    font-size: 8.5pt;
    background-color: #edf2f7;
    padding: 1px 3px;
    border-radius: 2px;
  }}
  hr {{
    border: 0;
    border-top: 1px solid #e2e8f0;
    margin: 10px 0;
  }}
  a {{
    color: #2b6cb0;
    text-decoration: none;
  }}
  li {{
    margin: 2px 0;
    margin-left: 14px;
  }}
</style>
</head>
<body>
{"".join(html_lines)}
</body>
</html>
"""

with open(html_path, "w", encoding="utf-8") as f:
    f.write(styled_html)

print(f"[+] HTML written to {html_path}")

cmd = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "--headless",
    "--disable-gpu",
    f"--print-to-pdf={pdf_path}",
    os.path.abspath(html_path)
]

res = subprocess.run(cmd, capture_output=True, text=True)
if os.path.exists(pdf_path):
    size_kb = os.path.getsize(pdf_path) / 1024
    print(f"[+] PDF generated successfully: {pdf_path} ({size_kb:.1f} KB)")
else:
    print(f"[!] PDF generation failed: {res.stderr}")
