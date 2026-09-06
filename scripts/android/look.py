import re,sys
d=open(sys.argv[1],encoding='utf-8').read()
for n in re.finditer(r'<node[^>]*>',d):
    s=n.group(0)
    t=(re.search(r'text="([^"]*)"',s) or [None,''])[1]
    c=(re.search(r'content-desc="([^"]*)"',s) or [None,''])[1]
    if not (t or c): continue
    t=re.sub(r'\d[\d ]{6,}\d','<伏>',t); c=re.sub(r'\d[\d ]{6,}\d','<伏>',c)
    clk='clickable="true"' in s
    ck=re.search(r'checked="(true|false)"',s)
    b=re.search(r'bounds="\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]"',s)
    x1,y1,x2,y2=map(int,b.groups()) if b else (0,0,0,0)
    print(f'{"[押]" if clk else "   "} ({(x1+x2)//2},{(y1+y2)//2}) chk={ck.group(1) if ck else "-":5} {t!r} {c!r}')
