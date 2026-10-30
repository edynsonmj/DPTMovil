import re,collections,subprocess,sys
t=open(sys.argv[1],encoding='utf-8').read()
nodes=set(re.findall(r'^\s*"(/[^"]+\.dart)" \[',t,re.M))
edges=re.findall(r'"(/[^"]+\.dart)" -> "(/[^"]+\.dart)"',t)
def L(p):
    for pre,k in [('/presentation/viewmodels','VM'),('/presentation/view/','View'),('/domain/servicios','Serv'),('/domain/entities','Ent'),('/data/repositories','Repo'),('/data/api','Api'),('/data/models','DModel')]:
        if p.startswith(pre):return k
    if p.startswith('/domain/'):return 'DomOtro'
    return None
ALLOWED={('View','VM'),('View','Ent'),('VM','Serv'),('VM','Ent'),('Serv','Repo'),('Serv','Ent'),('Serv','DModel'),
 ('Repo','Api'),('Repo','DModel'),('Repo','Ent'),('Api','DModel'),('Api','Ent'),('DModel','Ent')}
NAME={'View':'View','VM':'ViewModel','Serv':'Servicios','Repo':'Repositorios','Api':'Conexiones (API)','DModel':'Modelos de datos','Ent':'Entidades'}
cnt=collections.Counter(L(n) for n in nodes if L(n))
viol=collections.defaultdict(set)
for a,b in edges:
    la,lb=L(a),L(b)
    if la and lb and 'DomOtro' not in (la,lb) and la!=lb and (la,lb) not in ALLOWED: viol[a].add(b)
X={k:(cnt[k]-sum(1 for f in viol if L(f)==k))/cnt[k] for k in cnt}
RED='#d03b3b'; GRAY='#898781'; INK='#0b0b0b'; SEC='#52514e'
FILL={'View':'#cde2fb','VM':'#cde2fb','Serv':'#d6f0e4','Repo':'#f3f2ee','Api':'#f3f2ee','DModel':'#f3f2ee','Ent':'#fdecc8'}
def fx(v):return f"{v:.2f}".replace('.',',')
tot=sum(cnt.values()); A=tot-len(viol)
# ---------- Fig 1: layers
agg=collections.Counter((L(a),L(b)) for a,b in edges if L(a) and L(b) and L(a)!=L(b) and 'DomOtro' not in (L(a),L(b)))
g=['digraph G {','graph [rankdir=TB fontname="DejaVu Sans" bgcolor="white" nodesep=0.9 ranksep=0.75 pad=0.4 fontsize=20 labelloc=t label=<<b>Dependencias entre capas — DPTMovil</b><br/><font point-size="13" color="%s">Acoplamiento de componentes X = %d/%d = %s · flechas = n.º de imports entre archivos</font>>];'%(SEC,A,tot,fx(A/tot)),
   'node [shape=box style="rounded,filled" fontname="DejaVu Sans" color="#52514e" penwidth=1.2 margin="0.25,0.12"];',
   'edge [fontname="DejaVu Sans" fontsize=12 arrowsize=0.8];']
for k in ['View','VM','Serv','Repo','Api','DModel','Ent']:
    xc = INK if X[k]>=0.9 else RED
    g.append(f'{k} [label=<<b>{NAME[k]}</b><br/><font point-size="11" color="{SEC}">{cnt[k]} archivos</font><br/><font point-size="12" color="{xc}">X = {fx(X[k])}</font>> fillcolor="{FILL[k]}"];')
g+=['{rank=same; Repo; Ent;}','{rank=same; Api; DModel;}']
order=[('View','VM'),('VM','Serv'),('Serv','Repo')]
for (a,b),n in sorted(agg.items()):
    ok=(a,b) in ALLOWED
    if ok: g.append(f'{a} -> {b} [label=" {n}" color="{GRAY}" fontcolor="{SEC}" penwidth={1+min(n,60)/25:.1f}];')
    else: g.append(f'{a} -> {b} [label=<<b> {n}</b>> color="{RED}" fontcolor="{RED}" penwidth={1.5+min(n,60)/20:.1f} constraint=false];')
g.append(f'subgraph cluster_leg {{label=<<b>Convención</b>> fontsize=12 style="rounded" color="#cfcdc6"; l1 [shape=plaintext style="" label=<<table border="0" cellspacing="4"><tr><td><font color="{GRAY}">━━▶</font></td><td align="left">Dependencia permitida</td></tr><tr><td><font color="{RED}"><b>━━▶</b></font></td><td align="left">Viola la arquitectura (MVVM + servicios)</td></tr></table>> fontsize=12];}}')
g.append('DModel -> l1 [style=invis];}')
open('capas.dot','w').write('\n'.join(g))
# ---------- Fig 2: violations detail
cause={}
def C(a,b):
    la,lb=L(a),L(b)
    if b.endswith(('respuestaModelo.dart','errorModelo.dart')):return 1
    if la=='Serv' and lb=='Api':return 2
    if la=='Ent' and lb=='DModel':return 3
    if lb in('View',) :return 4
    if la=='View' and lb=='Api':return 4
    return 4
CC={1:'#2a78d6',2:'#1baf7a',3:'#eda100',4:RED}
CN={1:'1 · respuestaModelo/errorModelo en data/models',2:'2 · Servicios importan conexiones',3:'3 · Ciclo entidad ↔ modelo',4:'4 · Hacia la interfaz (y page1 → conexión)'}
used=set();E=[]
for a,bs in viol.items():
    for b in bs:
        E.append((a,b,C(a,b)));used|={a,b}
lab=lambda p:p.split('/')[-1].replace('.dart','')
h=['digraph G {','graph [rankdir=LR fontname="DejaVu Sans" bgcolor="white" nodesep=0.12 ranksep=1.6 pad=0.4 newrank=true labelloc=t fontsize=20 label=<<b>Dependencias que violan la arquitectura — %d archivos</b><br/><font point-size="13" color="%s">Color de la flecha = causa raíz</font>>];'%(len(viol),SEC),
   'node [shape=box style="rounded,filled" fontname="DejaVu Sans" fontsize=11 color="#898781" height=0.25 margin="0.08,0.03"];','edge [arrowsize=0.6 penwidth=1.2];']
for k in ['View','VM','Serv','Api','DModel','Ent']:
    fs=sorted(f for f in used if L(f)==k)
    if not fs:continue
    h.append(f'subgraph cluster_{k} {{label=<<b>{NAME[k]}</b>> fontsize=14 style="rounded,filled" fillcolor="#fafaf8" color="#cfcdc6";')
    for f in fs:
        bad=f in viol
        h.append(f'"{f}" [label="{lab(f)}" fillcolor="{FILL[k]}" {"penwidth=2 color=\""+RED+"\"" if bad else ""}];')
    h.append('}')
for a,b,c in E:h.append(f'"{a}" -> "{b}" [color="{CC[c]}"];')
rows=''.join(f'<tr><td><font color="{CC[i]}"><b>━━▶</b></font></td><td align="left">{CN[i]} ({sum(1 for e in E if e[2]==i)} imports)</td></tr>' for i in CC)
h.append(f'leg [shape=plaintext style="" label=<<table border="0" cellspacing="3">{rows}<tr><td><font color="{RED}">▢</font></td><td align="left">Borde rojo = archivo que no cumple</td></tr></table>> fontsize=12];')
h.append('}')
open('violaciones.dot','w').write('\n'.join(h))
print(cnt,len(viol),A,tot,collections.Counter(e[2] for e in E))
