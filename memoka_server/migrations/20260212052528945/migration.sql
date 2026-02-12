BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_core_user" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_core_session" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_core_profile_image" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_core_profile" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_core_jwt_refresh_token" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_secret_challenge" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_rate_limited_request_attempt" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_passkey_challenge" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_passkey_account" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_google_account" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_firebase_account" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_email_account_request" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_email_account_password_reset_request" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_email_account" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_apple_account" CASCADE;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "notes" DROP COLUMN "originalChannelId";
ALTER TABLE "notes" ADD COLUMN "archived" boolean NOT NULL DEFAULT false;
ALTER TABLE "notes" ADD COLUMN "archivedAt" timestamp without time zone;
CREATE INDEX "archived_updated_idx" ON "notes" USING btree ("archived", "updatedAt");

--
-- MIGRATION VERSION FOR memoka
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('memoka', '20260212052528945', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260212052528945', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


--
-- MIGRATION VERSION FOR 'serverpod_auth_idp', 'serverpod_auth_core'
--
DELETE FROM "serverpod_migrations"WHERE "module" IN ('serverpod_auth_idp', 'serverpod_auth_core');

COMMIT;
