import {describe,it,expect} from 'vitest';
import {createFingerprint,employeeCanSee,isAdministrator,makeCursor,normalizeMessage,parseCursor,validateMessage} from '../src/api/domain.js';
describe('Kudos validation and visibility',()=>{
 it('rejects empty and whitespace-only messages',()=>{expect(validateMessage('')).toBeTruthy();expect(validateMessage('  ')).toBeTruthy()});
 it('accepts 500 characters and rejects 501 Unicode code points',()=>{expect(validateMessage('x'.repeat(500))).toBeNull();expect(validateMessage('x'.repeat(501))).toMatch(/500/);expect(validateMessage('😀'.repeat(500))).toBeNull();expect(validateMessage('😀'.repeat(501))).toMatch(/500/)});
 it('normalizes whitespace and case for duplicate detection',()=>{expect(normalizeMessage('  Great   WORK  ')).toBe('great work');expect(createFingerprint('r1','Great WORK')).toBe(createFingerprint('r1',' great   work '));expect(createFingerprint('r1','great work')).not.toBe(createFingerprint('r2','great work'))});
 it('only exposes published posts to employees',()=>{expect(employeeCanSee('PUBLISHED')).toBe(true);expect(employeeCanSee('HIDDEN')).toBe(false);expect(employeeCanSee('DELETED')).toBe(false)});
 it('recognizes only the administrator role',()=>{expect(isAdministrator('ADMINISTRATOR')).toBe(true);expect(isAdministrator('EMPLOYEE')).toBe(false);expect(isAdministrator(undefined)).toBe(false)});
 it('round trips cursor values and rejects malformed cursors',()=>{const date=new Date('2026-11-13T00:00:00Z');expect(parseCursor(makeCursor(date,'k1'))).toEqual({createdAt:date,id:'k1'});expect(parseCursor('bad')).toBeNull()});
});