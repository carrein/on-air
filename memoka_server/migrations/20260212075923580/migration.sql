BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "channels" ADD COLUMN "sortOrder" bigint NOT NULL DEFAULT 0;

--
-- MIGRATION VERSION FOR memoka
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('memoka', '20260212075923580', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260212075923580', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


COMMIT;
