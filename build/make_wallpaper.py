#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont
import os, sys
W,H=1920,1080
pine=(12,91,68); charcoal=(10,31,24); cream=(250,246,238); amber=(199,154,43); dark2=(7,22,17)
img=Image.new('RGB',(W,H),charcoal)
d=ImageDraw.Draw(img,'RGBA')
# solid editorial blocks (NO gradients per user brand rule)
d.rectangle([0,H-180,W,H], fill=pine)
d.rectangle([0,H-192,W,H-180], fill=amber)
d.polygon([(1250,0),(1920,0),(1920,1080),(1550,1080)], fill=dark2)
d.ellipse([1220,180,1780,740], fill=pine)
d.ellipse([1330,290,1670,630], fill=charcoal)
# logo
logo_path=sys.argv[1] if len(sys.argv)>1 else ''
out=sys.argv[2] if len(sys.argv)>2 else 'wallpaper.png'
if logo_path and os.path.exists(logo_path):
    try:
        lg=Image.open(logo_path).convert('RGBA'); lg.thumbnail((260,260))
        img.paste(lg,(90,70),lg); d=ImageDraw.Draw(img,'RGBA')
    except Exception as e: print('logo paste failed',e)
def font(sz,bold=False):
    for p in ["/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"]:
        if os.path.exists(p): return ImageFont.truetype(p,sz)
    return ImageFont.load_default()
d.text((95,380),"JK OS",font=font(150,True),fill=cream)
d.text((100,560),"Smart Solutions, Stronger Business.",font=font(44),fill=(210,225,218))
d.text((100,640),"By JK Soft Solutions  •  Lightweight  •  Powerful  •  Secure",font=font(32),fill=amber)
# simple window mock in circle area
d.rounded_rectangle([1385,400,1625,620],radius=18,fill=cream)
d.rectangle([1385,400,1625,455],fill=pine)
for i,c in enumerate([(220,80,60),(230,180,60),(80,200,120)]): d.ellipse([1405+i*38,418,1433+i*38,446],fill=c)
d.rectangle([1415,485,1595,510],fill=(180,190,185)); d.rectangle([1415,530,1595,555],fill=(200,205,200)); d.rectangle([1415,575,1520,600],fill=pine)
img.save(out,'PNG')
print('saved',out,img.size)
