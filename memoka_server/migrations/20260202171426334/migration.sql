BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "media_attachments" (
    "id" bigserial PRIMARY KEY,
    "noteId" bigint NOT NULL,
    "channelId" bigint NOT NULL,
    "filePath" text NOT NULL,
    "originalFilename" text NOT NULL,
    "mimeType" text NOT NULL,
    "fileSize" bigint NOT NULL,
    "width" bigint,
    "height" bigint,
    "thumbnailPath" text,
    "compressed" boolean NOT NULL DEFAULT false,
    "animated" boolean NOT NULL DEFAULT false,
    "contentHash" text,
    "uploadedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "note_idx" ON "media_attachments" USING btree ("noteId");
CREATE INDEX "channel_idx" ON "media_attachments" USING btree ("channelId", "uploadedAt");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "notes" ADD COLUMN "attachments" json;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "media_attachments"
    ADD CONSTRAINT "media_attachments_fk_0"
    FOREIGN KEY("noteId")
    REFERENCES "notes"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "media_attachments"
    ADD CONSTRAINT "media_attachments_fk_1"
    FOREIGN KEY("channelId")
    REFERENCES "channels"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR on_air
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('memoka', '20260202171426334', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260202171426334', "timestamp" = now();

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
