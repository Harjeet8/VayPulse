import test from 'node:test';
import assert from 'node:assert/strict';
import {validateSpeech, withinBudget} from './policy.mjs';
test('does not change an ESP32 action or its conditions',()=>{
 const text='Check the soil near the roots. Water it if it is dry.';
 assert.deepEqual(validateSpeech({text,language:'en'}),{text,language:'en'});
});
test('rejects unknown languages and oversized requests',()=>{
 assert.throws(()=>validateSpeech({text:'hello',language:'xx'}));
 assert.throws(()=>validateSpeech({text:'x'.repeat(1801),language:'ta'}));
});
test('enforces user and global character caps',()=>{
 assert.equal(withinBudget(9999,99999,1),true);
 assert.equal(withinBudget(10000,1,1),false);
 assert.equal(withinBudget(1,100000,1),false);
});
