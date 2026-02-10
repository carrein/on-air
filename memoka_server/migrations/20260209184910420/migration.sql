BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "channels" ADD COLUMN "isSystemChannel" boolean NOT NULL DEFAULT false;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "notes" ADD COLUMN "originalChannelId" bigint;

--
-- ACTION CREATE ARCHIVE CRATE SYSTEM CHANNEL
--
INSERT INTO "channels" (id, name, emoji, pinned, "isSystemChannel", "createdAt", "updatedAt")
VALUES (-1, 'Archive Crate', '', false, true, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

--
-- MIGRATION VERSION FOR memoka
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('memoka', '20260209184910420', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260209184910420', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260109031533194', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260109031533194', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20251208110412389-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110412389-v3-0-0', "timestamp" = now();


COMMIT;
