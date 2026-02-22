BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "notes" ADD COLUMN "clientMutationId" text;
CREATE UNIQUE INDEX "client_mutation_idx" ON "notes" USING btree ("clientMutationId");

--
-- MIGRATION VERSION FOR memoka
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('memoka', '20260222080306661', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260222080306661', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


COMMIT;
