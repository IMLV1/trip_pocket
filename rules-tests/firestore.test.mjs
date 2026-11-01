import {readFileSync} from 'node:fs';
import {before,after,beforeEach,test} from 'node:test';
import {initializeTestEnvironment,assertSucceeds,assertFails} from '@firebase/rules-unit-testing';
import {doc,setDoc,getDoc,getDocs,collection,query,where,orderBy,updateDoc,deleteDoc,serverTimestamp,Timestamp,writeBatch} from 'firebase/firestore';
let env;
const tripPath='users/owner/trips/trip1';
const trip=()=>({title:'เชียงใหม่',destination:'เชียงใหม่',startDate:'2026-11-06',endDate:'2026-11-08',budgetSatang:300000,status:'active',createdAt:serverTimestamp(),updatedAt:serverTimestamp()});
const activity=()=>({title:'คาเฟ่',date:'2026-11-07',timeMinutes:540,estimatedCostSatang:20000,latitude:18.78,longitude:98.98,note:'private',createdAt:serverTimestamp(),updatedAt:serverTimestamp()});
const db=(uid='owner')=>uid?env.authenticatedContext(uid).firestore():env.unauthenticatedContext().firestore();
before(async()=>{env=await initializeTestEnvironment({projectId:'demo-trippocket',firestore:{rules:readFileSync('firestore.rules','utf8')}});});
after(async()=>env?.cleanup());
beforeEach(async()=>env.clearFirestore());
test('owner CRUD, active query, child before parent deletion',async()=>{const d=db(),p=doc(d,tripPath),a=doc(d,tripPath+'/activities/a');await assertSucceeds(setDoc(p,trip()));await assertSucceeds(getDocs(query(collection(d,'users/owner/trips'),where('status','==','active'),orderBy('startDate'))));await assertSucceeds(setDoc(a,activity()));await assertSucceeds(updateDoc(a,{estimatedCostSatang:0,updatedAt:serverTimestamp()}));await assertFails(deleteDoc(p));await assertSucceeds(updateDoc(p,{status:'deleting',updatedAt:serverTimestamp()}));await assertFails(setDoc(doc(d,tripPath+'/activities/new'),activity()));await assertFails(updateDoc(p,{status:'active',updatedAt:serverTimestamp()}));await assertSucceeds(deleteDoc(a));await assertSucceeds(deleteDoc(p));});
test('user B and anonymous cannot access any owner operation',async()=>{await setDoc(doc(db(),tripPath),trip());await setDoc(doc(db(),tripPath+'/activities/a'),activity());for(const uid of ['other',null]){const d=db(uid);for(const p of [tripPath,tripPath+'/activities/a']){await assertFails(getDoc(doc(d,p)));await assertFails(updateDoc(doc(d,p),{title:'hack',updatedAt:serverTimestamp()}));await assertFails(deleteDoc(doc(d,p)));}await assertFails(getDocs(collection(d,'users/owner/trips')));await assertFails(setDoc(doc(d,'users/owner/trips/new'),trip()));await assertFails(setDoc(doc(d,tripPath+'/activities/new'),activity()));}});
test('trip field allowlist, money, dates, timestamps',async()=>{const d=db();for(const change of [{title:''},{title:' '.repeat(5)},{title:'ก'.repeat(101)},{budgetSatang:-1},{budgetSatang:1.5},{budgetSatang:1000000001},{endDate:'2026-11-01'},{startDate:'2026-1-01'},{status:'deleting'},{extra:true},{createdAt:Timestamp.fromMillis(1)},{updatedAt:Timestamp.fromMillis(1)}])await assertFails(setDoc(doc(d,tripPath),{...trip(),...change}));const missing=trip();delete missing.title;await assertFails(setDoc(doc(d,tripPath),missing));await setDoc(doc(d,tripPath),trip());await assertFails(updateDoc(doc(d,tripPath),{createdAt:Timestamp.fromMillis(1),updatedAt:serverTimestamp()}));await assertFails(updateDoc(doc(d,tripPath),{status:'deleting',title:'also edit',updatedAt:serverTimestamp()}));});
test('activity range, bounds, schema, parent missing and immutable timestamps',async()=>{const d=db(),a=doc(d,tripPath+'/activities/a');await assertFails(setDoc(a,activity()));await setDoc(doc(d,tripPath),trip());for(const change of [{date:'2026-11-09'},{timeMinutes:1440},{timeMinutes:-1},{estimatedCostSatang:-1},{estimatedCostSatang:0.1},{latitude:91},{latitude:NaN},{longitude:-181},{note:'ก'.repeat(501)},{title:'ก'.repeat(101)},{unknown:true}])await assertFails(setDoc(a,{...activity(),...change}));await assertSucceeds(setDoc(a,{...activity(),title:'ก'.repeat(100)}));await assertFails(updateDoc(a,{createdAt:Timestamp.fromMillis(1),updatedAt:serverTimestamp()}));});
test('getAfter enforces parent range and deleting in same batch',async()=>{const d=db(),p=doc(d,tripPath);await setDoc(p,trip());let b=writeBatch(d);b.update(p,{endDate:'2026-11-06',updatedAt:serverTimestamp()});b.set(doc(d,tripPath+'/activities/a'),activity());await assertFails(b.commit());b=writeBatch(d);b.update(p,{status:'deleting',updatedAt:serverTimestamp()});b.set(doc(d,tripPath+'/activities/a'),activity());await assertFails(b.commit());});
test('100 child cleanup batch fits cached parent rule reads',async()=>{const d=db(),p=doc(d,tripPath);await setDoc(p,trip());let b=writeBatch(d);for(let i=0;i<100;i++)b.set(doc(d,tripPath+'/activities/a'+i),activity());await assertSucceeds(b.commit());await updateDoc(p,{status:'deleting',updatedAt:serverTimestamp()});b=writeBatch(d);for(let i=0;i<100;i++)b.delete(doc(d,tripPath+'/activities/a'+i));await assertSucceeds(b.commit());await assertSucceeds(deleteDoc(p));});


const v2=()=>({...activity(),schemaVersion:2,category:'food',orderIndex:0,costKnown:true,travelMode:'none',travelFromId:'',travelSignature:'',travelCostSatang:0,travelCostKnown:false});
test('V2 compatibility, incoming transport, migration and rank updates',async()=>{
  const d=db(),p=doc(d,tripPath),a=doc(d,tripPath+'/activities/a');await setDoc(p,trip());
  await assertSucceeds(setDoc(a,activity()));const upgrade=v2();delete upgrade.createdAt;await assertSucceeds(updateDoc(a,upgrade));
  await assertSucceeds(updateDoc(a,{orderIndex:1000,updatedAt:serverTimestamp()}));
  await assertSucceeds(setDoc(doc(d,tripPath+'/activities/b'),{...v2(),travelMode:'transit',travelFromId:'a',travelSignature:'user-segment',travelCostKnown:true,travelCostSatang:2000}));
  await assertFails(getDoc(doc(db('other'),tripPath+'/activities/a')));
  await assertFails(updateDoc(doc(db('other'),tripPath+'/activities/a'),{orderIndex:2000,updatedAt:serverTimestamp()}));
});
test('V2 rejects partial groups, types, invalid enums, unknown money and unchecked fields',async()=>{
  const d=db(),a=doc(d,tripPath+'/activities/a');await setDoc(doc(d,tripPath),trip());
  await assertFails(setDoc(a,{...activity(),category:'food'}));
  for(const change of [{schemaVersion:3},{category:'bogus'},{orderIndex:-1},{orderIndex:1.5},{orderIndex:1000000001},{costKnown:false},{costKnown:'yes'},{travelMode:'plane'},{travelCostKnown:'yes'},{travelMode:'none',travelCostKnown:true},{travelMode:'car',travelCostSatang:1},{travelMode:'car',travelCostSatang:-1},{travelMode:'car',travelCostKnown:true,travelCostSatang:1.5},{travelFromId:'a'.repeat(129)},{travelSignature:'x'.repeat(1025)},{extra:'bad'}])await assertFails(setDoc(a,{...v2(),...change}));
  await assertSucceeds(setDoc(a,{...v2(),costKnown:false,estimatedCostSatang:0}));
});
test('V2 reorder batch and resumable child cleanup retain owner restrictions',async()=>{
  const d=db(),p=doc(d,tripPath);await setDoc(p,trip());let batch=writeBatch(d);
  for(let i=0;i<100;i++)batch.set(doc(d,tripPath+'/activities/v'+i),{...v2(),orderIndex:i*1000});await assertSucceeds(batch.commit());
  batch=writeBatch(d);for(let i=0;i<100;i++)batch.update(doc(d,tripPath+'/activities/v'+i),{orderIndex:(99-i)*1000,updatedAt:serverTimestamp()});await assertSucceeds(batch.commit());
  await updateDoc(p,{status:'deleting',updatedAt:serverTimestamp()});await assertFails(updateDoc(doc(d,tripPath+'/activities/v0'),{orderIndex:1,updatedAt:serverTimestamp()}));
  batch=writeBatch(d);for(let i=0;i<100;i++)batch.delete(doc(d,tripPath+'/activities/v'+i));await assertSucceeds(batch.commit());await assertSucceeds(deleteDoc(p));
});

test('trip destination pin accepts legacy/null/pair and rejects malformed or cross-account edits',async()=>{
 const d=db(),p=doc(d,tripPath);
 await assertSucceeds(setDoc(p,trip()));
 await assertSucceeds(updateDoc(p,{destinationLatitude:18.78,destinationLongitude:98.98,updatedAt:serverTimestamp()}));
 const pinned=await getDoc(p);if(pinned.data().destinationLatitude!==18.78)throw Error('pin not persisted');
 for(const change of [
  {destinationLatitude:91,destinationLongitude:98.98},
  {destinationLatitude:18.78,destinationLongitude:-181},
  {destinationLatitude:NaN,destinationLongitude:98.98},
  {destinationLatitude:Infinity,destinationLongitude:98.98},
  {destinationLatitude:'18.78',destinationLongitude:98.98},
  {destinationLatitude:null,destinationLongitude:98.98},
  {destinationLatitude:18.78},
  {destinationLongitude:98.98}
 ])await assertFails(setDoc(p,{...trip(),...change}));
 await assertFails(updateDoc(doc(db('other'),tripPath),{destinationLatitude:13.7,destinationLongitude:100.5,updatedAt:serverTimestamp()}));
 await assertSucceeds(updateDoc(p,{destinationLatitude:null,destinationLongitude:null,updatedAt:serverTimestamp()}));
 await assertSucceeds(updateDoc(p,{status:'deleting',updatedAt:serverTimestamp()}));
 await assertFails(updateDoc(p,{destinationLatitude:18.78,destinationLongitude:98.98,updatedAt:serverTimestamp()}));
 await assertSucceeds(deleteDoc(p));
});

test('strict trip dates reject same-day active writes but allow legacy resumable deletion',async()=>{
 const d=db(),p=doc(d,tripPath);
 await assertFails(setDoc(p,{...trip(),endDate:'2026-11-06'}));
 await assertSucceeds(setDoc(p,trip()));
 await assertFails(updateDoc(p,{endDate:'2026-11-06',updatedAt:serverTimestamp()}));
 // Seed a genuine legacy same-day parent without bypassing rules for client operations.
 await env.withSecurityRulesDisabled(async c=>{await setDoc(doc(c.firestore(),tripPath),{...trip(),endDate:'2026-11-06',createdAt:Timestamp.fromMillis(1),updatedAt:Timestamp.fromMillis(1)});});
 await assertSucceeds(getDoc(p));
 await assertFails(updateDoc(p,{title:'still same-day',updatedAt:serverTimestamp()}));
 await assertFails(updateDoc(p,{status:'deleting',title:'changed',updatedAt:serverTimestamp()}));
 await assertSucceeds(setDoc(doc(d,tripPath+'/activities/a'),{...activity(),date:'2026-11-06'}));
 await assertSucceeds(updateDoc(p,{status:'deleting',updatedAt:serverTimestamp()}));
 await assertSucceeds(deleteDoc(doc(d,tripPath+'/activities/a')));
 await assertSucceeds(deleteDoc(p));
});

test('completed trip flag is owner-only, typed, monotonic and compatible with resumable deletion',async()=>{
 const d=db(),p=doc(d,tripPath);
 await assertFails(setDoc(p,{...trip(),completed:true}));
 await assertFails(setDoc(p,{...trip(),completed:'yes'}));
 await assertSucceeds(setDoc(p,trip()));
 await assertSucceeds(updateDoc(p,{completed:true,updatedAt:serverTimestamp()}));
 await assertFails(updateDoc(doc(db('other'),tripPath),{completed:true,updatedAt:serverTimestamp()}));
 await assertFails(updateDoc(p,{completed:false,updatedAt:serverTimestamp()}));
 await assertSucceeds(updateDoc(p,{title:'แก้ชื่อหลังจบทริป',completed:true,updatedAt:serverTimestamp()}));
 await assertSucceeds(setDoc(doc(d,tripPath+'/activities/a'),activity()));
 await assertSucceeds(updateDoc(p,{status:'deleting',updatedAt:serverTimestamp()}));
 await assertSucceeds(deleteDoc(doc(d,tripPath+'/activities/a')));
 await assertSucceeds(deleteDoc(p));
});
