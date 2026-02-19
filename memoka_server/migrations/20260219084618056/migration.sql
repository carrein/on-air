BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "channels" ALTER COLUMN "emoji" SET DEFAULT 'chatCircle'::text;

--
-- MIGRATION VERSION FOR memoka
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('memoka', '20260219084618056', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260219084618056', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


COMMIT;
