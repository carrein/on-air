-- Database Security: Create Dedicated Application User
-- This script creates a non-superuser account with minimal privileges
--
-- Usage:
--   1. Connect to PostgreSQL as superuser (postgres)
--   2. Run this script: psql -U postgres -d memoka -f create_db_user.sql
--   3. Update your passwords.yaml to use the new user
--
-- IMPORTANT: Replace 'STRONG_PASSWORD_HERE' with a secure password!

-- Create dedicated user for the application
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'memoka_app') THEN
    CREATE USER memoka_app WITH PASSWORD 'STRONG_PASSWORD_HERE';
  END IF;
END
$$;

-- Grant connect permission
GRANT CONNECT ON DATABASE memoka TO memoka_app;

-- Grant schema usage
GRANT USAGE ON SCHEMA public TO memoka_app;

-- Grant table permissions (data manipulation only, no DDL)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO memoka_app;

-- Grant sequence permissions (for auto-incrementing IDs)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO memoka_app;

-- Grant permissions on future tables (for migrations)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO memoka_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO memoka_app;

-- Explicitly deny superuser privileges
ALTER USER memoka_app WITH NOSUPERUSER;

-- Deny table/schema creation
ALTER USER memoka_app WITH NOCREATEDB;
ALTER USER memoka_app WITH NOCREATEROLE;

-- Show current privileges
\du memoka_app

-- Verify permissions
SELECT
  grantee,
  privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'memoka_app'
LIMIT 10;

-- After running this script:
-- 1. Update config/development.yaml:
--    database:
--      user: memoka_app
--
-- 2. Update config/passwords.yaml:
--    development:
--      database: 'your_new_password_here'
--
-- 3. Test connection:
--    psql -U memoka_app -d memoka -h localhost -p 8090
