-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateTable
CREATE TABLE "employees" (
    "id" TEXT NOT NULL,
    "sso_subject" TEXT NOT NULL,
    "display_name" TEXT NOT NULL,
    "role" TEXT NOT NULL DEFAULT 'EMPLOYEE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "employees_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "employees" ADD CONSTRAINT "employee_role_valid" CHECK ("role" IN ('EMPLOYEE','ADMINISTRATOR'));

-- CreateTable
CREATE TABLE "kudos" (
    "id" TEXT NOT NULL,
    "sender_id" TEXT NOT NULL,
    "recipient_id" TEXT NOT NULL,
    "message" VARCHAR(500) NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'PUBLISHED',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "moderated_at" TIMESTAMP(3),

    CONSTRAINT "kudos_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "kudos" ADD CONSTRAINT "kudos_not_self" CHECK ("sender_id" <> "recipient_id");
ALTER TABLE "kudos" ADD CONSTRAINT "kudos_status_valid" CHECK ("status" IN ('PUBLISHED','HIDDEN','DELETED'));
ALTER TABLE "kudos" ADD CONSTRAINT "kudos_message_nonblank" CHECK (length(btrim("message")) > 0);

-- CreateTable
CREATE TABLE "kudos_likes" (
    "kudos_id" TEXT NOT NULL,
    "employee_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "kudos_likes_pkey" PRIMARY KEY ("kudos_id","employee_id")
);

-- CreateTable
CREATE TABLE "reports" (
    "id" TEXT NOT NULL,
    "kudos_id" TEXT NOT NULL,
    "reporter_id" TEXT NOT NULL,
    "reason" VARCHAR(120) NOT NULL,
    "detail" VARCHAR(1000),
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reviewed_by" TEXT,
    "reviewed_at" TIMESTAMP(3),

    CONSTRAINT "reports_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "reports" ADD CONSTRAINT "reports_status_valid" CHECK ("status" IN ('PENDING','UNDER_REVIEW','RESOLVED','DISMISSED'));

-- CreateTable
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "recipient_id" TEXT NOT NULL,
    "kudos_id" TEXT NOT NULL,
    "type" TEXT NOT NULL DEFAULT 'KUDOS_RECEIVED',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "read_at" TIMESTAMP(3),

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "moderation_audit" (
    "id" TEXT NOT NULL,
    "administrator_id" TEXT NOT NULL,
    "kudos_id" TEXT NOT NULL,
    "report_id" TEXT,
    "action" TEXT NOT NULL,
    "reason" VARCHAR(500),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "moderation_audit_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "moderation_audit" ADD CONSTRAINT "moderation_audit_action_valid" CHECK ("action" IN ('HIDE','DELETE','REPORT_STATUS'));

-- CreateTable
CREATE TABLE "idempotency_records" (
    "id" TEXT NOT NULL,
    "employee_id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "fingerprint" TEXT NOT NULL,
    "kudos_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "idempotency_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "creation_rate_windows" (
    "employee_id" TEXT NOT NULL,
    "window_start" TIMESTAMP(3) NOT NULL,
    "count" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "creation_rate_windows_pkey" PRIMARY KEY ("employee_id","window_start")
);

-- CreateIndex
CREATE UNIQUE INDEX "employees_sso_subject_key" ON "employees"("sso_subject");

-- CreateIndex
CREATE INDEX "employees_display_name_idx" ON "employees"("display_name");

-- CreateIndex
CREATE INDEX "kudos_status_created_at_idx" ON "kudos"("status", "created_at" DESC);

-- CreateIndex
CREATE INDEX "kudos_sender_id_status_created_at_idx" ON "kudos"("sender_id", "status", "created_at" DESC);

-- CreateIndex
CREATE INDEX "kudos_recipient_id_status_created_at_idx" ON "kudos"("recipient_id", "status", "created_at" DESC);

-- CreateIndex
CREATE INDEX "reports_status_created_at_idx" ON "reports"("status", "created_at");

-- CreateIndex
CREATE INDEX "reports_reporter_id_created_at_idx" ON "reports"("reporter_id", "created_at");

-- CreateIndex
CREATE INDEX "notifications_recipient_id_created_at_idx" ON "notifications"("recipient_id", "created_at" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "notifications_recipient_id_kudos_id_key" ON "notifications"("recipient_id", "kudos_id");

-- CreateIndex
CREATE INDEX "moderation_audit_kudos_id_created_at_idx" ON "moderation_audit"("kudos_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "moderation_audit_created_at_idx" ON "moderation_audit"("created_at" DESC);

-- CreateIndex
CREATE INDEX "idempotency_records_expires_at_idx" ON "idempotency_records"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "idempotency_records_employee_id_key_key" ON "idempotency_records"("employee_id", "key");

-- AddForeignKey
ALTER TABLE "kudos" ADD CONSTRAINT "kudos_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "employees"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kudos" ADD CONSTRAINT "kudos_recipient_id_fkey" FOREIGN KEY ("recipient_id") REFERENCES "employees"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kudos_likes" ADD CONSTRAINT "kudos_likes_kudos_id_fkey" FOREIGN KEY ("kudos_id") REFERENCES "kudos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kudos_likes" ADD CONSTRAINT "kudos_likes_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "employees"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reports" ADD CONSTRAINT "reports_kudos_id_fkey" FOREIGN KEY ("kudos_id") REFERENCES "kudos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reports" ADD CONSTRAINT "reports_reporter_id_fkey" FOREIGN KEY ("reporter_id") REFERENCES "employees"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reports" ADD CONSTRAINT "reports_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "employees"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_recipient_id_fkey" FOREIGN KEY ("recipient_id") REFERENCES "employees"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_kudos_id_fkey" FOREIGN KEY ("kudos_id") REFERENCES "kudos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "moderation_audit" ADD CONSTRAINT "moderation_audit_administrator_id_fkey" FOREIGN KEY ("administrator_id") REFERENCES "employees"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "moderation_audit" ADD CONSTRAINT "moderation_audit_kudos_id_fkey" FOREIGN KEY ("kudos_id") REFERENCES "kudos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "moderation_audit" ADD CONSTRAINT "moderation_audit_report_id_fkey" FOREIGN KEY ("report_id") REFERENCES "reports"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "idempotency_records" ADD CONSTRAINT "idempotency_records_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "employees"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "idempotency_records" ADD CONSTRAINT "idempotency_records_kudos_id_fkey" FOREIGN KEY ("kudos_id") REFERENCES "kudos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "creation_rate_windows" ADD CONSTRAINT "creation_rate_windows_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "employees"("id") ON DELETE CASCADE ON UPDATE CASCADE;

