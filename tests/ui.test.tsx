import {afterEach,describe,expect,it,vi} from 'vitest';
import {cleanup,render,screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import App from '../src/components/App.js';
const reply=(data:any,status=200)=>({status,ok:status>=200&&status<300,json:async()=>data});
afterEach(()=>{cleanup();vi.unstubAllGlobals()});
describe('accessible employee interface',()=>{
 it('signs into the simulation and exposes labeled employee workflows',async()=>{const fetchMock=vi.fn(async(input:any,init:any={})=>{const url=String(input);if(url.endsWith('/me'))return reply({error:'Sign in'},401);if(url.endsWith('/dev/users'))return reply([{subject:'demo-ava',label:'Ava Patel'}]);if(url.endsWith('/dev/sign-in'))return reply({user:{id:'e1',name:'Ava Patel',role:'EMPLOYEE'}});if(url.includes('/kudos?'))return reply({items:[],nextCursor:null});if(url.endsWith('/notifications'))return reply({items:[],nextCursor:null});return reply([])});vi.stubGlobal('fetch',fetchMock);const user=userEvent.setup();render(<App/>);await screen.findByLabelText('Simulation identity');await user.click(screen.getByRole('button',{name:'Continue'}));expect(await screen.findByRole('heading',{name:'Recognition grows here.'})).toBeInTheDocument();expect(screen.getByLabelText('Who would you like to recognize?')).toBeInTheDocument();expect(screen.getByLabelText('Your message')).toBeInTheDocument();expect(screen.getByLabelText('Search by sender or recipient name')).toBeInTheDocument()});
});