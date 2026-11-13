import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
const demo = [
  {ssoSubject:'demo-ava',displayName:'Ava Patel',role:'EMPLOYEE'},
  {ssoSubject:'demo-liam',displayName:'Liam Chen',role:'EMPLOYEE'},
  {ssoSubject:'demo-noor',displayName:'Noor Williams',role:'EMPLOYEE'},
  {ssoSubject:'demo-admin',displayName:'Morgan Admin',role:'ADMINISTRATOR'},
];
for (const employee of demo) await prisma.employee.upsert({where:{ssoSubject:employee.ssoSubject},create:employee,update:{displayName:employee.displayName,role:employee.role}});
await prisma.$disconnect();
console.log('Simulation employees seeded.');
