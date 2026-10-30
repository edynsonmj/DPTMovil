"""Diagrama de dependencias de un solo modulo, ordenado por capas.
Uso: python modulo.py dependencias.dot <modulo|todos> [carpeta_salida]
Genera <modulo>.dot; luego: dot -Tpng -Gdpi=180 <modulo>.dot -o <modulo>.png
"""
import re,sys,os,collections
MODULOS={'alumno':'alumno','atencion':'atencion','autenticacion':'autenticaci','categoria':'categori','clase':'clase',
 'curso':'curso','deporte':'deporte','estadisticas':'estadistic','facultad':'facultad','grupo':'grupo','horario':'horario',
 'imagen':'imagen','inscripcion':'inscripci','instructor':'instructor'}
CAPAS=[('View','/presentation/view/','View','#cde2fb'),('VM','/presentation/viewmodels','ViewModel','#cde2fb'),
 ('Serv','/domain/servicios','Servicios','#d6f0e4'),('Repo','/data/repositories','Repositorios','#f3f2ee'),
 ('Api','/data/api','Conexiones (API)','#f3f2ee'),('DModel','/data/models','Modelos de datos','#f3f2ee'),('Ent','/domain/entities','Entidades','#fdecc8')]
PERM={('View','VM'),('View','Ent'),('VM','Serv'),('VM','Ent'),('Serv','Repo'),('Serv','Ent'),('Serv','DModel'),
 ('Repo','Api'),('Repo','DModel'),('Repo','Ent'),('Api','DModel'),('Api','Ent'),('DModel','Ent')}
RED='#d03b3b';GRAY='#898781';SEC='#52514e'
def capa(p):
    for k,pre,_,_ in CAPAS:
        if p.startswith(pre):return k
def nombre(p):return p.split('/')[-1].replace('.dart','')
def generar(dotfile,mod,outdir):
    t=open(dotfile,encoding='utf-8').read()
    edges=[(a,b) for a,b in re.findall(r'"(/[^"]+\.dart)" -> "(/[^"]+\.dart)"',t) if capa(a) and capa(b)]
    nodes=set(re.findall(r'^\s*"(/[^"]+\.dart)" \[',t,re.M))
    pat=re.compile(MODULOS[mod])
    propios={n for n in nodes if capa(n) and pat.search(n.lower())}
    E=[(a,b) for a,b in edges if a in propios or b in propios]
    E=[(a,b) for a,b in E if a in propios]  # solo lo que el modulo importa
    # se omiten los widgets compartidos usados por las Views (no aportan a la lectura por capas)
    E=[(a,b) for a,b in E if not (b.startswith('/presentation/view/widgets/') and capa(a)=='View')]
    vis=propios|{b for a,b in E}
    viol=[(a,b) for a,b in E if capa(a)!=capa(b) and (capa(a),capa(b)) not in PERM]
    g=['digraph G {',
     f'graph [rankdir=TB fontname="DejaVu Sans" bgcolor="white" nodesep=0.25 ranksep=0.55 pad=0.35 labelloc=t fontsize=18 label=<<b>Módulo {mod}: dependencias por capa</b><br/><font point-size="12" color="{SEC}">{len(propios)} archivos del módulo · {len(E)} imports · <font color="{RED}">{len(viol)} violan la arquitectura</font></font>>];',
     'node [shape=box style="rounded,filled" fontname="DejaVu Sans" fontsize=11 color="#52514e" margin="0.12,0.05" height=0.3];',
     'edge [arrowsize=0.6];']
    prev=None
    for k,_,lab,fill in CAPAS:
        fs=sorted(n for n in vis if capa(n)==k)
        g.append(f'L_{k} [shape=plaintext style="" fontsize=12 fontcolor="{SEC}" label=<<b>{lab}</b>>];')
        for f in fs:
            mal=any(a==f for a,b in viol)
            st=f'fillcolor="{fill}"' if f in propios else 'fillcolor="white" style="rounded,dashed" fontcolor="#52514e"'
            if mal: st+=f' color="{RED}" penwidth=2'
            g.append(f'"{f}" [label="{nombre(f)}" {st}];')
        g.append('{rank=same; L_%s; %s}'%(k,' '.join(f'"{f}";' for f in fs)))
        if prev:g.append(f'L_{prev} -> L_{k} [style=invis];')
        prev=k
    for a,b in E:
        bad=(a,b) in viol
        up=[c[0] for c in CAPAS].index(capa(b))<[c[0] for c in CAPAS].index(capa(a))
        g.append(f'"{a}" -> "{b}" [color="{RED if bad else GRAY}" penwidth={2.2 if bad else 1.1}{" constraint=false" if up else ""}];')
    g.append(f'leg [shape=plaintext style="" fontsize=11 label=<<table border="0" cellspacing="2"><tr><td><font color="{GRAY}">━━▶</font></td><td align="left">Permitida</td><td>  </td><td><font color="{RED}"><b>━━▶</b></font></td><td align="left">Viola la arquitectura</td><td>  </td><td align="left">Borde punteado = archivo de otro módulo · se omiten widgets compartidos</td></tr></table>>];')
    g.append(f'L_Ent -> leg [style=invis];')
    g.append('}')
    out=os.path.join(outdir,f'{mod}.dot');open(out,'w',encoding='utf-8').write('\n'.join(g))
    print(f'{mod}: {len(propios)} archivos, {len(E)} imports, {len(viol)} violaciones -> {out}')
if __name__=='__main__':
    dotfile,mod=sys.argv[1],sys.argv[2];outdir=sys.argv[3] if len(sys.argv)>3 else '.'
    os.makedirs(outdir,exist_ok=True)
    for m in (MODULOS if mod=='todos' else [mod]):generar(dotfile,m,outdir)
