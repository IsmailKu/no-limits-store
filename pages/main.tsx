import React,{Suspense,lazy} from 'react';
import {createRoot} from 'react-dom/client';
import '../app/globals.css';

const base=(import.meta.env.BASE_URL||'/').replace(/\/$/,'');
const route=location.pathname.startsWith(base)?location.pathname.slice(base.length):location.pathname;
const Page=route.startsWith('/admin/login')
  ? lazy(()=>import('../app/admin/login/page'))
  : route.startsWith('/admin')
    ? lazy(()=>import('../app/admin/page'))
    : lazy(()=>import('../app/page'));

createRoot(document.getElementById('root')!).render(
  <React.StrictMode><Suspense fallback={<main style={{minHeight:'100vh',display:'grid',placeItems:'center',background:'#050505',color:'#A5FF4D'}}>NO LIMITS</main>}><Page/></Suspense></React.StrictMode>
);
