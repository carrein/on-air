BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "channels" ADD COLUMN "version" bigint NOT NULL DEFAULT 0;
ALTER TABLE "channels" ADD COLUMN "deletedAt" timestamp without time zone;
ALTER TABLE "channels" ADD COLUMN "position" double precision NOT NULL DEFAULT 0.0;
ALTER TABLE "channels" ADD COLUMN "clientMutationId" text;
CREATE INDEX "channels_version_idx" ON "channels" USING btree ("version");
CREATE UNIQUE INDEX "client_mutation_ch_idx" ON "channels" USING btree ("clientMutationId");
--
-- ACTION ALTER TABLE
--
ALTER TABLE "notes" ADD COLUMN "version" bigint NOT NULL DEFAULT 0;
ALTER TABLE "notes" ADD COLUMN "deletedAt" timestamp without time zone;
CREATE INDEX "notes_version_idx" ON "notes" USING btree ("version");

--
-- Sync state singleton — global version counter (managed manually, not via ORM)
--
CREATE TABLE "sync_state" (
    "id" bigint PRIMARY KEY DEFAULT 1,
    "globalVersion" bigint NOT NULL DEFAULT 0,
    CONSTRAINT "sync_state_singleton" CHECK ("id" = 1)
);
INSERT INTO "sync_state" ("id", "globalVersion") VALUES (1, 0);

--
-- Data migration: populate position from sortOrder for existing channels
--
UPDATE "channels" SET "position" = "sortOrder"::double precision;

--
-- MIGRATION VERSION FOR memoka
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('memoka', '20260226024731882', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260226024731882', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


COMMIT;
