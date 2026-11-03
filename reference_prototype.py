"""Reference prototype (Python/SciPy) for the Defender-Attacker Quarto project.
Used only to generate the reference values in the development plan. The project itself is built in R."""
import numpy as np
from scipy.optimize import linprog, minimize
ids=["PLAT","PIPE","DATA","IDP","CORP","VEND"]
L=np.array([45,60,30,18,10,20.]); DC=0.10
V=np.array([6.0,2.5,5.0,7.0,5.5,4.0]); AC=np.array([-1.0,-1.0,-1.0,-0.5,-0.3,-0.5])
K=np.array([4.0,3.0,2.5,2.0,3.0,5.0]); CB=np.array([.9,.9,.9,.9,.85,.7]); P=np.array([.30,.15,.30,.25,.50,.20])
FL=0.25; Ud_u=-L; Ud_c=-DC*L
def Ud(c): return c*Ud_c+(1-c)*Ud_u
def Ua(c,Va=V,Ac=AC): return c*Ac+(1-c)*Va
def br(c,Va=V,Ac=AC):
    u=Ua(c,Va,Ac); S=np.where(u>=u.max()-1e-7)[0]; return S[np.argmax(Ud(c)[S])]
def sse(B,Va=V,Ac=AC,floor=FL,cb=CB,k=K,ud_c=Ud_c,ud_u=Ud_u):
    n=len(Va);best=None
    for t in range(n):
        obj=np.zeros(n); obj[t]=-(ud_c[t]-ud_u[t]); A=[];b=[]
        for s in range(n):
            if s==t: continue
            row=np.zeros(n); row[s]=Ac[s]-Va[s]; row[t]-=(Ac[t]-Va[t]); A.append(row); b.append(Va[t]-Va[s])
        A.append(k); b.append(B)
        r=linprog(obj,A_ub=A,b_ub=b,bounds=[(floor,x) for x in cb],method="highs")
        if r.status==0:
            val=ud_u[t]+r.x[t]*(ud_c[t]-ud_u[t])
            if best is None or val>best[0]+1e-9: best=(val,t,r.x)
    return best
def risk_ranked(B):
    c=np.full(6,FL); rem=B-K@c
    for i in np.argsort(-(P*L)):
        add=min(CB[i]-c[i],rem/K[i]); c[i]+=add; rem-=add*K[i]
        if rem<=1e-12: break
    return c
def proportional(B):
    EL=P*L; c=np.full(6,FL); rem=B-K@c; act=np.ones(6,bool)
    for _ in range(20):
        w=np.where(act,EL,0)
        if w.sum()==0 or rem<=1e-9: break
        newc=np.minimum(c+w/w.sum()*rem/K,CB); rem-=K@(newc-c); c=newc; act=c<CB-1e-9
    return c
def uniform(B):
    lo,hi=0,1
    for _ in range(60):
        m=(lo+hi)/2
        if K@np.minimum(np.maximum(m,FL),CB)<=B: lo=m
        else: hi=m
    return np.minimum(np.maximum(lo,FL),CB)
def qre_loss(c,lam,Va=V):
    u=lam*Ua(c,Va); q=np.exp(u-u.max()); q/=q.sum(); return -(q@Ud(c))
def robust(B,lam=2.0,starts=20,seed=1):
    rng=np.random.default_rng(seed); best=None
    x0s=[proportional(B)]+[FL+(CB-FL)*rng.random(6) for _ in range(starts-1)]
    for x0 in x0s:
        x0=FL+(x0-FL)*min(1,(B-K@np.full(6,FL))/max(1e-9,K@(x0-FL)))
        r=minimize(lambda c: qre_loss(c,lam),x0,bounds=[(FL,x) for x in CB],
                   constraints=[{'type':'ineq','fun':lambda c: B-K@c}],method='SLSQP')
        if best is None or r.fun<best.fun: best=r
    return best.x
if __name__=="__main__":
    # two-asset example
    v,t,c=sse(1.0,Va=np.array([6.0,7.0]),Ac=np.array([-1.0,-0.5]),floor=0,cb=np.array([1.,1.]),k=np.array([1.,1.]),
              ud_c=-0.1*np.array([45,18.]),ud_u=-np.array([45,18.]))
    print("2-asset SSE:",np.round(c,4),"target",["PLAT","IDP"][t],"loss",round(-v,3))
    B=9.0
    S=dict(risk_ranked=risk_ranked(B),proportional=proportional(B),uniform=uniform(B),textbook=sse(B)[2],robust=robust(B))
    rng=np.random.default_rng(20261103); draws=[V*rng.lognormal(0,0.35,6) for _ in range(3000)]
    for n,c in S.items():
        t=br(c); mc=np.array([-Ud(c)[br(c,Vt)] for Vt in draws])
        print(f"{n:12s} cov {np.round(c,3)} spend {K@c:.2f} target {ids[t]} loss {-Ud(c)[t]:.2f} "
              f"MCmean {mc.mean():.2f} p95 {np.percentile(mc,95):.1f} QRE2 {qre_loss(c,2):.2f}")
