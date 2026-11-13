import {createHash} from 'node:crypto';
export type Role = 'EMPLOYEE' | 'ADMINISTRATOR';
export type Visibility = 'PUBLISHED' | 'HIDDEN' | 'DELETED';
export function normalizeMessage(input: string): string { return input.trim().replace(/\s+/gu, ' ').toLowerCase(); }
export function validateMessage(input: unknown): string | null {
  if (typeof input !== 'string') return 'Enter a message.';
  const trimmed = input.trim();
  if (!trimmed) return 'Enter a message.';
  if ([...trimmed].length > 500) return 'Message must be 500 characters or fewer.';
  return null;
}
export function isAdministrator(role: string | undefined): boolean { return role === 'ADMINISTRATOR'; }
export function employeeCanSee(status: string): boolean { return status === 'PUBLISHED'; }
export function makeCursor(createdAt: Date, id: string): string { return Buffer.from(JSON.stringify({t:createdAt.toISOString(),i:id})).toString('base64url'); }
export function parseCursor(value?: string): {createdAt:Date;id:string}|null {
  if (!value) return null;
  try { const parsed=JSON.parse(Buffer.from(value,'base64url').toString('utf8')); const createdAt=new Date(parsed.t); if(!Number.isFinite(createdAt.getTime())||typeof parsed.i!=='string') return null; return {createdAt,id:parsed.i}; } catch { return null; }
}
export function createFingerprint(recipientId:string,message:string):string { return createHash('sha256').update(JSON.stringify([recipientId,normalizeMessage(message)])).digest('hex'); }
export function minuteBucket(now:Date):Date { const d=new Date(now);d.setUTCSeconds(0,0);return d; }
