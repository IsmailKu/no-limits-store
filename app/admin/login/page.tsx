'use client';
import { FormEvent,useEffect,useState } from 'react';
import { Loader2,LockKeyhole } from 'lucide-react';
import { assetUrl,isSupabaseConfigured,sitePath,supabase } from '../../../lib/supabase';
import '../admin.css';

export default function AdminLogin(){
 const [loading,setLoading]=useState(false),[error,setError]=useState('');
 useEffect(()=>{supabase?.auth.getSession().then(({data})=>{if(data.session)location.href=sitePath('/admin')})},[]);
 const submit=async(e:FormEvent<HTMLFormElement>)=>{e.preventDefault();if(!supabase)return;setLoading(true);setError('');const fd=new FormData(e.currentTarget);const {error}=await supabase.auth.signInWithPassword({email:String(fd.get('email')),password:String(fd.get('password'))});if(error){setError('Неверный email или пароль.');setLoading(false)}else location.href=sitePath('/admin')};
 return <main className="admin-login"><form onSubmit={submit} className="login-card"><img src={assetUrl('/brand/no-limits-light.png')} alt="NO LIMITS"/><span className="login-icon"><LockKeyhole/></span><h1>ВХОД В АДМИНКУ</h1><p>Только для сотрудников NO LIMITS</p>{!isSupabaseConfigured&&<div className="setup-note"><strong>Supabase ещё не подключён.</strong><br/>Добавьте URL и публичный anon key в переменные окружения сайта.</div>}<input name="email" type="email" autoComplete="email" placeholder="Email" required disabled={!isSupabaseConfigured}/><input name="password" type="password" autoComplete="current-password" placeholder="Пароль" required disabled={!isSupabaseConfigured}/>{error&&<p className="admin-error">{error}</p>}<button disabled={loading||!isSupabaseConfigured}>{loading?<><Loader2 className="spin"/> ВХОДИМ</>:'ВОЙТИ'}</button><a href={sitePath('/')}>← Вернуться в магазин</a></form></main>
}
