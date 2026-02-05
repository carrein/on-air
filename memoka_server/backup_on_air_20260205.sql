--
-- PostgreSQL database dump
--

\restrict tjfH9hNLTMHx8wJeaCAU0jhDG5ARm5iLXM5mXhMSNQMdTHnFtW9Z8GjP7kvAIlt

-- Dumped from database version 16.11 (Debian 16.11-1.pgdg12+1)
-- Dumped by pg_dump version 16.11 (Debian 16.11-1.pgdg12+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: gen_random_uuid_v7(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.gen_random_uuid_v7() RETURNS uuid
    LANGUAGE plpgsql
    AS $$
begin
  -- use random v4 uuid as starting point (which has the same variant we need)
  -- then overlay timestamp
  -- then set version 7 by flipping the 2 and 1 bit in the version 4 string
  return encode(
    set_bit(
      set_bit(
        overlay(uuid_send(gen_random_uuid())
                placing substring(int8send(floor(extract(epoch from clock_timestamp()) * 1000)::bigint) from 3)
                from 1 for 6
        ),
        52, 1
      ),
      53, 1
    ),
    'hex')::uuid;
end
$$;


ALTER FUNCTION public.gen_random_uuid_v7() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: channels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.channels (
    id bigint NOT NULL,
    name text NOT NULL,
    "createdAt" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    emoji text DEFAULT '💬'::text NOT NULL,
    pinned boolean DEFAULT false NOT NULL
);


ALTER TABLE public.channels OWNER TO postgres;

--
-- Name: channels_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.channels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.channels_id_seq OWNER TO postgres;

--
-- Name: channels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.channels_id_seq OWNED BY public.channels.id;


--
-- Name: media_attachments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.media_attachments (
    id bigint NOT NULL,
    "noteId" bigint NOT NULL,
    "channelId" bigint NOT NULL,
    "filePath" text NOT NULL,
    "originalFilename" text NOT NULL,
    "mimeType" text NOT NULL,
    "fileSize" bigint NOT NULL,
    width bigint,
    height bigint,
    "thumbnailPath" text,
    compressed boolean DEFAULT false NOT NULL,
    animated boolean DEFAULT false NOT NULL,
    "contentHash" text,
    "uploadedAt" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    duration double precision
);


ALTER TABLE public.media_attachments OWNER TO postgres;

--
-- Name: media_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.media_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.media_attachments_id_seq OWNER TO postgres;

--
-- Name: media_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.media_attachments_id_seq OWNED BY public.media_attachments.id;


--
-- Name: notes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notes (
    id bigint NOT NULL,
    "channelId" bigint NOT NULL,
    content text NOT NULL,
    "createdAt" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "linkPreview" json,
    attachments json
);


ALTER TABLE public.notes OWNER TO postgres;

--
-- Name: notes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notes_id_seq OWNER TO postgres;

--
-- Name: notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notes_id_seq OWNED BY public.notes.id;


--
-- Name: serverpod_auth_core_jwt_refresh_token; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_auth_core_jwt_refresh_token (
    id uuid DEFAULT public.gen_random_uuid_v7() NOT NULL,
    "authUserId" uuid NOT NULL,
    "scopeNames" json NOT NULL,
    "extraClaims" text,
    method text NOT NULL,
    "fixedSecret" bytea NOT NULL,
    "rotatingSecretHash" text NOT NULL,
    "lastUpdatedAt" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "createdAt" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.serverpod_auth_core_jwt_refresh_token OWNER TO postgres;

--
-- Name: serverpod_auth_core_profile; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_auth_core_profile (
    id uuid DEFAULT public.gen_random_uuid_v7() NOT NULL,
    "authUserId" uuid NOT NULL,
    "userName" text,
    "fullName" text,
    email text,
    "createdAt" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "imageId" uuid
);


ALTER TABLE public.serverpod_auth_core_profile OWNER TO postgres;

--
-- Name: serverpod_auth_core_profile_image; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_auth_core_profile_image (
    id uuid DEFAULT public.gen_random_uuid_v7() NOT NULL,
    "userProfileId" uuid NOT NULL,
    "createdAt" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "storageId" text NOT NULL,
    path text NOT NULL,
    url text NOT NULL
);


ALTER TABLE public.serverpod_auth_core_profile_image OWNER TO postgres;

--
-- Name: serverpod_auth_core_session; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_auth_core_session (
    id uuid DEFAULT public.gen_random_uuid_v7() NOT NULL,
    "authUserId" uuid NOT NULL,
    "scopeNames" json NOT NULL,
    "createdAt" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "lastUsedAt" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "expiresAt" timestamp without time zone,
    "expireAfterUnusedFor" bigint,
    "sessionKeyHash" bytea NOT NULL,
    "sessionKeySalt" bytea NOT NULL,
    method text NOT NULL
);


ALTER TABLE public.serverpod_auth_core_session OWNER TO postgres;

--
-- Name: serverpod_auth_core_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_auth_core_user (
    id uuid DEFAULT public.gen_random_uuid_v7() NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "scopeNames" json NOT NULL,
    blocked boolean NOT NULL
);


ALTER TABLE public.serverpod_auth_core_user OWNER TO postgres;

--
-- Name: serverpod_auth_idp_apple_account; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_auth_idp_apple_account (
    id uuid DEFAULT public.gen_random_uuid_v7() NOT NULL,
    "userIdentifier" text NOT NULL,
    "refreshToken" text NOT NULL,
    "refreshTokenRequestedWithBundleIdentifier" boolean NOT NULL,
    "lastRefreshedAt" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    email text,
    "isEmailVerified" boolean,
    "isPrivateEmail" boolean,
    "firstName" text,
    "lastName" text
);


ALTER TABLE public.serverpod_auth_idp_apple_account OWNER TO postgres;

--
-- Name: serverpod_auth_idp_email_account; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_auth_idp_email_account (
    id uuid DEFAULT public.gen_random_uuid_v7() NOT NULL,
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    email text NOT NULL,
    "passwordHash" text NOT NULL
);


ALTER TABLE public.serverpod_auth_idp_email_account OWNER TO postgres;

--
-- Name: serverpod_auth_idp_email_account_password_reset_request; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_auth_idp_email_account_password_reset_request (
    id uuid DEFAULT public.gen_random_uuid_v7() NOT NULL,
    "emailAccountId" uuid NOT NULL,
    "createdAt" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "challengeId" uuid NOT NULL,
    "setPasswordChallengeId" uuid
);


ALTER TABLE public.serverpod_auth_idp_email_account_password_reset_request OWNER TO postgres;

--
-- Name: serverpod_auth_idp_email_account_request; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_auth_idp_email_account_request (
    id uuid DEFAULT public.gen_random_uuid_v7() NOT NULL,
    "createdAt" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    email text NOT NULL,
    "challengeId" uuid NOT NULL,
    "createAccountChallengeId" uuid
);


ALTER TABLE public.serverpod_auth_idp_email_account_request OWNER TO postgres;

--
-- Name: serverpod_auth_idp_firebase_account; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_auth_idp_firebase_account (
    id uuid DEFAULT public.gen_random_uuid_v7() NOT NULL,
    "authUserId" uuid NOT NULL,
    created timestamp without time zone NOT NULL,
    email text,
    phone text,
    "userIdentifier" text NOT NULL
);


ALTER TABLE public.serverpod_auth_idp_firebase_account OWNER TO postgres;

--
-- Name: serverpod_auth_idp_google_account; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_auth_idp_google_account (
    id uuid DEFAULT public.gen_random_uuid_v7() NOT NULL,
    "authUserId" uuid NOT NULL,
    created timestamp without time zone NOT NULL,
    email text NOT NULL,
    "userIdentifier" text NOT NULL
);


ALTER TABLE public.serverpod_auth_idp_google_account OWNER TO postgres;

--
-- Name: serverpod_auth_idp_passkey_account; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_auth_idp_passkey_account (
    id uuid DEFAULT public.gen_random_uuid_v7() NOT NULL,
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "keyId" bytea NOT NULL,
    "keyIdBase64" text NOT NULL,
    "clientDataJSON" bytea NOT NULL,
    "attestationObject" bytea NOT NULL,
    "originalChallenge" bytea NOT NULL
);


ALTER TABLE public.serverpod_auth_idp_passkey_account OWNER TO postgres;

--
-- Name: serverpod_auth_idp_passkey_challenge; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_auth_idp_passkey_challenge (
    id uuid DEFAULT public.gen_random_uuid_v7() NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    challenge bytea NOT NULL
);


ALTER TABLE public.serverpod_auth_idp_passkey_challenge OWNER TO postgres;

--
-- Name: serverpod_auth_idp_rate_limited_request_attempt; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_auth_idp_rate_limited_request_attempt (
    id uuid DEFAULT public.gen_random_uuid_v7() NOT NULL,
    domain text NOT NULL,
    source text NOT NULL,
    nonce text NOT NULL,
    "ipAddress" text,
    "attemptedAt" timestamp without time zone NOT NULL,
    "extraData" json
);


ALTER TABLE public.serverpod_auth_idp_rate_limited_request_attempt OWNER TO postgres;

--
-- Name: serverpod_auth_idp_secret_challenge; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_auth_idp_secret_challenge (
    id uuid DEFAULT public.gen_random_uuid_v7() NOT NULL,
    "challengeCodeHash" text NOT NULL
);


ALTER TABLE public.serverpod_auth_idp_secret_challenge OWNER TO postgres;

--
-- Name: serverpod_cloud_storage; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_cloud_storage (
    id bigint NOT NULL,
    "storageId" text NOT NULL,
    path text NOT NULL,
    "addedTime" timestamp without time zone NOT NULL,
    expiration timestamp without time zone,
    "byteData" bytea NOT NULL,
    verified boolean NOT NULL
);


ALTER TABLE public.serverpod_cloud_storage OWNER TO postgres;

--
-- Name: serverpod_cloud_storage_direct_upload; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_cloud_storage_direct_upload (
    id bigint NOT NULL,
    "storageId" text NOT NULL,
    path text NOT NULL,
    expiration timestamp without time zone NOT NULL,
    "authKey" text NOT NULL
);


ALTER TABLE public.serverpod_cloud_storage_direct_upload OWNER TO postgres;

--
-- Name: serverpod_cloud_storage_direct_upload_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.serverpod_cloud_storage_direct_upload_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.serverpod_cloud_storage_direct_upload_id_seq OWNER TO postgres;

--
-- Name: serverpod_cloud_storage_direct_upload_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.serverpod_cloud_storage_direct_upload_id_seq OWNED BY public.serverpod_cloud_storage_direct_upload.id;


--
-- Name: serverpod_cloud_storage_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.serverpod_cloud_storage_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.serverpod_cloud_storage_id_seq OWNER TO postgres;

--
-- Name: serverpod_cloud_storage_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.serverpod_cloud_storage_id_seq OWNED BY public.serverpod_cloud_storage.id;


--
-- Name: serverpod_future_call; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_future_call (
    id bigint NOT NULL,
    name text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "serializedObject" text,
    "serverId" text NOT NULL,
    identifier text
);


ALTER TABLE public.serverpod_future_call OWNER TO postgres;

--
-- Name: serverpod_future_call_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.serverpod_future_call_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.serverpod_future_call_id_seq OWNER TO postgres;

--
-- Name: serverpod_future_call_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.serverpod_future_call_id_seq OWNED BY public.serverpod_future_call.id;


--
-- Name: serverpod_health_connection_info; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_health_connection_info (
    id bigint NOT NULL,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    active bigint NOT NULL,
    closing bigint NOT NULL,
    idle bigint NOT NULL,
    granularity bigint NOT NULL
);


ALTER TABLE public.serverpod_health_connection_info OWNER TO postgres;

--
-- Name: serverpod_health_connection_info_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.serverpod_health_connection_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.serverpod_health_connection_info_id_seq OWNER TO postgres;

--
-- Name: serverpod_health_connection_info_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.serverpod_health_connection_info_id_seq OWNED BY public.serverpod_health_connection_info.id;


--
-- Name: serverpod_health_metric; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_health_metric (
    id bigint NOT NULL,
    name text NOT NULL,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "isHealthy" boolean NOT NULL,
    value double precision NOT NULL,
    granularity bigint NOT NULL
);


ALTER TABLE public.serverpod_health_metric OWNER TO postgres;

--
-- Name: serverpod_health_metric_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.serverpod_health_metric_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.serverpod_health_metric_id_seq OWNER TO postgres;

--
-- Name: serverpod_health_metric_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.serverpod_health_metric_id_seq OWNED BY public.serverpod_health_metric.id;


--
-- Name: serverpod_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_log (
    id bigint NOT NULL,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    reference text,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "logLevel" bigint NOT NULL,
    message text NOT NULL,
    error text,
    "stackTrace" text,
    "order" bigint NOT NULL
);


ALTER TABLE public.serverpod_log OWNER TO postgres;

--
-- Name: serverpod_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.serverpod_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.serverpod_log_id_seq OWNER TO postgres;

--
-- Name: serverpod_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.serverpod_log_id_seq OWNED BY public.serverpod_log.id;


--
-- Name: serverpod_message_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_message_log (
    id bigint NOT NULL,
    "sessionLogId" bigint NOT NULL,
    "serverId" text NOT NULL,
    "messageId" bigint NOT NULL,
    endpoint text NOT NULL,
    "messageName" text NOT NULL,
    duration double precision NOT NULL,
    error text,
    "stackTrace" text,
    slow boolean NOT NULL,
    "order" bigint NOT NULL
);


ALTER TABLE public.serverpod_message_log OWNER TO postgres;

--
-- Name: serverpod_message_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.serverpod_message_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.serverpod_message_log_id_seq OWNER TO postgres;

--
-- Name: serverpod_message_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.serverpod_message_log_id_seq OWNED BY public.serverpod_message_log.id;


--
-- Name: serverpod_method; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_method (
    id bigint NOT NULL,
    endpoint text NOT NULL,
    method text NOT NULL
);


ALTER TABLE public.serverpod_method OWNER TO postgres;

--
-- Name: serverpod_method_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.serverpod_method_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.serverpod_method_id_seq OWNER TO postgres;

--
-- Name: serverpod_method_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.serverpod_method_id_seq OWNED BY public.serverpod_method.id;


--
-- Name: serverpod_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_migrations (
    id bigint NOT NULL,
    module text NOT NULL,
    version text NOT NULL,
    "timestamp" timestamp without time zone
);


ALTER TABLE public.serverpod_migrations OWNER TO postgres;

--
-- Name: serverpod_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.serverpod_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.serverpod_migrations_id_seq OWNER TO postgres;

--
-- Name: serverpod_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.serverpod_migrations_id_seq OWNED BY public.serverpod_migrations.id;


--
-- Name: serverpod_query_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_query_log (
    id bigint NOT NULL,
    "serverId" text NOT NULL,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    query text NOT NULL,
    duration double precision NOT NULL,
    "numRows" bigint,
    error text,
    "stackTrace" text,
    slow boolean NOT NULL,
    "order" bigint NOT NULL
);


ALTER TABLE public.serverpod_query_log OWNER TO postgres;

--
-- Name: serverpod_query_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.serverpod_query_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.serverpod_query_log_id_seq OWNER TO postgres;

--
-- Name: serverpod_query_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.serverpod_query_log_id_seq OWNED BY public.serverpod_query_log.id;


--
-- Name: serverpod_readwrite_test; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_readwrite_test (
    id bigint NOT NULL,
    number bigint NOT NULL
);


ALTER TABLE public.serverpod_readwrite_test OWNER TO postgres;

--
-- Name: serverpod_readwrite_test_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.serverpod_readwrite_test_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.serverpod_readwrite_test_id_seq OWNER TO postgres;

--
-- Name: serverpod_readwrite_test_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.serverpod_readwrite_test_id_seq OWNED BY public.serverpod_readwrite_test.id;


--
-- Name: serverpod_runtime_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_runtime_settings (
    id bigint NOT NULL,
    "logSettings" json NOT NULL,
    "logSettingsOverrides" json NOT NULL,
    "logServiceCalls" boolean NOT NULL,
    "logMalformedCalls" boolean NOT NULL
);


ALTER TABLE public.serverpod_runtime_settings OWNER TO postgres;

--
-- Name: serverpod_runtime_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.serverpod_runtime_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.serverpod_runtime_settings_id_seq OWNER TO postgres;

--
-- Name: serverpod_runtime_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.serverpod_runtime_settings_id_seq OWNED BY public.serverpod_runtime_settings.id;


--
-- Name: serverpod_session_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.serverpod_session_log (
    id bigint NOT NULL,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    module text,
    endpoint text,
    method text,
    duration double precision,
    "numQueries" bigint,
    slow boolean,
    error text,
    "stackTrace" text,
    "authenticatedUserId" bigint,
    "userId" text,
    "isOpen" boolean,
    touched timestamp without time zone NOT NULL
);


ALTER TABLE public.serverpod_session_log OWNER TO postgres;

--
-- Name: serverpod_session_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.serverpod_session_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.serverpod_session_log_id_seq OWNER TO postgres;

--
-- Name: serverpod_session_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.serverpod_session_log_id_seq OWNED BY public.serverpod_session_log.id;


--
-- Name: channels id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.channels ALTER COLUMN id SET DEFAULT nextval('public.channels_id_seq'::regclass);


--
-- Name: media_attachments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.media_attachments ALTER COLUMN id SET DEFAULT nextval('public.media_attachments_id_seq'::regclass);


--
-- Name: notes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notes ALTER COLUMN id SET DEFAULT nextval('public.notes_id_seq'::regclass);


--
-- Name: serverpod_cloud_storage id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_cloud_storage ALTER COLUMN id SET DEFAULT nextval('public.serverpod_cloud_storage_id_seq'::regclass);


--
-- Name: serverpod_cloud_storage_direct_upload id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_cloud_storage_direct_upload ALTER COLUMN id SET DEFAULT nextval('public.serverpod_cloud_storage_direct_upload_id_seq'::regclass);


--
-- Name: serverpod_future_call id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_future_call ALTER COLUMN id SET DEFAULT nextval('public.serverpod_future_call_id_seq'::regclass);


--
-- Name: serverpod_health_connection_info id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_health_connection_info ALTER COLUMN id SET DEFAULT nextval('public.serverpod_health_connection_info_id_seq'::regclass);


--
-- Name: serverpod_health_metric id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_health_metric ALTER COLUMN id SET DEFAULT nextval('public.serverpod_health_metric_id_seq'::regclass);


--
-- Name: serverpod_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_log ALTER COLUMN id SET DEFAULT nextval('public.serverpod_log_id_seq'::regclass);


--
-- Name: serverpod_message_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_message_log ALTER COLUMN id SET DEFAULT nextval('public.serverpod_message_log_id_seq'::regclass);


--
-- Name: serverpod_method id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_method ALTER COLUMN id SET DEFAULT nextval('public.serverpod_method_id_seq'::regclass);


--
-- Name: serverpod_migrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_migrations ALTER COLUMN id SET DEFAULT nextval('public.serverpod_migrations_id_seq'::regclass);


--
-- Name: serverpod_query_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_query_log ALTER COLUMN id SET DEFAULT nextval('public.serverpod_query_log_id_seq'::regclass);


--
-- Name: serverpod_readwrite_test id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_readwrite_test ALTER COLUMN id SET DEFAULT nextval('public.serverpod_readwrite_test_id_seq'::regclass);


--
-- Name: serverpod_runtime_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_runtime_settings ALTER COLUMN id SET DEFAULT nextval('public.serverpod_runtime_settings_id_seq'::regclass);


--
-- Name: serverpod_session_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_session_log ALTER COLUMN id SET DEFAULT nextval('public.serverpod_session_log_id_seq'::regclass);


--
-- Data for Name: channels; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.channels (id, name, "createdAt", "updatedAt", emoji, pinned) FROM stdin;
25	MediaList	2026-02-03 16:02:38.798046	2026-02-03 19:36:27.841362	💬	f
26	C	2026-02-03 17:45:43.645843	2026-02-03 19:37:50.621103	💬	f
24	TriageList	2026-02-03 15:20:44.054232	2026-02-03 19:38:16.214898	💬	f
27	MediaDump	2026-02-03 20:00:10.314527	2026-02-03 20:00:16.503198	💬	f
14	General	2026-02-02 11:03:13.584162	2026-02-03 20:01:14.371464	🙂	t
\.


--
-- Data for Name: media_attachments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.media_attachments (id, "noteId", "channelId", "filePath", "originalFilename", "mimeType", "fileSize", width, height, "thumbnailPath", compressed, animated, "contentHash", "uploadedAt", duration) FROM stdin;
17	121	14	channels/14/e5acddb6-25f4-4b13-b633-84488c80e1ef.jpg	sample.jpg	image/jpeg	90367	944	1088	thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	t	f	b2ab32e6	2026-02-03 07:20:05.112914	\N
18	122	14	channels/14/abc20280-16b6-42d3-9327-5568a1acef2a.pdf	CruiseTicket.pdf	application/pdf	225425	\N	\N	\N	f	f	df186dbf	2026-02-03 15:08:10.604979	\N
19	123	14	channels/14/fc0ee416-809e-4db2-b77e-d558946b85c5.zip	chat-bgs-v1.2.zip	application/zip	18686125	\N	\N	\N	f	f	cef3abfb	2026-02-03 15:08:57.588471	\N
20	129	25	channels/25/151e5f11-6d1a-44f7-952e-22d962c1b5df.png	no-dart.png	image/png	1380188	1280	800	thumbnails/151e5f11-6d1a-44f7-952e-22d962c1b5df_thumb.jpg	t	f	4c002b65	2026-02-03 16:05:56.427687	\N
21	130	25	channels/25/791fe96b-b4ab-449c-9cef-d8eae0e0be00.zip	chat-bgs-v1.2.zip	application/zip	18686125	\N	\N	\N	f	f	cef3abfb	2026-02-03 16:06:22.377219	\N
22	131	25	channels/25/0bf8c3ea-ae09-4ad0-86fc-0136fc0d1db5.png	clawd.png	image/png	44283	924	750	thumbnails/0bf8c3ea-ae09-4ad0-86fc-0136fc0d1db5_thumb.jpg	t	f	49a9fa81	2026-02-03 16:06:27.645523	\N
23	132	25	channels/25/7e3605aa-0ce9-404f-978a-051b25fc0c9b.pdf	CruiseTicket.pdf	application/pdf	225425	\N	\N	\N	f	f	df186dbf	2026-02-03 16:06:28.894033	\N
24	133	14	channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	Lamp - 二人のいた風景(Futari no Ita Fukei) Guitar Solo Cover.mp4	video/mp4	15388662	1280	720	thumbnails/fc7df6f1-086e-42ba-9ffd-4d8d8be15930_thumb.jpg	f	f	c3ad2ce9	2026-02-03 16:35:45.836681	94.666667
25	134	14	channels/14/046d65cc-c87a-4ed9-8223-8c5def8fadce.pdf	CV_ADDISON.pdf	application/pdf	74679	\N	\N	\N	f	f	40590a6f	2026-02-03 16:56:08.228745	\N
26	135	14	channels/14/7971e7dc-b2b3-47f7-a5c2-1fa8b37bc074.jpg	IMG_2987.JPG	image/jpeg	410341	1920	1440	thumbnails/7971e7dc-b2b3-47f7-a5c2-1fa8b37bc074_thumb.jpg	t	f	30116b1b	2026-02-03 16:56:20.862229	\N
29	146	25	channels/25/68af219d-e724-47a6-942e-42fe6701afa8.zip	chat-bgs-v1.2.zip	application/zip	18686125	\N	\N	\N	f	f	cef3abfb	2026-02-03 19:36:25.89925	\N
30	147	25	channels/25/034048a0-39f1-4f5a-ad0e-d158a6a0693d.jpg	IMG_2351.JPG	image/jpeg	418511	1920	1440	thumbnails/034048a0-39f1-4f5a-ad0e-d158a6a0693d_thumb.jpg	t	f	d0cdf2bb	2026-02-03 19:36:26.637555	\N
31	148	25	channels/25/b8de9cfd-5e64-4905-9d16-cb8633d6a251.png	no-dart.png	image/png	1380188	1280	800	thumbnails/b8de9cfd-5e64-4905-9d16-cb8633d6a251_thumb.jpg	t	f	4c002b65	2026-02-03 19:36:27.838484	\N
32	150	26	channels/26/e9d6a36f-a9b4-4023-8b67-bb7c0ab3ca32.jpg	sample.jpg	image/jpeg	90367	944	1088	thumbnails/e9d6a36f-a9b4-4023-8b67-bb7c0ab3ca32_thumb.jpg	t	f	b2ab32e6	2026-02-03 19:37:33.232132	\N
33	151	26	channels/26/35f482f6-1143-419e-b5f5-eed6322fa58b.png	Untitled-2025-12-30-2222.png	image/png	56352	937	422	thumbnails/35f482f6-1143-419e-b5f5-eed6322fa58b_thumb.jpg	t	f	cfe4b5fc	2026-02-03 19:37:45.927022	\N
34	154	27	channels/27/976a0077-3551-4d38-9a1e-15eb23c3b998.png	1280px-Dart-logo-icon.svg.png	image/png	83094	1280	1280	thumbnails/976a0077-3551-4d38-9a1e-15eb23c3b998_thumb.jpg	t	f	5a454319	2026-02-03 20:00:16.370502	\N
35	155	27	channels/27/6730dac2-628b-4275-a3f9-1b9a00a9f303.webp	-2147483648_-211976.webp	image/webp	34411	645	720	thumbnails/6730dac2-628b-4275-a3f9-1b9a00a9f303_thumb.jpg	t	f	cfbcf576	2026-02-03 20:00:16.500158	\N
\.


--
-- Data for Name: notes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notes (id, "channelId", content, "createdAt", "updatedAt", "linkPreview", attachments) FROM stdin;
75	14	Buy Milk	2026-02-02 11:03:24.552264	2026-02-02 11:03:24.552265	\N	\N
76	14	This makes the math even more stacked in favor of the plans. In an agentic loop (e.g. Claude Code), the model makes dozens of tool calls per turn. After every tool call, the model is invoked again. Cache read of the entire context. The API charges 10% for every read; subscriptions charge nothing. This adds up fast, as we'll see in a second.	2026-02-02 11:05:02.517753	2026-02-02 11:05:02.517754	\N	\N
77	14	https://finviz.com/	2026-02-02 11:11:58.423734	2026-02-02 11:11:58.873257	{"__className__":"LinkPreview","url":"https://finviz.com/","title":"Finviz - Stock Screener","description":"Stock screener for investors and traders, financial visualizations.","faviconUrl":"https://finviz.com/favicon_2x.png","fetchedAt":"2026-02-02T11:11:58.873248Z"}	\N
153	24	If i type into the textfield and switch channels, the unsent text disappears.	2026-02-03 19:38:16.206731	2026-02-03 19:38:16.206731	\N	\N
154	27		2026-02-03 20:00:16.366946	2026-02-03 20:00:16.366946	\N	\N
155	27		2026-02-03 20:00:16.496829	2026-02-03 20:00:16.496829	\N	\N
156	14	https://pastebin.com  \nhttps://letterboxd.com	2026-02-03 20:01:14.365723	2026-02-03 20:01:15.541781	{"__className__":"LinkPreview","url":"https://pastebin.com","title":"Pastebin.com - #1 paste tool since 2002!","description":"Pastebin.com is the number one paste tool since 2002. Pastebin is a website where you can store text online for a set period of time.","imageUrl":"https://pastebin.com/i/facebook.png","faviconUrl":"https://pastebin.com/favicon.ico","fetchedAt":"2026-02-03T20:01:15.541752Z"}	\N
121	14		2026-02-03 07:20:05.107944	2026-02-03 07:20:05.107944	\N	\N
122	14		2026-02-03 15:08:10.597692	2026-02-03 15:08:10.597692	\N	\N
123	14		2026-02-03 15:08:57.583773	2026-02-03 15:08:57.583773	\N	\N
124	14	s	2026-02-03 15:09:18.43082	2026-02-03 15:09:18.430821	\N	\N
129	25		2026-02-03 16:05:56.423818	2026-02-03 16:05:56.423818	\N	\N
130	25		2026-02-03 16:06:22.372738	2026-02-03 16:06:22.372739	\N	\N
131	25		2026-02-03 16:06:27.641102	2026-02-03 16:06:27.641102	\N	\N
132	25		2026-02-03 16:06:28.889257	2026-02-03 16:06:28.889258	\N	\N
133	14		2026-02-03 16:35:45.830408	2026-02-03 16:35:45.830408	\N	\N
134	14		2026-02-03 16:56:08.223456	2026-02-03 16:56:08.223456	\N	\N
135	14		2026-02-03 16:56:20.858534	2026-02-03 16:56:20.858534	\N	\N
140	24	Let's create a sidebar on the right. This sidebar is visible on web and shows all the media and links in the channel. Section them by means of tabs IMAGES/VIDEOS/DOCUMENTS/LINKS. For images, videos and documents, show them as a grid. For links, show them as a list. On mobile, and small viewport, this sidebar hides and can be opened from a menu in chat.	2026-02-03 17:51:24.761517	2026-02-03 17:51:24.761517	\N	\N
146	25		2026-02-03 19:36:25.89466	2026-02-03 19:36:25.89466	\N	\N
147	25		2026-02-03 19:36:26.634078	2026-02-03 19:36:26.634078	\N	\N
148	25		2026-02-03 19:36:27.835419	2026-02-03 19:36:27.835419	\N	\N
149	24	Not able to right click on the note where there is text.	2026-02-03 19:37:08.367857	2026-02-03 19:37:08.367858	\N	\N
150	26		2026-02-03 19:37:33.228466	2026-02-03 19:37:33.228467	\N	\N
151	26		2026-02-03 19:37:45.923498	2026-02-03 19:37:45.923498	\N	\N
152	26	ad	2026-02-03 19:37:50.612128	2026-02-03 19:37:50.612128	\N	\N
\.


--
-- Data for Name: serverpod_auth_core_jwt_refresh_token; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_auth_core_jwt_refresh_token (id, "authUserId", "scopeNames", "extraClaims", method, "fixedSecret", "rotatingSecretHash", "lastUpdatedAt", "createdAt") FROM stdin;
\.


--
-- Data for Name: serverpod_auth_core_profile; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_auth_core_profile (id, "authUserId", "userName", "fullName", email, "createdAt", "imageId") FROM stdin;
\.


--
-- Data for Name: serverpod_auth_core_profile_image; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_auth_core_profile_image (id, "userProfileId", "createdAt", "storageId", path, url) FROM stdin;
\.


--
-- Data for Name: serverpod_auth_core_session; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_auth_core_session (id, "authUserId", "scopeNames", "createdAt", "lastUsedAt", "expiresAt", "expireAfterUnusedFor", "sessionKeyHash", "sessionKeySalt", method) FROM stdin;
\.


--
-- Data for Name: serverpod_auth_core_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_auth_core_user (id, "createdAt", "scopeNames", blocked) FROM stdin;
\.


--
-- Data for Name: serverpod_auth_idp_apple_account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_auth_idp_apple_account (id, "userIdentifier", "refreshToken", "refreshTokenRequestedWithBundleIdentifier", "lastRefreshedAt", "authUserId", "createdAt", email, "isEmailVerified", "isPrivateEmail", "firstName", "lastName") FROM stdin;
\.


--
-- Data for Name: serverpod_auth_idp_email_account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_auth_idp_email_account (id, "authUserId", "createdAt", email, "passwordHash") FROM stdin;
\.


--
-- Data for Name: serverpod_auth_idp_email_account_password_reset_request; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_auth_idp_email_account_password_reset_request (id, "emailAccountId", "createdAt", "challengeId", "setPasswordChallengeId") FROM stdin;
\.


--
-- Data for Name: serverpod_auth_idp_email_account_request; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_auth_idp_email_account_request (id, "createdAt", email, "challengeId", "createAccountChallengeId") FROM stdin;
\.


--
-- Data for Name: serverpod_auth_idp_firebase_account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_auth_idp_firebase_account (id, "authUserId", created, email, phone, "userIdentifier") FROM stdin;
\.


--
-- Data for Name: serverpod_auth_idp_google_account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_auth_idp_google_account (id, "authUserId", created, email, "userIdentifier") FROM stdin;
\.


--
-- Data for Name: serverpod_auth_idp_passkey_account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_auth_idp_passkey_account (id, "authUserId", "createdAt", "keyId", "keyIdBase64", "clientDataJSON", "attestationObject", "originalChallenge") FROM stdin;
\.


--
-- Data for Name: serverpod_auth_idp_passkey_challenge; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_auth_idp_passkey_challenge (id, "createdAt", challenge) FROM stdin;
\.


--
-- Data for Name: serverpod_auth_idp_rate_limited_request_attempt; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_auth_idp_rate_limited_request_attempt (id, domain, source, nonce, "ipAddress", "attemptedAt", "extraData") FROM stdin;
\.


--
-- Data for Name: serverpod_auth_idp_secret_challenge; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_auth_idp_secret_challenge (id, "challengeCodeHash") FROM stdin;
\.


--
-- Data for Name: serverpod_cloud_storage; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_cloud_storage (id, "storageId", path, "addedTime", expiration, "byteData", verified) FROM stdin;
\.


--
-- Data for Name: serverpod_cloud_storage_direct_upload; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_cloud_storage_direct_upload (id, "storageId", path, expiration, "authKey") FROM stdin;
\.


--
-- Data for Name: serverpod_future_call; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_future_call (id, name, "time", "serializedObject", "serverId", identifier) FROM stdin;
\.


--
-- Data for Name: serverpod_health_connection_info; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_health_connection_info (id, "serverId", "timestamp", active, closing, idle, granularity) FROM stdin;
75	default	2026-02-02 10:02:00	0	0	6	1
76	default	2026-02-02 10:03:00	0	0	6	1
77	default	2026-02-02 10:04:00	0	0	6	1
78	default	2026-02-02 10:07:00	0	0	0	1
79	default	2026-02-02 10:08:00	0	0	6	1
80	default	2026-02-02 10:09:00	0	0	6	1
81	default	2026-02-02 10:10:00	0	0	6	1
82	default	2026-02-02 10:16:00	0	0	1	1
83	default	2026-02-02 10:17:00	0	0	6	1
84	default	2026-02-02 10:18:00	0	0	6	1
85	default	2026-02-02 10:19:00	0	0	6	1
86	default	2026-02-02 10:20:00	0	0	6	1
87	default	2026-02-02 10:21:00	0	0	6	1
88	default	2026-02-02 10:23:00	0	0	6	1
89	default	2026-02-02 11:00:00	1	0	5	1
90	default	2026-02-02 11:01:00	0	0	6	1
91	default	2026-02-02 11:03:00	0	0	6	1
92	default	2026-02-02 11:04:00	0	0	1	1
93	default	2026-02-02 11:06:00	0	0	1	1
94	default	2026-02-02 11:12:00	0	0	1	1
95	default	2026-02-02 11:13:00	0	0	1	1
96	default	2026-02-02 11:14:00	0	0	1	1
98	default	2026-02-02 16:59:00	0	0	2	1
99	default	2026-02-02 17:19:00	0	0	0	1
100	default	2026-02-02 17:34:00	0	0	0	1
101	default	2026-02-02 17:38:00	0	0	2	1
102	default	2026-02-02 17:40:00	0	0	1	1
103	default	2026-02-02 17:43:00	0	0	2	1
104	default	2026-02-02 17:45:00	0	0	2	1
105	default	2026-02-02 17:48:00	0	0	1	1
106	default	2026-02-02 17:49:00	0	0	1	1
107	default	2026-02-02 17:50:00	0	0	1	1
108	default	2026-02-02 17:51:00	0	0	0	1
109	default	2026-02-02 17:52:00	0	0	0	1
110	default	2026-02-02 17:56:00	0	0	0	1
111	default	2026-02-02 17:57:00	0	0	3	1
112	default	2026-02-02 17:58:00	0	0	3	1
113	default	2026-02-02 18:00:00	0	0	3	1
114	default	2026-01-31 17:00:00	0	0	0	60
115	default	2026-02-02 18:01:00	0	0	3	1
116	default	2026-02-02 18:02:00	0	0	3	1
117	default	2026-02-02 18:05:00	0	0	3	1
118	default	2026-02-02 18:06:00	0	0	3	1
119	default	2026-02-02 18:07:00	0	0	3	1
120	default	2026-02-02 18:08:00	0	0	3	1
121	default	2026-02-02 18:09:00	0	0	0	1
122	default	2026-02-02 18:10:00	0	0	5	1
123	default	2026-02-02 18:21:00	0	0	5	1
124	default	2026-02-02 18:24:00	0	0	0	1
125	default	2026-02-02 18:31:00	0	0	5	1
126	default	2026-02-02 18:32:00	0	0	5	1
127	default	2026-02-02 18:34:00	0	0	10	1
128	default	2026-02-02 18:35:00	0	0	5	1
129	default	2026-02-02 18:37:00	0	0	0	1
130	default	2026-02-02 18:38:00	0	0	10	1
131	default	2026-02-02 18:39:00	0	0	9	1
132	default	2026-02-02 18:40:00	0	0	9	1
133	default	2026-02-02 18:46:00	0	0	1	1
134	default	2026-02-02 18:47:00	0	0	3	1
135	default	2026-02-02 18:48:00	0	0	3	1
136	default	2026-02-02 19:06:00	0	0	0	1
137	default	2026-01-31 18:00:00	0	0	3	60
138	default	2026-02-03 06:37:00	0	0	2	1
139	default	2026-02-03 06:38:00	0	0	4	1
140	default	2026-02-03 06:42:00	0	0	0	1
141	default	2026-02-03 06:43:00	0	0	0	1
142	default	2026-02-03 06:44:00	0	0	4	1
143	default	2026-02-03 06:46:00	0	0	6	1
144	default	2026-02-03 06:47:00	0	0	6	1
145	default	2026-02-03 06:49:00	0	0	2	1
146	default	2026-02-03 06:51:00	0	0	4	1
147	default	2026-02-03 06:52:00	0	0	5	1
148	default	2026-02-03 06:53:00	0	0	4	1
149	default	2026-02-03 07:20:00	0	0	4	1
150	default	2026-02-03 07:21:00	0	0	4	1
151	default	2026-02-03 07:34:00	0	0	2	1
152	default	2026-02-03 07:35:00	0	0	2	1
153	default	2026-02-03 07:36:00	0	0	2	1
154	default	2026-02-03 07:37:00	0	0	3	1
155	default	2026-02-03 08:11:00	0	0	0	1
156	default	2026-02-03 09:06:00	0	0	4	1
157	default	2026-02-03 09:07:00	0	0	4	1
158	default	2026-02-03 09:09:00	0	0	2	1
159	default	2026-02-03 15:00:00	0	0	0	1
160	default	2026-02-01 14:00:00	0	0	2	60
161	default	2026-02-03 15:09:00	0	0	4	1
162	default	2026-02-03 15:10:00	0	0	4	1
163	default	2026-02-03 15:11:00	0	0	4	1
164	default	2026-02-03 15:21:00	0	0	3	1
165	default	2026-02-03 15:23:00	0	0	3	1
166	default	2026-02-03 15:24:00	0	0	2	1
167	default	2026-02-03 16:02:00	0	0	2	1
168	default	2026-02-01 15:00:00	0	0	2	60
169	default	2026-02-03 16:03:00	0	0	2	1
170	default	2026-02-03 16:04:00	0	0	2	1
171	default	2026-02-03 16:06:00	0	0	5	1
172	default	2026-02-03 16:07:00	0	0	5	1
173	default	2026-02-03 16:10:00	0	0	2	1
174	default	2026-02-03 16:13:00	0	0	6	1
175	default	2026-02-03 16:19:00	0	0	0	1
176	default	2026-02-03 16:21:00	0	0	0	1
177	default	2026-02-03 16:23:00	0	0	3	1
178	default	2026-02-03 16:25:00	0	0	2	1
179	default	2026-02-03 16:27:00	0	0	0	1
180	default	2026-02-03 16:28:00	0	0	5	1
181	default	2026-02-03 16:29:00	0	0	0	1
182	default	2026-02-03 16:30:00	0	0	4	1
183	default	2026-02-03 16:31:00	0	0	0	1
184	default	2026-02-03 16:34:00	0	0	0	1
185	default	2026-02-03 16:35:00	0	0	5	1
186	default	2026-02-03 16:36:00	0	0	5	1
187	default	2026-02-03 16:37:00	0	0	5	1
188	default	2026-02-03 16:38:00	0	0	1	1
189	default	2026-02-03 16:42:00	0	0	0	1
190	default	2026-02-03 16:57:00	0	0	1	1
191	default	2026-02-03 17:45:00	0	0	0	1
192	default	2026-02-01 16:00:00	0	0	2	60
193	default	2026-02-03 17:46:00	0	0	0	1
194	default	2026-02-03 17:48:00	0	0	0	1
195	default	2026-02-03 17:52:00	0	0	0	1
196	default	2026-02-03 18:53:00	0	0	0	1
197	default	2026-02-01 17:00:00	0	0	2	60
198	default	2026-02-03 19:10:00	0	0	6	1
199	default	2026-02-03 19:35:00	0	0	6	1
200	default	2026-02-03 19:36:00	0	0	6	1
201	default	2026-02-03 19:37:00	0	0	6	1
202	default	2026-02-03 19:38:00	0	0	6	1
203	default	2026-02-03 19:39:00	0	0	1	1
204	default	2026-02-03 19:41:00	0	0	5	1
205	default	2026-02-03 19:42:00	0	0	8	1
206	default	2026-02-03 20:00:00	0	0	6	1
207	default	2026-02-03 20:01:00	0	0	6	1
208	default	2026-02-03 20:02:00	0	0	6	1
209	default	2026-02-03 20:06:00	0	0	5	1
210	default	2026-02-03 20:07:00	0	0	10	1
211	default	2026-02-03 20:11:00	0	0	0	1
212	default	2026-02-03 20:13:00	0	0	0	1
213	default	2026-02-03 20:30:00	0	0	0	1
214	default	2026-02-04 06:07:00	0	0	5	1
215	default	2026-02-02 05:00:00	0	0	3	60
216	default	2026-02-04 06:11:00	0	0	0	1
217	default	2026-02-04 06:43:00	0	0	0	1
218	default	2026-02-04 10:42:00	0	0	0	1
219	default	2026-02-02 06:00:00	0	0	6	60
220	default	2026-02-04 15:29:00	0	0	0	1
221	default	2026-02-02 12:00:00	0	0	0	60
\.


--
-- Data for Name: serverpod_health_metric; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_health_metric (id, name, "serverId", "timestamp", "isHealthy", value, granularity) FROM stdin;
661	serverpod_database	default	2026-02-04 15:29:00	t	0.006996	1
662	serverpod_cpu	default	2026-02-04 15:29:00	t	0.2547851502895355	1
663	serverpod_memory	default	2026-02-04 15:29:00	t	0.9598226547241211	1
664	serverpod_memory	default	2026-02-02 12:00:00	t	0.04062945687252542	60
665	serverpod_cpu	default	2026-02-02 12:00:00	t	0.015620753816936327	60
666	serverpod_database	default	2026-02-02 12:00:00	t	0.00015095652173913044	60
224	serverpod_database	default	2026-02-02 10:02:00	t	0.007052	1
225	serverpod_cpu	default	2026-02-02 10:02:00	t	0.37822264432907104	1
226	serverpod_memory	default	2026-02-02 10:02:00	t	0.9946653246879578	1
227	serverpod_database	default	2026-02-02 10:03:00	t	0.005768	1
228	serverpod_cpu	default	2026-02-02 10:03:00	t	0.289794921875	1
229	serverpod_memory	default	2026-02-02 10:03:00	t	0.9861384034156799	1
230	serverpod_database	default	2026-02-02 10:04:00	t	0.007866	1
231	serverpod_cpu	default	2026-02-02 10:04:00	t	0.362060546875	1
232	serverpod_memory	default	2026-02-02 10:04:00	t	0.9870457053184509	1
233	serverpod_database	default	2026-02-02 10:07:00	t	0.003586	1
234	serverpod_cpu	default	2026-02-02 10:07:00	t	0.3931640684604645	1
235	serverpod_memory	default	2026-02-02 10:07:00	t	0.9793873429298401	1
236	serverpod_database	default	2026-02-02 10:08:00	t	0.004093	1
237	serverpod_cpu	default	2026-02-02 10:08:00	t	0.41889649629592896	1
238	serverpod_memory	default	2026-02-02 10:08:00	t	0.9610509872436523	1
239	serverpod_database	default	2026-02-02 10:09:00	t	0.005955	1
240	serverpod_cpu	default	2026-02-02 10:09:00	t	0.405029296875	1
241	serverpod_memory	default	2026-02-02 10:09:00	t	0.9867597818374634	1
242	serverpod_database	default	2026-02-02 10:10:00	t	0.003578	1
243	serverpod_cpu	default	2026-02-02 10:10:00	t	0.342529296875	1
244	serverpod_memory	default	2026-02-02 10:10:00	t	0.9903129935264587	1
245	serverpod_database	default	2026-02-02 10:16:00	t	0.003703	1
246	serverpod_cpu	default	2026-02-02 10:16:00	t	0.330322265625	1
247	serverpod_memory	default	2026-02-02 10:16:00	t	0.9916802644729614	1
248	serverpod_database	default	2026-02-02 10:17:00	t	0.006441	1
249	serverpod_cpu	default	2026-02-02 10:17:00	t	0.3199218809604645	1
250	serverpod_memory	default	2026-02-02 10:17:00	t	0.9848960638046265	1
251	serverpod_database	default	2026-02-02 10:18:00	t	0.005943	1
252	serverpod_cpu	default	2026-02-02 10:18:00	t	0.3836914002895355	1
253	serverpod_memory	default	2026-02-02 10:18:00	t	0.9913451075553894	1
254	serverpod_database	default	2026-02-02 10:19:00	t	0.006303	1
255	serverpod_cpu	default	2026-02-02 10:19:00	t	0.3260742127895355	1
256	serverpod_memory	default	2026-02-02 10:19:00	t	0.9928990006446838	1
257	serverpod_database	default	2026-02-02 10:20:00	t	0.004716	1
258	serverpod_cpu	default	2026-02-02 10:20:00	t	0.4325195252895355	1
259	serverpod_memory	default	2026-02-02 10:20:00	t	0.975082516670227	1
260	serverpod_database	default	2026-02-02 10:21:00	t	0.003107	1
261	serverpod_cpu	default	2026-02-02 10:21:00	t	1.23193359375	1
262	serverpod_memory	default	2026-02-02 10:21:00	t	0.9882753491401672	1
263	serverpod_database	default	2026-02-02 10:23:00	t	0.006059	1
264	serverpod_cpu	default	2026-02-02 10:23:00	t	0.8271484375	1
265	serverpod_memory	default	2026-02-02 10:23:00	t	0.9823633432388306	1
266	serverpod_database	default	2026-02-02 11:00:00	t	0.003185	1
267	serverpod_cpu	default	2026-02-02 11:00:00	t	0.3384765684604645	1
268	serverpod_memory	default	2026-02-02 11:00:00	t	0.9925006031990051	1
269	serverpod_database	default	2026-02-02 11:01:00	t	0.006205	1
270	serverpod_cpu	default	2026-02-02 11:01:00	t	0.343017578125	1
271	serverpod_memory	default	2026-02-02 11:01:00	t	0.9915714263916016	1
272	serverpod_database	default	2026-02-02 11:03:00	t	0.003045	1
273	serverpod_cpu	default	2026-02-02 11:03:00	t	0.294677734375	1
274	serverpod_memory	default	2026-02-02 11:03:00	t	0.9827696681022644	1
275	serverpod_database	default	2026-02-02 11:04:00	t	0.003977	1
276	serverpod_cpu	default	2026-02-02 11:04:00	t	0.27167969942092896	1
277	serverpod_memory	default	2026-02-02 11:04:00	t	0.9929140210151672	1
278	serverpod_database	default	2026-02-02 11:06:00	t	0.004201	1
279	serverpod_cpu	default	2026-02-02 11:06:00	t	0.3333984315395355	1
280	serverpod_memory	default	2026-02-02 11:06:00	t	0.9937742948532104	1
281	serverpod_database	default	2026-02-02 11:12:00	t	0.002993	1
282	serverpod_cpu	default	2026-02-02 11:12:00	t	0.3731445372104645	1
283	serverpod_memory	default	2026-02-02 11:12:00	t	0.9916711449623108	1
284	serverpod_database	default	2026-02-02 11:13:00	t	0.004533	1
285	serverpod_cpu	default	2026-02-02 11:13:00	t	0.305419921875	1
286	serverpod_memory	default	2026-02-02 11:13:00	t	0.9934694766998291	1
287	serverpod_database	default	2026-02-02 11:14:00	t	0.009732	1
288	serverpod_cpu	default	2026-02-02 11:14:00	t	0.29121094942092896	1
289	serverpod_memory	default	2026-02-02 11:14:00	t	0.9931452870368958	1
293	serverpod_database	default	2026-02-02 16:59:00	t	0.004826	1
294	serverpod_cpu	default	2026-02-02 16:59:00	t	0.35595703125	1
295	serverpod_memory	default	2026-02-02 16:59:00	t	0.9812436699867249	1
296	serverpod_database	default	2026-02-02 17:19:00	t	0.003564	1
297	serverpod_cpu	default	2026-02-02 17:19:00	t	0.18056640028953552	1
298	serverpod_memory	default	2026-02-02 17:19:00	t	0.9663791060447693	1
299	serverpod_database	default	2026-02-02 17:34:00	t	0.003195	1
300	serverpod_cpu	default	2026-02-02 17:34:00	t	0.33198243379592896	1
301	serverpod_memory	default	2026-02-02 17:34:00	t	0.9800680875778198	1
302	serverpod_database	default	2026-02-02 17:38:00	t	0.006081	1
303	serverpod_cpu	default	2026-02-02 17:38:00	t	0.3057617247104645	1
304	serverpod_memory	default	2026-02-02 17:38:00	t	0.993964433670044	1
305	serverpod_database	default	2026-02-02 17:40:00	t	0.006677	1
306	serverpod_cpu	default	2026-02-02 17:40:00	t	0.3658203184604645	1
307	serverpod_memory	default	2026-02-02 17:40:00	t	0.980833888053894	1
308	serverpod_database	default	2026-02-02 17:43:00	t	0.005628	1
309	serverpod_cpu	default	2026-02-02 17:43:00	t	0.5916992425918579	1
310	serverpod_memory	default	2026-02-02 17:43:00	t	0.968644917011261	1
311	serverpod_database	default	2026-02-02 17:45:00	t	0.003179	1
312	serverpod_cpu	default	2026-02-02 17:45:00	t	0.326904296875	1
313	serverpod_memory	default	2026-02-02 17:45:00	t	0.978283166885376	1
314	serverpod_database	default	2026-02-02 17:48:00	t	0.004739	1
315	serverpod_cpu	default	2026-02-02 17:48:00	t	0.29755860567092896	1
316	serverpod_memory	default	2026-02-02 17:48:00	t	0.993742823600769	1
317	serverpod_database	default	2026-02-02 17:49:00	t	0.003577	1
318	serverpod_cpu	default	2026-02-02 17:49:00	t	0.3514160215854645	1
319	serverpod_memory	default	2026-02-02 17:49:00	t	0.9534550309181213	1
320	serverpod_database	default	2026-02-02 17:50:00	t	0.003474	1
321	serverpod_cpu	default	2026-02-02 17:50:00	t	0.298828125	1
322	serverpod_memory	default	2026-02-02 17:50:00	t	0.97929847240448	1
323	serverpod_database	default	2026-02-02 17:51:00	t	0.004747	1
324	serverpod_cpu	default	2026-02-02 17:51:00	t	0.2886718809604645	1
325	serverpod_memory	default	2026-02-02 17:51:00	t	0.8410936594009399	1
326	serverpod_database	default	2026-02-02 17:52:00	t	0.003013	1
327	serverpod_cpu	default	2026-02-02 17:52:00	t	0.3407226502895355	1
328	serverpod_memory	default	2026-02-02 17:52:00	t	0.9747446775436401	1
329	serverpod_database	default	2026-02-02 17:56:00	t	0.003622	1
330	serverpod_cpu	default	2026-02-02 17:56:00	t	0.3619140684604645	1
331	serverpod_memory	default	2026-02-02 17:56:00	t	0.9813697338104248	1
332	serverpod_database	default	2026-02-02 17:57:00	t	0.003358	1
333	serverpod_cpu	default	2026-02-02 17:57:00	t	0.24624022841453552	1
334	serverpod_memory	default	2026-02-02 17:57:00	t	0.9852426052093506	1
335	serverpod_database	default	2026-02-02 17:58:00	t	0.003067	1
336	serverpod_cpu	default	2026-02-02 17:58:00	t	0.253173828125	1
337	serverpod_memory	default	2026-02-02 17:58:00	t	0.9768981337547302	1
339	serverpod_database	default	2026-02-02 18:00:00	t	0.002645	1
340	serverpod_cpu	default	2026-02-02 18:00:00	t	0.3355956971645355	1
341	serverpod_memory	default	2026-02-02 18:00:00	t	0.9821882843971252	1
342	serverpod_memory	default	2026-01-31 17:00:00	t	0.6764437754948934	60
343	serverpod_database	default	2026-01-31 17:00:00	t	0.0025889999999999997	60
344	serverpod_cpu	default	2026-01-31 17:00:00	t	0.3792154888312022	60
345	serverpod_database	default	2026-02-02 18:01:00	t	0.009451	1
346	serverpod_cpu	default	2026-02-02 18:01:00	t	0.57177734375	1
347	serverpod_memory	default	2026-02-02 18:01:00	t	0.9861865639686584	1
348	serverpod_database	default	2026-02-02 18:02:00	t	0.005373	1
349	serverpod_cpu	default	2026-02-02 18:02:00	t	0.31367188692092896	1
350	serverpod_memory	default	2026-02-02 18:02:00	t	0.9859582185745239	1
351	serverpod_database	default	2026-02-02 18:05:00	t	0.002509	1
352	serverpod_cpu	default	2026-02-02 18:05:00	t	0.4136718809604645	1
353	serverpod_memory	default	2026-02-02 18:05:00	t	0.9842608571052551	1
354	serverpod_database	default	2026-02-02 18:06:00	t	0.010374	1
355	serverpod_cpu	default	2026-02-02 18:06:00	t	0.3992675840854645	1
356	serverpod_memory	default	2026-02-02 18:06:00	t	0.9865207672119141	1
357	serverpod_database	default	2026-02-02 18:07:00	t	0.002571	1
358	serverpod_cpu	default	2026-02-02 18:07:00	t	0.37055665254592896	1
359	serverpod_memory	default	2026-02-02 18:07:00	t	0.957486629486084	1
360	serverpod_database	default	2026-02-02 18:08:00	t	0.003072	1
361	serverpod_cpu	default	2026-02-02 18:08:00	t	0.397705078125	1
362	serverpod_memory	default	2026-02-02 18:08:00	t	0.9946863055229187	1
363	serverpod_database	default	2026-02-02 18:09:00	t	0.003104	1
364	serverpod_cpu	default	2026-02-02 18:09:00	t	0.43305665254592896	1
365	serverpod_memory	default	2026-02-02 18:09:00	t	0.9523280262947083	1
366	serverpod_database	default	2026-02-02 18:10:00	t	0.00323	1
367	serverpod_cpu	default	2026-02-02 18:10:00	t	0.39506834745407104	1
368	serverpod_memory	default	2026-02-02 18:10:00	t	0.9844664335250854	1
369	serverpod_database	default	2026-02-02 18:21:00	t	0.003069	1
370	serverpod_cpu	default	2026-02-02 18:21:00	t	0.24282225966453552	1
371	serverpod_memory	default	2026-02-02 18:21:00	t	0.9858051538467407	1
372	serverpod_database	default	2026-02-02 18:24:00	t	0.007836	1
373	serverpod_cpu	default	2026-02-02 18:24:00	t	0.38286131620407104	1
374	serverpod_memory	default	2026-02-02 18:24:00	t	0.8911743760108948	1
375	serverpod_database	default	2026-02-02 18:31:00	t	0.00458	1
376	serverpod_cpu	default	2026-02-02 18:31:00	t	0.34858399629592896	1
377	serverpod_memory	default	2026-02-02 18:31:00	t	0.9882410168647766	1
378	serverpod_database	default	2026-02-02 18:32:00	t	0.003157	1
379	serverpod_cpu	default	2026-02-02 18:32:00	t	0.27338868379592896	1
380	serverpod_memory	default	2026-02-02 18:32:00	t	0.9784079790115356	1
381	serverpod_database	default	2026-02-02 18:34:00	t	0.004823	1
382	serverpod_cpu	default	2026-02-02 18:34:00	t	0.520263671875	1
383	serverpod_memory	default	2026-02-02 18:34:00	t	0.9874564409255981	1
384	serverpod_database	default	2026-02-02 18:35:00	t	0.003481	1
385	serverpod_cpu	default	2026-02-02 18:35:00	t	0.40522462129592896	1
386	serverpod_memory	default	2026-02-02 18:35:00	t	0.9591683745384216	1
387	serverpod_database	default	2026-02-02 18:37:00	t	0.003499	1
388	serverpod_cpu	default	2026-02-02 18:37:00	t	0.3798828125	1
389	serverpod_memory	default	2026-02-02 18:37:00	t	0.982326865196228	1
390	serverpod_database	default	2026-02-02 18:38:00	t	0.004015	1
391	serverpod_cpu	default	2026-02-02 18:38:00	t	0.4729980528354645	1
392	serverpod_memory	default	2026-02-02 18:38:00	t	0.9917191863059998	1
393	serverpod_database	default	2026-02-02 18:39:00	t	0.002752	1
394	serverpod_cpu	default	2026-02-02 18:39:00	t	0.4344726502895355	1
395	serverpod_memory	default	2026-02-02 18:39:00	t	0.9921108484268188	1
396	serverpod_database	default	2026-02-02 18:40:00	t	0.003384	1
397	serverpod_cpu	default	2026-02-02 18:40:00	t	0.31816405057907104	1
398	serverpod_memory	default	2026-02-02 18:40:00	t	0.9806514978408813	1
399	serverpod_database	default	2026-02-02 18:46:00	t	0.007713	1
400	serverpod_cpu	default	2026-02-02 18:46:00	t	0.20429687201976776	1
401	serverpod_memory	default	2026-02-02 18:46:00	t	0.9848812222480774	1
402	serverpod_database	default	2026-02-02 18:47:00	t	0.002887	1
403	serverpod_cpu	default	2026-02-02 18:47:00	t	0.489501953125	1
404	serverpod_memory	default	2026-02-02 18:47:00	t	0.9889476895332336	1
405	serverpod_database	default	2026-02-02 18:48:00	t	0.005051	1
406	serverpod_cpu	default	2026-02-02 18:48:00	t	0.438232421875	1
407	serverpod_memory	default	2026-02-02 18:48:00	t	0.9826778769493103	1
408	serverpod_database	default	2026-02-02 19:06:00	t	0.002641	1
409	serverpod_cpu	default	2026-02-02 19:06:00	t	0.38945311307907104	1
410	serverpod_memory	default	2026-02-02 19:06:00	t	0.8818333148956299	1
411	serverpod_database	default	2026-01-31 18:00:00	t	0.005049	60
412	serverpod_cpu	default	2026-01-31 18:00:00	t	0.4445556700229645	60
413	serverpod_memory	default	2026-01-31 18:00:00	t	0.9119305908679962	60
414	serverpod_database	default	2026-02-03 06:37:00	t	0.002394	1
415	serverpod_cpu	default	2026-02-03 06:37:00	t	0.30180662870407104	1
416	serverpod_memory	default	2026-02-03 06:37:00	t	0.9840062856674194	1
417	serverpod_database	default	2026-02-03 06:38:00	t	0.004497	1
418	serverpod_cpu	default	2026-02-03 06:38:00	t	0.3985839784145355	1
419	serverpod_memory	default	2026-02-03 06:38:00	t	0.9768666625022888	1
420	serverpod_database	default	2026-02-03 06:42:00	t	0.005019	1
421	serverpod_cpu	default	2026-02-03 06:42:00	t	0.36821287870407104	1
422	serverpod_memory	default	2026-02-03 06:42:00	t	0.8483351469039917	1
423	serverpod_database	default	2026-02-03 06:43:00	t	0.003554	1
424	serverpod_cpu	default	2026-02-03 06:43:00	t	0.33002930879592896	1
425	serverpod_memory	default	2026-02-03 06:43:00	t	0.8646459579467773	1
426	serverpod_database	default	2026-02-03 06:44:00	t	0.004542	1
427	serverpod_cpu	default	2026-02-03 06:44:00	t	0.37504881620407104	1
428	serverpod_memory	default	2026-02-03 06:44:00	t	0.9792913794517517	1
429	serverpod_database	default	2026-02-03 06:46:00	t	0.003422	1
430	serverpod_cpu	default	2026-02-03 06:46:00	t	0.5672851800918579	1
431	serverpod_memory	default	2026-02-03 06:46:00	t	0.9751379489898682	1
432	serverpod_database	default	2026-02-03 06:47:00	t	0.005634	1
433	serverpod_cpu	default	2026-02-03 06:47:00	t	0.41020506620407104	1
434	serverpod_memory	default	2026-02-03 06:47:00	t	0.9670239686965942	1
435	serverpod_database	default	2026-02-03 06:49:00	t	0.003668	1
436	serverpod_cpu	default	2026-02-03 06:49:00	t	0.722363293170929	1
437	serverpod_memory	default	2026-02-03 06:49:00	t	0.9841950535774231	1
438	serverpod_database	default	2026-02-03 06:51:00	t	0.003406	1
439	serverpod_cpu	default	2026-02-03 06:51:00	t	0.44121092557907104	1
440	serverpod_memory	default	2026-02-03 06:51:00	t	0.9166154265403748	1
441	serverpod_database	default	2026-02-03 06:52:00	t	0.004841	1
442	serverpod_cpu	default	2026-02-03 06:52:00	t	0.48662108182907104	1
443	serverpod_memory	default	2026-02-03 06:52:00	t	0.9899290800094604	1
444	serverpod_database	default	2026-02-03 06:53:00	t	0.003559	1
445	serverpod_cpu	default	2026-02-03 06:53:00	t	0.35014647245407104	1
446	serverpod_memory	default	2026-02-03 06:53:00	t	0.8931100964546204	1
447	serverpod_database	default	2026-02-03 07:20:00	t	0.004707	1
448	serverpod_cpu	default	2026-02-03 07:20:00	t	0.367919921875	1
449	serverpod_memory	default	2026-02-03 07:20:00	t	0.9934675693511963	1
450	serverpod_database	default	2026-02-03 07:21:00	t	0.003078	1
451	serverpod_cpu	default	2026-02-03 07:21:00	t	0.5276855230331421	1
452	serverpod_memory	default	2026-02-03 07:21:00	t	0.9923292994499207	1
453	serverpod_database	default	2026-02-03 07:34:00	t	0.024745	1
454	serverpod_cpu	default	2026-02-03 07:34:00	t	0.39873045682907104	1
455	serverpod_memory	default	2026-02-03 07:34:00	t	0.9817997217178345	1
456	serverpod_database	default	2026-02-03 07:35:00	t	0.003987	1
457	serverpod_cpu	default	2026-02-03 07:35:00	t	0.351318359375	1
458	serverpod_memory	default	2026-02-03 07:35:00	t	0.9930505156517029	1
459	serverpod_database	default	2026-02-03 07:36:00	t	0.005937	1
460	serverpod_cpu	default	2026-02-03 07:36:00	t	0.34526365995407104	1
461	serverpod_memory	default	2026-02-03 07:36:00	t	0.9729816317558289	1
462	serverpod_database	default	2026-02-03 07:37:00	t	0.004557	1
463	serverpod_cpu	default	2026-02-03 07:37:00	t	0.5208495855331421	1
464	serverpod_memory	default	2026-02-03 07:37:00	t	0.9852144718170166	1
465	serverpod_database	default	2026-02-03 08:11:00	t	0.004705	1
466	serverpod_cpu	default	2026-02-03 08:11:00	t	0.24106445908546448	1
467	serverpod_memory	default	2026-02-03 08:11:00	t	0.9367708563804626	1
468	serverpod_database	default	2026-02-03 09:06:00	t	0.004897	1
469	serverpod_cpu	default	2026-02-03 09:06:00	t	0.36308592557907104	1
470	serverpod_memory	default	2026-02-03 09:06:00	t	0.9956119060516357	1
471	serverpod_database	default	2026-02-03 09:07:00	t	0.005555	1
472	serverpod_cpu	default	2026-02-03 09:07:00	t	0.25908201932907104	1
473	serverpod_memory	default	2026-02-03 09:07:00	t	0.9907156825065613	1
474	serverpod_database	default	2026-02-03 09:09:00	t	0.003445	1
475	serverpod_cpu	default	2026-02-03 09:09:00	t	0.3080078065395355	1
476	serverpod_memory	default	2026-02-03 09:09:00	t	0.9854021072387695	1
477	serverpod_database	default	2026-02-03 15:00:00	t	0.005144	1
478	serverpod_cpu	default	2026-02-03 15:00:00	t	0.517871081829071	1
479	serverpod_memory	default	2026-02-03 15:00:00	t	0.9765751957893372	1
480	serverpod_memory	default	2026-02-01 14:00:00	t	0.9744290510813395	60
481	serverpod_database	default	2026-02-01 14:00:00	t	0.0050873333333333335	60
482	serverpod_cpu	default	2026-02-01 14:00:00	t	0.39506836732228595	60
483	serverpod_database	default	2026-02-03 15:09:00	t	0.006462	1
484	serverpod_cpu	default	2026-02-03 15:09:00	t	0.658154308795929	1
485	serverpod_memory	default	2026-02-03 15:09:00	t	0.9872924089431763	1
486	serverpod_database	default	2026-02-03 15:10:00	t	0.006677	1
487	serverpod_cpu	default	2026-02-03 15:10:00	t	0.44990235567092896	1
488	serverpod_memory	default	2026-02-03 15:10:00	t	0.9797600507736206	1
489	serverpod_database	default	2026-02-03 15:11:00	t	0.00691	1
490	serverpod_cpu	default	2026-02-03 15:11:00	t	0.34370118379592896	1
491	serverpod_memory	default	2026-02-03 15:11:00	t	0.9887468814849854	1
492	serverpod_database	default	2026-02-03 15:21:00	t	0.005775	1
493	serverpod_cpu	default	2026-02-03 15:21:00	t	0.2796874940395355	1
494	serverpod_memory	default	2026-02-03 15:21:00	t	0.9759601950645447	1
495	serverpod_database	default	2026-02-03 15:23:00	t	0.005506	1
496	serverpod_cpu	default	2026-02-03 15:23:00	t	0.218994140625	1
497	serverpod_memory	default	2026-02-03 15:23:00	t	0.9854943752288818	1
498	serverpod_database	default	2026-02-03 15:24:00	t	0.005243	1
499	serverpod_cpu	default	2026-02-03 15:24:00	t	0.19570311903953552	1
500	serverpod_memory	default	2026-02-03 15:24:00	t	0.9697970151901245	1
501	serverpod_database	default	2026-02-03 16:02:00	t	0.005519	1
502	serverpod_cpu	default	2026-02-03 16:02:00	t	0.23100586235523224	1
503	serverpod_memory	default	2026-02-03 16:02:00	t	0.979451596736908	1
504	serverpod_memory	default	2026-02-01 15:00:00	t	0.9424788198973003	60
505	serverpod_cpu	default	2026-02-01 15:00:00	t	0.4227436263310282	60
506	serverpod_database	default	2026-02-01 15:00:00	t	0.004720526315789474	60
507	serverpod_database	default	2026-02-03 16:03:00	t	0.006124	1
508	serverpod_cpu	default	2026-02-03 16:03:00	t	0.4812988340854645	1
509	serverpod_memory	default	2026-02-03 16:03:00	t	0.9392561316490173	1
510	serverpod_database	default	2026-02-03 16:04:00	t	0.00374	1
511	serverpod_cpu	default	2026-02-03 16:04:00	t	0.44091796875	1
512	serverpod_memory	default	2026-02-03 16:04:00	t	0.9439203143119812	1
513	serverpod_database	default	2026-02-03 16:06:00	t	0.004187	1
514	serverpod_cpu	default	2026-02-03 16:06:00	t	0.39306640625	1
515	serverpod_memory	default	2026-02-03 16:06:00	t	0.9642100930213928	1
516	serverpod_database	default	2026-02-03 16:07:00	t	0.004266	1
517	serverpod_cpu	default	2026-02-03 16:07:00	t	0.40239256620407104	1
518	serverpod_memory	default	2026-02-03 16:07:00	t	0.9964368343353271	1
519	serverpod_database	default	2026-02-03 16:10:00	t	0.005281	1
520	serverpod_cpu	default	2026-02-03 16:10:00	t	0.3855957090854645	1
521	serverpod_memory	default	2026-02-03 16:10:00	t	0.9840760231018066	1
522	serverpod_database	default	2026-02-03 16:13:00	t	0.003773	1
523	serverpod_cpu	default	2026-02-03 16:13:00	t	0.4703613221645355	1
524	serverpod_memory	default	2026-02-03 16:13:00	t	0.9952088594436646	1
525	serverpod_database	default	2026-02-03 16:19:00	t	0.004402	1
526	serverpod_cpu	default	2026-02-03 16:19:00	t	0.416748046875	1
527	serverpod_memory	default	2026-02-03 16:19:00	t	0.992981493473053	1
528	serverpod_database	default	2026-02-03 16:21:00	t	0.007935	1
529	serverpod_cpu	default	2026-02-03 16:21:00	t	0.6021484136581421	1
530	serverpod_memory	default	2026-02-03 16:21:00	t	0.9946076273918152	1
531	serverpod_database	default	2026-02-03 16:23:00	t	0.006409	1
532	serverpod_cpu	default	2026-02-03 16:23:00	t	0.31352537870407104	1
533	serverpod_memory	default	2026-02-03 16:23:00	t	0.9882928729057312	1
534	serverpod_database	default	2026-02-03 16:25:00	t	0.005532	1
535	serverpod_cpu	default	2026-02-03 16:25:00	t	0.2901855409145355	1
536	serverpod_memory	default	2026-02-03 16:25:00	t	0.9873937368392944	1
537	serverpod_database	default	2026-02-03 16:27:00	t	0.003444	1
538	serverpod_cpu	default	2026-02-03 16:27:00	t	0.34331053495407104	1
539	serverpod_memory	default	2026-02-03 16:27:00	t	0.6337594985961914	1
540	serverpod_database	default	2026-02-03 16:28:00	t	0.005018	1
541	serverpod_cpu	default	2026-02-03 16:28:00	t	0.521533191204071	1
542	serverpod_memory	default	2026-02-03 16:28:00	t	0.9289246797561646	1
543	serverpod_database	default	2026-02-03 16:29:00	t	0.003605	1
544	serverpod_cpu	default	2026-02-03 16:29:00	t	0.417724609375	1
545	serverpod_memory	default	2026-02-03 16:29:00	t	0.8928014636039734	1
546	serverpod_database	default	2026-02-03 16:30:00	t	0.005834	1
547	serverpod_cpu	default	2026-02-03 16:30:00	t	0.46855467557907104	1
548	serverpod_memory	default	2026-02-03 16:30:00	t	0.934895932674408	1
549	serverpod_database	default	2026-02-03 16:31:00	t	0.005076	1
550	serverpod_cpu	default	2026-02-03 16:31:00	t	0.3955078125	1
551	serverpod_memory	default	2026-02-03 16:31:00	t	0.9494073390960693	1
552	serverpod_database	default	2026-02-03 16:34:00	t	0.00471	1
553	serverpod_cpu	default	2026-02-03 16:34:00	t	0.3077636659145355	1
554	serverpod_memory	default	2026-02-03 16:34:00	t	0.9837629795074463	1
555	serverpod_database	default	2026-02-03 16:35:00	t	0.009611	1
556	serverpod_cpu	default	2026-02-03 16:35:00	t	0.7708495855331421	1
557	serverpod_memory	default	2026-02-03 16:35:00	t	0.9928056001663208	1
558	serverpod_database	default	2026-02-03 16:36:00	t	0.004494	1
559	serverpod_cpu	default	2026-02-03 16:36:00	t	0.49760740995407104	1
560	serverpod_memory	default	2026-02-03 16:36:00	t	0.9921815395355225	1
561	serverpod_database	default	2026-02-03 16:37:00	t	0.004614	1
562	serverpod_cpu	default	2026-02-03 16:37:00	t	0.329833984375	1
563	serverpod_memory	default	2026-02-03 16:37:00	t	0.8340476155281067	1
564	serverpod_database	default	2026-02-03 16:38:00	t	0.00538	1
565	serverpod_cpu	default	2026-02-03 16:38:00	t	0.25712889432907104	1
566	serverpod_memory	default	2026-02-03 16:38:00	t	0.8414672613143921	1
567	serverpod_database	default	2026-02-03 16:42:00	t	0.002933	1
568	serverpod_cpu	default	2026-02-03 16:42:00	t	0.24599608778953552	1
569	serverpod_memory	default	2026-02-03 16:42:00	t	0.9682445526123047	1
570	serverpod_database	default	2026-02-03 16:57:00	t	0.003695	1
571	serverpod_cpu	default	2026-02-03 16:57:00	t	0.3546386659145355	1
572	serverpod_memory	default	2026-02-03 16:57:00	t	0.970508873462677	1
573	serverpod_database	default	2026-02-03 17:45:00	t	0.005684	1
574	serverpod_cpu	default	2026-02-03 17:45:00	t	0.38544923067092896	1
575	serverpod_memory	default	2026-02-03 17:45:00	t	0.9928084015846252	1
576	serverpod_memory	default	2026-02-01 16:00:00	t	0.9439978241920471	60
577	serverpod_cpu	default	2026-02-01 16:00:00	t	0.47268066108226775	60
578	serverpod_database	default	2026-02-01 16:00:00	t	0.0049943999999999995	60
579	serverpod_database	default	2026-02-03 17:46:00	t	0.005622	1
580	serverpod_cpu	default	2026-02-03 17:46:00	t	0.3480468690395355	1
581	serverpod_memory	default	2026-02-03 17:46:00	t	0.9914287328720093	1
582	serverpod_database	default	2026-02-03 17:48:00	t	0.002891	1
583	serverpod_cpu	default	2026-02-03 17:48:00	t	0.3695312440395355	1
584	serverpod_memory	default	2026-02-03 17:48:00	t	0.9932148456573486	1
586	serverpod_database	default	2026-02-03 17:52:00	t	0.00539	1
587	serverpod_cpu	default	2026-02-03 17:52:00	t	0.3546386659145355	1
588	serverpod_memory	default	2026-02-03 17:52:00	t	0.9791786670684814	1
589	serverpod_database	default	2026-02-03 18:53:00	t	0.002342	1
590	serverpod_cpu	default	2026-02-03 18:53:00	t	0.17172852158546448	1
591	serverpod_memory	default	2026-02-03 18:53:00	t	0.9717822074890137	1
592	serverpod_database	default	2026-02-01 17:00:00	t	0.0049334999999999995	60
593	serverpod_memory	default	2026-02-01 17:00:00	t	0.9556669443845749	60
594	serverpod_cpu	default	2026-02-01 17:00:00	t	0.3926391527056694	60
595	serverpod_database	default	2026-02-03 19:10:00	t	0.005761	1
596	serverpod_cpu	default	2026-02-03 19:10:00	t	0.4605956971645355	1
597	serverpod_memory	default	2026-02-03 19:10:00	t	0.994093656539917	1
598	serverpod_database	default	2026-02-03 19:35:00	t	0.004644	1
599	serverpod_cpu	default	2026-02-03 19:35:00	t	0.3152832090854645	1
600	serverpod_memory	default	2026-02-03 19:35:00	t	0.9782842397689819	1
601	serverpod_database	default	2026-02-03 19:36:00	t	0.00496	1
602	serverpod_cpu	default	2026-02-03 19:36:00	t	0.22255858778953552	1
603	serverpod_memory	default	2026-02-03 19:36:00	t	0.9856167435646057	1
604	serverpod_database	default	2026-02-03 19:37:00	t	0.005735	1
605	serverpod_cpu	default	2026-02-03 19:37:00	t	0.31962889432907104	1
606	serverpod_memory	default	2026-02-03 19:37:00	t	0.9774025082588196	1
607	serverpod_database	default	2026-02-03 19:38:00	t	0.004775	1
608	serverpod_cpu	default	2026-02-03 19:38:00	t	0.23779296875	1
609	serverpod_memory	default	2026-02-03 19:38:00	t	0.9945201873779297	1
610	serverpod_database	default	2026-02-03 19:39:00	t	0.004586	1
611	serverpod_cpu	default	2026-02-03 19:39:00	t	0.2685546875	1
612	serverpod_memory	default	2026-02-03 19:39:00	t	0.9857438206672668	1
613	serverpod_database	default	2026-02-03 19:41:00	t	0.004607	1
614	serverpod_cpu	default	2026-02-03 19:41:00	t	0.36762696504592896	1
615	serverpod_memory	default	2026-02-03 19:41:00	t	0.9669520258903503	1
616	serverpod_database	default	2026-02-03 19:42:00	t	0.010452	1
617	serverpod_cpu	default	2026-02-03 19:42:00	t	0.40380859375	1
618	serverpod_memory	default	2026-02-03 19:42:00	t	0.9923751950263977	1
619	serverpod_database	default	2026-02-03 20:00:00	t	0.006512	1
620	serverpod_cpu	default	2026-02-03 20:00:00	t	0.31440430879592896	1
621	serverpod_memory	default	2026-02-03 20:00:00	t	0.9893915057182312	1
622	serverpod_database	default	2026-02-03 20:01:00	t	0.004289	1
623	serverpod_cpu	default	2026-02-03 20:01:00	t	0.2516113221645355	1
624	serverpod_memory	default	2026-02-03 20:01:00	t	0.9840783476829529	1
625	serverpod_database	default	2026-02-03 20:02:00	t	0.003487	1
626	serverpod_cpu	default	2026-02-03 20:02:00	t	0.24189452826976776	1
627	serverpod_memory	default	2026-02-03 20:02:00	t	0.9888272285461426	1
628	serverpod_database	default	2026-02-03 20:06:00	t	0.008156	1
629	serverpod_cpu	default	2026-02-03 20:06:00	t	0.39409178495407104	1
630	serverpod_memory	default	2026-02-03 20:06:00	t	0.9930922985076904	1
631	serverpod_database	default	2026-02-03 20:07:00	t	0.004461	1
632	serverpod_cpu	default	2026-02-03 20:07:00	t	0.36479490995407104	1
633	serverpod_memory	default	2026-02-03 20:07:00	t	0.9860399961471558	1
634	serverpod_database	default	2026-02-03 20:11:00	t	0.005302	1
635	serverpod_cpu	default	2026-02-03 20:11:00	t	0.24936524033546448	1
636	serverpod_memory	default	2026-02-03 20:11:00	t	0.9863187670707703	1
637	serverpod_database	default	2026-02-03 20:13:00	t	0.003798	1
638	serverpod_cpu	default	2026-02-03 20:13:00	t	0.27875977754592896	1
639	serverpod_memory	default	2026-02-03 20:13:00	t	0.9950103759765625	1
640	serverpod_database	default	2026-02-03 20:30:00	t	0.004283	1
641	serverpod_cpu	default	2026-02-03 20:30:00	t	0.32221680879592896	1
642	serverpod_memory	default	2026-02-03 20:30:00	t	0.9395359754562378	1
643	serverpod_database	default	2026-02-04 06:07:00	t	0.004646	1
644	serverpod_cpu	default	2026-02-04 06:07:00	t	0.41450196504592896	1
645	serverpod_memory	default	2026-02-04 06:07:00	t	0.9956539273262024	1
646	serverpod_memory	default	2026-02-02 05:00:00	t	0.9915429216164809	60
647	serverpod_cpu	default	2026-02-02 05:00:00	t	0.37846303903139555	60
648	serverpod_database	default	2026-02-02 05:00:00	t	0.005581999999999999	60
649	serverpod_database	default	2026-02-04 06:11:00	t	0.00459	1
650	serverpod_cpu	default	2026-02-04 06:11:00	t	0.3038085997104645	1
651	serverpod_memory	default	2026-02-04 06:11:00	t	0.964250922203064	1
652	serverpod_database	default	2026-02-04 06:43:00	t	0.003445	1
653	serverpod_cpu	default	2026-02-04 06:43:00	t	0.19887694716453552	1
654	serverpod_memory	default	2026-02-04 06:43:00	t	0.9201604723930359	1
655	serverpod_database	default	2026-02-04 10:42:00	t	0.006165	1
656	serverpod_cpu	default	2026-02-04 10:42:00	t	0.3045410215854645	1
657	serverpod_memory	default	2026-02-04 10:42:00	t	0.9646034240722656	1
658	serverpod_memory	default	2026-02-02 06:00:00	t	0.9826558083295822	60
659	serverpod_cpu	default	2026-02-02 06:00:00	t	0.46136474460363386	60
660	serverpod_database	default	2026-02-02 06:00:00	t	0.0051841	60
\.


--
-- Data for Name: serverpod_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_log (id, "sessionLogId", "messageId", reference, "serverId", "time", "logLevel", message, error, "stackTrace", "order") FROM stdin;
1	1	\N	\N	default	2026-01-31 17:43:28.354947	1	Created default "General" channel	\N	\N	1
2	732	\N	\N	default	2026-02-02 18:37:46.642154	1	Deleted media directory for channel 19	\N	\N	1
3	735	\N	\N	default	2026-02-02 18:37:48.559307	1	Deleted media directory for channel 18	\N	\N	1
4	740	\N	\N	default	2026-02-02 18:37:50.524936	1	Deleted media directory for channel 15	\N	\N	1
5	744	\N	\N	default	2026-02-02 18:37:52.746877	1	Deleted media directory for channel 16	\N	\N	1
6	787	\N	\N	default	2026-02-02 18:45:40.319418	1	Deleted media directory for channel 22	\N	\N	1
7	789	\N	\N	default	2026-02-02 18:45:41.9376	1	Deleted media directory for channel 21	\N	\N	1
8	814	\N	\N	default	2026-02-02 18:47:11.007806	1	Deleted media file: channels/23/9b5fbd1c-4941-4b7d-8d24-fdbb50567490.jpg	\N	\N	1
9	814	\N	\N	default	2026-02-02 18:47:11.008002	1	Deleted thumbnail: thumbnails/9b5fbd1c-4941-4b7d-8d24-fdbb50567490_thumb.jpg	\N	\N	2
10	994	\N	\N	default	2026-02-03 09:05:58.306497	3	Media upload failed: Exception: Failed to decode image	\N	\N	1
11	995	\N	\N	default	2026-02-03 09:06:13.721646	3	Media upload failed: Exception: Failed to decode image	\N	\N	1
12	996	\N	\N	default	2026-02-03 09:06:33.748838	3	Media upload failed: Exception: Failed to decode image	\N	\N	1
13	997	\N	\N	default	2026-02-03 09:08:37.747705	3	Media upload failed: Exception: Failed to decode image	\N	\N	1
14	1021	\N	\N	default	2026-02-03 15:20:21.691287	1	Deleted media directory for channel 23	\N	\N	1
15	1048	\N	\N	default	2026-02-03 16:02:48.328884	3	Media upload failed: DatabaseQueryException: { message: column "duration" of relation "media_attachments" does not exist, code: 42703, position: 132 }	\N	\N	2
16	1049	\N	\N	default	2026-02-03 16:03:15.683665	3	Media upload failed: DatabaseQueryException: { message: column "duration" of relation "media_attachments" does not exist, code: 42703, position: 132 }	\N	\N	2
17	1233	\N	\N	default	2026-02-03 19:35:40.603808	1	Deleted media file: channels/24/c5a3dd38-900a-4446-9d41-3c9d17096d5e.jpg	\N	\N	1
18	1233	\N	\N	default	2026-02-03 19:35:40.605115	1	Deleted thumbnail: thumbnails/c5a3dd38-900a-4446-9d41-3c9d17096d5e_thumb.jpg	\N	\N	2
19	1234	\N	\N	default	2026-02-03 19:35:42.132274	1	Deleted media file: channels/24/7782eecd-d098-466d-9a5d-f314d03efcb5.jpg	\N	\N	1
20	1234	\N	\N	default	2026-02-03 19:35:42.13261	1	Deleted thumbnail: thumbnails/7782eecd-d098-466d-9a5d-f314d03efcb5_thumb.jpg	\N	\N	2
\.


--
-- Data for Name: serverpod_message_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_message_log (id, "sessionLogId", "serverId", "messageId", endpoint, "messageName", duration, error, "stackTrace", slow, "order") FROM stdin;
\.


--
-- Data for Name: serverpod_method; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_method (id, endpoint, method) FROM stdin;
\.


--
-- Data for Name: serverpod_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_migrations (id, module, version, "timestamp") FROM stdin;
1	on_air	20260203160450727	2026-02-03 16:05:09.220116
2	serverpod	20251208110333922-v3-0-0	2026-02-03 16:05:09.220116
3	serverpod_auth_idp	20260109031533194	2026-02-03 16:05:09.220116
4	serverpod_auth_core	20251208110412389-v3-0-0	2026-02-03 16:05:09.220116
\.


--
-- Data for Name: serverpod_query_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_query_log (id, "serverId", "sessionLogId", "messageId", query, duration, "numRows", error, "stackTrace", slow, "order") FROM stdin;
1	default	1048	\N	INSERT INTO "media_attachments" ("noteId", "channelId", "filePath", "originalFilename", "mimeType", "fileSize", "width", "height", "duration", "thumbnailPath", "compressed", "animated", "contentHash", "uploadedAt") VALUES (127, 25, 'channels/25/c7c89943-3106-4e13-aaca-5fd6dd0a50f9.png', 'no-dart.png', 'image/png', 1380188, 1280, 800, NULL, 'thumbnails/c7c89943-3106-4e13-aaca-5fd6dd0a50f9_thumb.jpg', TRUE, FALSE, '4c002b65', '2026-02-03T16:02:48.322119Z') RETURNING *	0.002523	\N	DatabaseQueryException: { message: column "duration" of relation "media_attachments" does not exist, code: 42703, position: 132 }	#0      _PgSessionBase._prepare (package:postgres/src/v3/connection.dart:199:35)\n#1      _PgSessionBase.execute (package:postgres/src/v3/connection.dart:183:30)\n#2      DatabaseConnection._query (package:serverpod/src/database/adapters/postgres/database_connection.dart:527:34)\n#3      DatabaseConnection._mappedResultsQuery (package:serverpod/src/database/adapters/postgres/database_connection.dart:626:24)\n#4      DatabaseConnection.insert (package:serverpod/src/database/adapters/postgres/database_connection.dart:147:19)\n#5      DatabaseConnection.insertRow (package:serverpod/src/database/adapters/postgres/database_connection.dart:162:24)\n#6      Database.insertRow (package:serverpod/src/database/database.dart:239:32)\n#7      MediaAttachmentRepository.insertRow (package:on_air_server/src/generated/media/media_attachment.dart:659:23)\n#8      MediaEndpoint.uploadMediaAndCreateNote.<anonymous closure> (package:on_air_server/src/media/media_endpoint.dart:214:34)\n<asynchronous suspension>\n#9      PgConnectionImplementation.runTx.<anonymous closure> (package:postgres/src/v3/connection.dart:591:24)\n<asynchronous suspension>\n#10     Pool.withResource (package:pool/pool.dart:127:14)\n<asynchronous suspension>\n#11     PoolImplementation.withConnection (package:postgres/src/pool/pool_impl.dart:153:16)\n<asynchronous suspension>\n#12     Database.transaction (package:serverpod/src/database/database.dart:399:12)\n<asynchronous suspension>\n#13     MediaEndpoint.uploadMediaAndCreateNote (package:on_air_server/src/media/media_endpoint.dart:184:20)\n<asynchronous suspension>\n#14     Server._handleEndpointCall (package:serverpod/src/server/server.dart:444:22)\n<asynchronous suspension>\n#15     Server._endpoints (package:serverpod/src/server/server.dart:311:12)\n<asynchronous suspension>\n#16     Server._reportException.<anonymous closure> (package:serverpod/src/server/server.dart:205:16)\n<asynchronous suspension>\n#17     Server._headers.<anonymous closure> (package:serverpod/src/server/server.dart:286:22)\n<asynchronous suspension>\n#18     _RoutingMiddlewareBuilder.call.<anonymous closure> (package:relic/src/middleware/routing_middleware.dart:121:18)\n<asynchronous suspension>\n#19     _RelicServer._wrapHandlerWithMiddleware.<anonymous closure> (package:relic/src/relic_server.dart:151:24)\n<asynchronous suspension>\n#20     _RelicServer._handleRequest (package:relic/src/relic_server.dart:127:22)\n<asynchronous suspension>\n	f	1
2	default	1049	\N	INSERT INTO "media_attachments" ("noteId", "channelId", "filePath", "originalFilename", "mimeType", "fileSize", "width", "height", "duration", "thumbnailPath", "compressed", "animated", "contentHash", "uploadedAt") VALUES (128, 25, 'channels/25/360da280-7f16-4894-b354-1d14fb199f58.png', 'no-dart.png', 'image/png', 1380188, 1280, 800, NULL, 'thumbnails/360da280-7f16-4894-b354-1d14fb199f58_thumb.jpg', FALSE, FALSE, '4c002b65', '2026-02-03T16:03:15.681606Z') RETURNING *	0.000785	\N	DatabaseQueryException: { message: column "duration" of relation "media_attachments" does not exist, code: 42703, position: 132 }	#0      _PgSessionBase._prepare (package:postgres/src/v3/connection.dart:199:35)\n#1      _PgSessionBase.execute (package:postgres/src/v3/connection.dart:183:30)\n#2      DatabaseConnection._query (package:serverpod/src/database/adapters/postgres/database_connection.dart:527:34)\n#3      DatabaseConnection._mappedResultsQuery (package:serverpod/src/database/adapters/postgres/database_connection.dart:626:24)\n#4      DatabaseConnection.insert (package:serverpod/src/database/adapters/postgres/database_connection.dart:147:19)\n#5      DatabaseConnection.insertRow (package:serverpod/src/database/adapters/postgres/database_connection.dart:162:24)\n#6      Database.insertRow (package:serverpod/src/database/database.dart:239:32)\n#7      MediaAttachmentRepository.insertRow (package:on_air_server/src/generated/media/media_attachment.dart:659:23)\n#8      MediaEndpoint.uploadMediaAndCreateNote.<anonymous closure> (package:on_air_server/src/media/media_endpoint.dart:214:34)\n<asynchronous suspension>\n#9      PgConnectionImplementation.runTx.<anonymous closure> (package:postgres/src/v3/connection.dart:591:24)\n<asynchronous suspension>\n#10     Pool.withResource (package:pool/pool.dart:127:14)\n<asynchronous suspension>\n#11     PoolImplementation.withConnection (package:postgres/src/pool/pool_impl.dart:153:16)\n<asynchronous suspension>\n#12     Database.transaction (package:serverpod/src/database/database.dart:399:12)\n<asynchronous suspension>\n#13     MediaEndpoint.uploadMediaAndCreateNote (package:on_air_server/src/media/media_endpoint.dart:184:20)\n<asynchronous suspension>\n#14     Server._handleEndpointCall (package:serverpod/src/server/server.dart:444:22)\n<asynchronous suspension>\n#15     Server._endpoints (package:serverpod/src/server/server.dart:311:12)\n<asynchronous suspension>\n#16     Server._reportException.<anonymous closure> (package:serverpod/src/server/server.dart:205:16)\n<asynchronous suspension>\n#17     Server._headers.<anonymous closure> (package:serverpod/src/server/server.dart:286:22)\n<asynchronous suspension>\n#18     _RoutingMiddlewareBuilder.call.<anonymous closure> (package:relic/src/middleware/routing_middleware.dart:121:18)\n<asynchronous suspension>\n#19     _RelicServer._wrapHandlerWithMiddleware.<anonymous closure> (package:relic/src/relic_server.dart:151:24)\n<asynchronous suspension>\n#20     _RelicServer._handleRequest (package:relic/src/relic_server.dart:127:22)\n<asynchronous suspension>\n	f	1
\.


--
-- Data for Name: serverpod_readwrite_test; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_readwrite_test (id, number) FROM stdin;
\.


--
-- Data for Name: serverpod_runtime_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_runtime_settings (id, "logSettings", "logSettingsOverrides", "logServiceCalls", "logMalformedCalls") FROM stdin;
1	{"__className__":"serverpod.LogSettings","logLevel":0,"logAllSessions":true,"logAllQueries":false,"logSlowSessions":true,"logStreamingSessionsContinuously":true,"logSlowQueries":true,"logFailedSessions":true,"logFailedQueries":true,"slowSessionDuration":1.0,"slowQueryDuration":1.0}	[]	f	f
\.


--
-- Data for Name: serverpod_session_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.serverpod_session_log (id, "serverId", "time", module, endpoint, method, duration, "numQueries", slow, error, "stackTrace", "authenticatedUserId", "userId", "isOpen", touched) FROM stdin;
1	default	2026-01-31 17:43:28.343042	\N	InternalSession	\N	0.014931	2	f	\N	\N	\N	\N	f	2026-01-31 17:43:28.358054
51	default	2026-02-01 14:24:13.217917	\N	chat	createNote	0.004714	1	f	\N	\N	\N	\N	f	2026-02-01 14:24:13.222637
2	default	2026-01-31 17:45:21.359828	\N	InternalSession	\N	0.006017	1	f	\N	\N	\N	\N	f	2026-01-31 17:45:21.365875
102	default	2026-02-01 15:53:52.95248	\N	chat	getChannels	0.002957	1	f	\N	\N	\N	\N	f	2026-02-01 15:53:52.955439
3	default	2026-01-31 17:46:11.925109	\N	chat	getChannels	0.004859	1	f	\N	\N	\N	\N	f	2026-01-31 17:46:11.929974
4	default	2026-01-31 17:46:29.07017	\N	chat	createNote	0.002164	0	f	type 'String' is not a subtype of type 'int'	#0      Endpoints.initializeEndpoints.<anonymous closure> (package:on_air_server/src/generated/endpoints.dart:346:23)\n#1      Server._handleEndpointCall (package:serverpod/src/server/server.dart:444:57)\n<asynchronous suspension>\n#2      Server._endpoints (package:serverpod/src/server/server.dart:311:12)\n<asynchronous suspension>\n#3      Server._reportException.<anonymous closure> (package:serverpod/src/server/server.dart:205:16)\n<asynchronous suspension>\n#4      Server._headers.<anonymous closure> (package:serverpod/src/server/server.dart:286:22)\n<asynchronous suspension>\n#5      _RoutingMiddlewareBuilder.call.<anonymous closure> (package:relic/src/middleware/routing_middleware.dart:121:18)\n<asynchronous suspension>\n#6      _RelicServer._wrapHandlerWithMiddleware.<anonymous closure> (package:relic/src/relic_server.dart:151:24)\n<asynchronous suspension>\n#7      _RelicServer._handleRequest (package:relic/src/relic_server.dart:127:22)\n<asynchronous suspension>\n	\N	\N	f	2026-01-31 17:46:29.07234
5	default	2026-01-31 18:21:55.579869	\N	chat	getChannels	0.003133	1	f	\N	\N	\N	\N	f	2026-01-31 18:21:55.583005
52	default	2026-02-01 15:06:08.536689	\N	InternalSession	\N	0.004884	1	f	\N	\N	\N	\N	f	2026-02-01 15:06:08.541603
6	default	2026-01-31 18:21:55.703304	\N	chat	getNotes	0.004178	1	f	\N	\N	\N	\N	f	2026-01-31 18:21:55.707485
33	default	2026-02-01 14:22:30.297892	\N	chat	chat	\N	\N	\N	\N	\N	\N	\N	f	2026-02-01 14:25:00.03157
38	default	2026-02-01 14:22:34.234782	\N	chat	chat	\N	\N	\N	\N	\N	\N	\N	f	2026-02-01 14:25:00.03157
7	default	2026-01-31 18:21:56.009516	\N	chat	chat	20.127612	0	f	\N	\N	\N	\N	f	2026-01-31 18:22:16.137213
8	default	2026-02-01 14:21:00.084543	\N	InternalSession	\N	0.005809	1	f	\N	\N	\N	\N	f	2026-02-01 14:21:00.090378
9	default	2026-02-01 14:21:32.922904	\N	chat	getChannels	0.011878	1	f	\N	\N	\N	\N	f	2026-02-01 14:21:32.934798
10	default	2026-02-01 14:21:33.045415	\N	chat	getNotes	0.014828	1	f	\N	\N	\N	\N	f	2026-02-01 14:21:33.060253
12	default	2026-02-01 14:21:34.164641	\N	chat	getChannels	0.003954	1	f	\N	\N	\N	\N	f	2026-02-01 14:21:34.168598
13	default	2026-02-01 14:21:34.302412	\N	chat	getNotes	0.011887	1	f	\N	\N	\N	\N	f	2026-02-01 14:21:34.314308
15	default	2026-02-01 14:21:50.135486	\N	chat	createNote	0.00994	1	f	\N	\N	\N	\N	f	2026-02-01 14:21:50.145433
16	default	2026-02-01 14:21:54.467467	\N	chat	deleteNote	0.010124	2	f	\N	\N	\N	\N	f	2026-02-01 14:21:54.477624
17	default	2026-02-01 14:22:02.584995	\N	chat	deleteChannel	0.008973	1	f	Exception: Cannot delete the last remaining channel	#0      ChatEndpoint.deleteChannel (package:on_air_server/src/chat/chat_endpoint.dart:76:7)\n<asynchronous suspension>\n#1      Server._handleEndpointCall (package:serverpod/src/server/server.dart:444:22)\n<asynchronous suspension>\n#2      Server._endpoints (package:serverpod/src/server/server.dart:311:12)\n<asynchronous suspension>\n#3      Server._reportException.<anonymous closure> (package:serverpod/src/server/server.dart:205:16)\n<asynchronous suspension>\n#4      Server._headers.<anonymous closure> (package:serverpod/src/server/server.dart:286:22)\n<asynchronous suspension>\n#5      _RoutingMiddlewareBuilder.call.<anonymous closure> (package:relic/src/middleware/routing_middleware.dart:121:18)\n<asynchronous suspension>\n#6      _RelicServer._wrapHandlerWithMiddleware.<anonymous closure> (package:relic/src/relic_server.dart:151:24)\n<asynchronous suspension>\n#7      _RelicServer._handleRequest (package:relic/src/relic_server.dart:127:22)\n<asynchronous suspension>\n	\N	\N	f	2026-02-01 14:22:02.593976
18	default	2026-02-01 14:22:07.991911	\N	chat	createChannel	0.006677	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:07.998596
19	default	2026-02-01 14:22:08.010309	\N	chat	getChannels	0.003546	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:08.013861
20	default	2026-02-01 14:22:08.015495	\N	chat	getChannels	0.005448	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:08.020953
21	default	2026-02-01 14:22:11.542612	\N	chat	getChannels	0.006904	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:11.549524
22	default	2026-02-01 14:22:11.58065	\N	chat	getChannels	0.006317	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:11.586972
23	default	2026-02-01 14:22:11.626292	\N	chat	getNotes	0.003297	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:11.629591
25	default	2026-02-01 14:22:11.683309	\N	chat	getNotes	0.044325	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:11.727637
27	default	2026-02-01 14:22:12.95426	\N	chat	getNotes	0.003918	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:12.958181
11	default	2026-02-01 14:21:33.234125	\N	chat	chat	41.950415	0	f	\N	\N	\N	\N	f	2026-02-01 14:22:15.184616
14	default	2026-02-01 14:21:34.685582	\N	chat	chat	41.385484	0	f	\N	\N	\N	\N	f	2026-02-01 14:22:16.071074
28	default	2026-02-01 14:22:20.602449	\N	chat	createNote	0.004522	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:20.606976
29	default	2026-02-01 14:22:26.460267	\N	chat	getNotes	0.003052	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:26.463322
30	default	2026-02-01 14:22:27.16532	\N	chat	getNotes	0.0034	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:27.168728
31	default	2026-02-01 14:22:30.178298	\N	chat	getChannels	0.002598	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:30.180899
32	default	2026-02-01 14:22:30.251042	\N	chat	getNotes	0.003717	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:30.254763
34	default	2026-02-01 14:22:31.878328	\N	chat	getNotes	0.003085	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:31.881415
35	default	2026-02-01 14:22:32.369612	\N	chat	getNotes	0.003338	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:32.372954
36	default	2026-02-01 14:22:34.125882	\N	chat	getChannels	0.004478	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:34.130363
37	default	2026-02-01 14:22:34.195694	\N	chat	getNotes	0.002832	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:34.198528
39	default	2026-02-01 14:22:35.120793	\N	chat	getNotes	0.003036	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:35.123832
26	default	2026-02-01 14:22:11.780959	\N	chat	chat	23.72585	0	f	\N	\N	\N	\N	f	2026-02-01 14:22:35.506818
40	default	2026-02-01 14:22:35.815654	\N	chat	getNotes	0.002305	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:35.817962
41	default	2026-02-01 14:22:37.995213	\N	chat	getNotes	0.003392	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:37.998608
42	default	2026-02-01 14:22:39.070755	\N	chat	getNotes	0.002868	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:39.073627
24	default	2026-02-01 14:22:11.67345	\N	chat	chat	27.58933	0	f	\N	\N	\N	\N	f	2026-02-01 14:22:39.262788
43	default	2026-02-01 14:22:40.075935	\N	chat	deleteNote	0.006223	2	f	\N	\N	\N	\N	f	2026-02-01 14:22:40.082165
44	default	2026-02-01 14:22:43.062005	\N	chat	deleteChannel	0.007613	2	f	\N	\N	\N	\N	f	2026-02-01 14:22:43.069624
45	default	2026-02-01 14:22:43.081842	\N	chat	getChannels	0.00267	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:43.084514
46	default	2026-02-01 14:22:43.087061	\N	chat	getChannels	0.005934	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:43.092998
47	default	2026-02-01 14:22:57.007358	\N	chat	createChannel	0.005064	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:57.012429
48	default	2026-02-01 14:22:57.02277	\N	chat	getChannels	0.003004	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:57.025777
49	default	2026-02-01 14:22:57.029623	\N	chat	getChannels	0.003529	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:57.033155
50	default	2026-02-01 14:22:59.648779	\N	chat	getNotes	0.00258	1	f	\N	\N	\N	\N	f	2026-02-01 14:22:59.651361
53	default	2026-02-01 15:09:11.159257	\N	InternalSession	\N	0.00485	1	f	\N	\N	\N	\N	f	2026-02-01 15:09:11.164137
96	default	2026-02-01 15:49:30.628228	\N	chat	chat	179.144248	0	f	\N	\N	\N	\N	f	2026-02-01 15:52:29.772487
54	default	2026-02-01 15:13:16.70665	\N	InternalSession	\N	0.004962	1	f	\N	\N	\N	\N	f	2026-02-01 15:13:16.711637
55	default	2026-02-01 15:13:21.323432	\N	chat	getChannels	0.007149	1	f	\N	\N	\N	\N	f	2026-02-01 15:13:21.330585
103	default	2026-02-01 15:53:53.122198	\N	chat	getNotes	0.002594	1	f	\N	\N	\N	\N	f	2026-02-01 15:53:53.124795
56	default	2026-02-01 15:13:21.395177	\N	chat	getNotes	0.006076	1	f	\N	\N	\N	\N	f	2026-02-01 15:13:21.401259
169	default	2026-02-01 16:50:20.534029	\N	chat	getNotes	0.007282	1	f	\N	\N	\N	\N	f	2026-02-01 16:50:20.541316
58	default	2026-02-01 15:13:23.921057	\N	chat	getChannels	0.00432	1	f	\N	\N	\N	\N	f	2026-02-01 15:13:23.925381
59	default	2026-02-01 15:13:24.019335	\N	chat	getNotes	0.004391	1	f	\N	\N	\N	\N	f	2026-02-01 15:13:24.02373
105	default	2026-02-01 15:54:10.324423	\N	chat	getNotes	0.003039	1	f	\N	\N	\N	\N	f	2026-02-01 15:54:10.327465
61	default	2026-02-01 15:13:33.786148	\N	chat	getNotes	0.004113	1	f	\N	\N	\N	\N	f	2026-02-01 15:13:33.790265
106	default	2026-02-01 15:54:11.231791	\N	chat	getNotes	0.003584	1	f	\N	\N	\N	\N	f	2026-02-01 15:54:11.235378
62	default	2026-02-01 15:13:34.377758	\N	chat	getNotes	0.003913	1	f	\N	\N	\N	\N	f	2026-02-01 15:13:34.381676
63	default	2026-02-01 15:13:46.041349	\N	chat	updateChannel	0.010392	2	f	\N	\N	\N	\N	f	2026-02-01 15:13:46.051745
107	default	2026-02-01 15:54:11.724691	\N	chat	getNotes	0.003176	1	f	\N	\N	\N	\N	f	2026-02-01 15:54:11.72787
64	default	2026-02-01 15:13:46.076869	\N	chat	getChannels	0.002761	1	f	\N	\N	\N	\N	f	2026-02-01 15:13:46.079633
65	default	2026-02-01 15:13:52.080648	\N	chat	createChannel	0.006109	1	f	\N	\N	\N	\N	f	2026-02-01 15:13:52.086761
108	default	2026-02-01 15:54:12.343363	\N	chat	getNotes	0.003399	1	f	\N	\N	\N	\N	f	2026-02-01 15:54:12.346767
66	default	2026-02-01 15:13:52.103031	\N	chat	getChannels	0.002906	1	f	\N	\N	\N	\N	f	2026-02-01 15:13:52.105941
104	default	2026-02-01 15:53:53.179337	\N	chat	chat	46.381347	0	f	\N	\N	\N	\N	f	2026-02-01 15:54:39.560695
67	default	2026-02-01 15:13:54.723879	\N	chat	getNotes	0.003883	1	f	\N	\N	\N	\N	f	2026-02-01 15:13:54.727765
109	default	2026-02-01 15:55:08.465311	\N	chat	getChannels	0.002815	1	f	\N	\N	\N	\N	f	2026-02-01 15:55:08.46813
68	default	2026-02-01 15:14:21.367412	\N	chat	createChannel	0.00551	1	f	\N	\N	\N	\N	f	2026-02-01 15:14:21.372928
110	default	2026-02-01 15:55:08.556404	\N	chat	getNotes	0.035827	1	f	\N	\N	\N	\N	f	2026-02-01 15:55:08.592239
69	default	2026-02-01 15:14:21.389459	\N	chat	getChannels	0.005273	1	f	\N	\N	\N	\N	f	2026-02-01 15:14:21.394737
112	default	2026-02-01 15:55:15.512429	\N	chat	getNotes	0.003958	1	f	\N	\N	\N	\N	f	2026-02-01 15:55:15.516416
70	default	2026-02-01 15:27:59.366767	\N	chat	getNotes	0.004395	1	f	\N	\N	\N	\N	f	2026-02-01 15:27:59.371165
113	default	2026-02-01 15:55:26.153689	\N	chat	getChannels	0.006002	1	f	\N	\N	\N	\N	f	2026-02-01 15:55:26.159698
71	default	2026-02-01 15:33:49.670644	\N	chat	getChannels	0.00509	1	f	\N	\N	\N	\N	f	2026-02-01 15:33:49.675742
114	default	2026-02-01 15:55:26.226706	\N	chat	getNotes	0.002834	1	f	\N	\N	\N	\N	f	2026-02-01 15:55:26.229542
72	default	2026-02-01 15:35:20.762167	\N	chat	getChannels	0.003509	1	f	\N	\N	\N	\N	f	2026-02-01 15:35:20.765679
116	default	2026-02-01 15:55:31.143154	\N	chat	getNotes	0.005494	1	f	\N	\N	\N	\N	f	2026-02-01 15:55:31.148653
73	default	2026-02-01 15:35:20.841705	\N	chat	getNotes	0.004096	1	f	\N	\N	\N	\N	f	2026-02-01 15:35:20.845803
57	default	2026-02-01 15:13:21.504875	\N	chat	chat	1324.450337	0	f	\N	\N	\N	\N	f	2026-02-01 15:35:25.955299
117	default	2026-02-01 15:55:31.620746	\N	chat	getNotes	0.0035	1	f	\N	\N	\N	\N	f	2026-02-01 15:55:31.62425
75	default	2026-02-01 15:35:31.895244	\N	InternalSession	\N	0.005399	1	f	\N	\N	\N	\N	f	2026-02-01 15:35:31.900667
76	default	2026-02-01 15:35:53.735098	\N	chat	getChannels	0.016313	1	f	\N	\N	\N	\N	f	2026-02-01 15:35:53.751457
118	default	2026-02-01 15:55:33.493684	\N	chat	deleteChannel	0.009704	2	f	\N	\N	\N	\N	f	2026-02-01 15:55:33.503403
77	default	2026-02-01 15:35:53.850177	\N	chat	getNotes	0.010395	1	f	\N	\N	\N	\N	f	2026-02-01 15:35:53.860576
119	default	2026-02-01 15:55:33.516634	\N	chat	getChannels	0.004942	1	f	\N	\N	\N	\N	f	2026-02-01 15:55:33.521586
79	default	2026-02-01 15:36:02.797958	\N	chat	getNotes	0.003337	1	f	\N	\N	\N	\N	f	2026-02-01 15:36:02.801297
120	default	2026-02-01 15:55:33.528973	\N	chat	getChannels	0.006739	1	f	\N	\N	\N	\N	f	2026-02-01 15:55:33.535722
80	default	2026-02-01 15:36:03.795874	\N	chat	getNotes	0.003306	1	f	\N	\N	\N	\N	f	2026-02-01 15:36:03.799183
81	default	2026-02-01 15:36:20.317264	\N	chat	updateChannel	0.010385	2	f	\N	\N	\N	\N	f	2026-02-01 15:36:20.327653
121	default	2026-02-01 15:55:41.200027	\N	chat	createChannel	0.007849	1	f	\N	\N	\N	\N	f	2026-02-01 15:55:41.207893
82	default	2026-02-01 15:36:20.35336	\N	chat	getChannels	0.004536	1	f	\N	\N	\N	\N	f	2026-02-01 15:36:20.357899
60	default	2026-02-01 15:13:24.11236	\N	chat	chat	\N	\N	\N	\N	\N	\N	\N	f	2026-02-01 15:34:00.017902
83	default	2026-02-01 15:37:51.160895	\N	chat	getNotes	0.003797	1	f	\N	\N	\N	\N	f	2026-02-01 15:37:51.164694
122	default	2026-02-01 15:55:41.223789	\N	chat	getChannels	0.008791	1	f	\N	\N	\N	\N	f	2026-02-01 15:55:41.232584
84	default	2026-02-01 15:37:51.996889	\N	chat	getNotes	0.003337	1	f	\N	\N	\N	\N	f	2026-02-01 15:37:52.000229
123	default	2026-02-01 15:55:41.230369	\N	chat	getChannels	0.004467	1	f	\N	\N	\N	\N	f	2026-02-01 15:55:41.234845
85	default	2026-02-01 15:37:53.369043	\N	chat	getNotes	0.003501	1	f	\N	\N	\N	\N	f	2026-02-01 15:37:53.372547
86	default	2026-02-01 15:37:53.841592	\N	chat	getNotes	0.003072	1	f	\N	\N	\N	\N	f	2026-02-01 15:37:53.844666
124	default	2026-02-01 15:55:42.629644	\N	chat	getNotes	0.00473	1	f	\N	\N	\N	\N	f	2026-02-01 15:55:42.634377
87	default	2026-02-01 15:37:54.392519	\N	chat	getNotes	0.004242	1	f	\N	\N	\N	\N	f	2026-02-01 15:37:54.396765
125	default	2026-02-01 15:55:45.206446	\N	chat	createNote	0.011793	3	f	\N	\N	\N	\N	f	2026-02-01 15:55:45.218256
88	default	2026-02-01 15:48:25.240047	\N	chat	getChannels	0.007687	1	f	\N	\N	\N	\N	f	2026-02-01 15:48:25.247737
89	default	2026-02-01 15:48:25.327205	\N	chat	getNotes	0.005721	1	f	\N	\N	\N	\N	f	2026-02-01 15:48:25.332936
91	default	2026-02-01 15:48:43.878684	\N	chat	getChannels	0.004394	1	f	\N	\N	\N	\N	f	2026-02-01 15:48:43.883083
92	default	2026-02-01 15:48:43.975378	\N	chat	getNotes	0.006287	1	f	\N	\N	\N	\N	f	2026-02-01 15:48:43.981673
78	default	2026-02-01 15:35:54.034577	\N	chat	chat	773.537348	0	f	\N	\N	\N	\N	f	2026-02-01 15:48:47.571947
74	default	2026-02-01 15:35:20.901316	\N	chat	chat	\N	\N	\N	\N	\N	\N	\N	f	2026-02-01 15:35:20.901339
94	default	2026-02-01 15:49:30.4992	\N	chat	getChannels	0.003606	1	f	\N	\N	\N	\N	f	2026-02-01 15:49:30.50281
95	default	2026-02-01 15:49:30.540248	\N	chat	getNotes	0.004089	1	f	\N	\N	\N	\N	f	2026-02-01 15:49:30.544348
111	default	2026-02-01 15:55:08.785768	\N	chat	chat	3192.066124	0	f	\N	\N	\N	\N	f	2026-02-01 16:48:20.851919
97	default	2026-02-01 15:49:31.43333	\N	chat	getNotes	0.00537	1	f	\N	\N	\N	\N	f	2026-02-01 15:49:31.438707
90	default	2026-02-01 15:48:25.751151	\N	chat	chat	68.295295	0	f	\N	\N	\N	\N	f	2026-02-01 15:49:34.046457
98	default	2026-02-01 15:49:58.816262	\N	chat	getNotes	0.007408	1	f	\N	\N	\N	\N	f	2026-02-01 15:49:58.823705
99	default	2026-02-01 15:49:59.459662	\N	chat	getNotes	0.005527	1	f	\N	\N	\N	\N	f	2026-02-01 15:49:59.465193
100	default	2026-02-01 15:50:00.182315	\N	chat	getNotes	0.003365	1	f	\N	\N	\N	\N	f	2026-02-01 15:50:00.185683
93	default	2026-02-01 15:48:44.141043	\N	chat	chat	76.973623	0	f	\N	\N	\N	\N	f	2026-02-01 15:50:01.114678
101	default	2026-02-01 15:50:14.141676	\N	chat	getNotes	0.004425	1	f	\N	\N	\N	\N	f	2026-02-01 15:50:14.146105
166	default	2026-02-01 16:50:20.328165	\N	chat	getChannels	0.002718	1	f	\N	\N	\N	\N	f	2026-02-01 16:50:20.330885
126	default	2026-02-01 15:55:47.817684	\N	chat	updateChannel	0.008314	2	f	\N	\N	\N	\N	f	2026-02-01 15:55:47.826004
127	default	2026-02-01 15:55:47.841152	\N	chat	getChannels	0.003436	1	f	\N	\N	\N	\N	f	2026-02-01 15:55:47.844596
167	default	2026-02-01 16:50:20.402408	\N	chat	getNotes	0.004397	1	f	\N	\N	\N	\N	f	2026-02-01 16:50:20.406809
128	default	2026-02-01 15:55:47.852741	\N	chat	getChannels	0.005336	1	f	\N	\N	\N	\N	f	2026-02-01 15:55:47.85809
115	default	2026-02-01 15:55:26.338662	\N	chat	chat	72.621243	0	f	\N	\N	\N	\N	f	2026-02-01 15:56:38.959925
168	default	2026-02-01 16:50:20.532516	\N	chat	getNotes	0.007894	1	f	\N	\N	\N	\N	f	2026-02-01 16:50:20.540412
129	default	2026-02-01 15:56:51.138235	\N	chat	getChannels	0.00487	1	f	\N	\N	\N	\N	f	2026-02-01 15:56:51.14311
130	default	2026-02-01 15:56:51.208762	\N	chat	getNotes	0.004305	1	f	\N	\N	\N	\N	f	2026-02-01 15:56:51.21307
171	default	2026-02-01 16:56:11.713186	\N	chat	getChannels	0.003314	1	f	\N	\N	\N	\N	f	2026-02-01 16:56:11.716503
132	default	2026-02-01 15:57:00.363875	\N	chat	getNotes	0.003286	1	f	\N	\N	\N	\N	f	2026-02-01 15:57:00.367188
133	default	2026-02-01 15:57:00.821083	\N	chat	getNotes	0.002995	1	f	\N	\N	\N	\N	f	2026-02-01 15:57:00.82408
172	default	2026-02-01 16:56:11.779293	\N	chat	getNotes	0.002566	1	f	\N	\N	\N	\N	f	2026-02-01 16:56:11.781861
134	default	2026-02-01 15:58:02.182538	\N	chat	getNotes	0.003172	1	f	\N	\N	\N	\N	f	2026-02-01 15:58:02.185713
135	default	2026-02-01 15:58:02.84639	\N	chat	getNotes	0.003749	1	f	\N	\N	\N	\N	f	2026-02-01 15:58:02.850143
175	default	2026-02-01 16:56:11.933854	\N	chat	getNotes	0.004242	1	f	\N	\N	\N	\N	f	2026-02-01 16:56:11.9381
136	default	2026-02-01 15:58:04.455515	\N	chat	getNotes	0.003225	1	f	\N	\N	\N	\N	f	2026-02-01 15:58:04.458743
174	default	2026-02-01 16:56:11.93476	\N	chat	getNotes	0.003827	1	f	\N	\N	\N	\N	f	2026-02-01 16:56:11.938589
137	default	2026-02-01 16:37:50.778635	\N	chat	getNotes	0.006304	1	f	\N	\N	\N	\N	f	2026-02-01 16:37:50.784943
131	default	2026-02-01 15:56:51.39756	\N	chat	chat	2460.663745	0	f	\N	\N	\N	\N	f	2026-02-01 16:37:52.061312
138	default	2026-02-01 16:37:52.053925	\N	chat	deleteChannel	0.006733	2	f	\N	\N	\N	\N	f	2026-02-01 16:37:52.060661
170	default	2026-02-01 16:50:20.545906	\N	chat	chat	461.861382	0	f	\N	\N	\N	\N	f	2026-02-01 16:58:02.407298
139	default	2026-02-01 16:37:52.076715	\N	chat	getChannels	0.003275	1	f	\N	\N	\N	\N	f	2026-02-01 16:37:52.079994
140	default	2026-02-01 16:37:53.824205	\N	chat	deleteChannel	0.006283	2	f	\N	\N	\N	\N	f	2026-02-01 16:37:53.830493
176	default	2026-02-01 16:58:26.580893	\N	chat	getChannels	0.002981	1	f	\N	\N	\N	\N	f	2026-02-01 16:58:26.583877
141	default	2026-02-01 16:37:53.846245	\N	chat	getChannels	0.002842	1	f	\N	\N	\N	\N	f	2026-02-01 16:37:53.849089
142	default	2026-02-01 16:37:57.407648	\N	chat	deleteChannel	0.008685	2	f	\N	\N	\N	\N	f	2026-02-01 16:37:57.416346
177	default	2026-02-01 16:58:26.613738	\N	chat	getNotes	0.002781	1	f	\N	\N	\N	\N	f	2026-02-01 16:58:26.616523
143	default	2026-02-01 16:37:57.428621	\N	chat	getChannels	0.003214	1	f	\N	\N	\N	\N	f	2026-02-01 16:37:57.431838
144	default	2026-02-01 16:37:58.865696	\N	chat	deleteChannel	0.00587	1	f	Exception: Cannot delete the last remaining channel	#0      ChatEndpoint.deleteChannel (package:on_air_server/src/chat/chat_endpoint.dart:139:7)\n<asynchronous suspension>\n#1      Server._handleEndpointCall (package:serverpod/src/server/server.dart:444:22)\n<asynchronous suspension>\n#2      Server._endpoints (package:serverpod/src/server/server.dart:311:12)\n<asynchronous suspension>\n#3      Server._reportException.<anonymous closure> (package:serverpod/src/server/server.dart:205:16)\n<asynchronous suspension>\n#4      Server._headers.<anonymous closure> (package:serverpod/src/server/server.dart:286:22)\n<asynchronous suspension>\n#5      _RoutingMiddlewareBuilder.call.<anonymous closure> (package:relic/src/middleware/routing_middleware.dart:121:18)\n<asynchronous suspension>\n#6      _RelicServer._wrapHandlerWithMiddleware.<anonymous closure> (package:relic/src/relic_server.dart:151:24)\n<asynchronous suspension>\n#7      _RelicServer._handleRequest (package:relic/src/relic_server.dart:127:22)\n<asynchronous suspension>\n	\N	\N	f	2026-02-01 16:37:58.871574
145	default	2026-02-01 16:38:40.763578	\N	chat	getNotes	0.003505	1	f	\N	\N	\N	\N	f	2026-02-01 16:38:40.767086
179	default	2026-02-01 16:58:26.718287	\N	chat	getNotes	0.00333	1	f	\N	\N	\N	\N	f	2026-02-01 16:58:26.721619
146	default	2026-02-01 16:38:44.831441	\N	chat	deleteNote	0.012289	2	f	\N	\N	\N	\N	f	2026-02-01 16:38:44.843737
173	default	2026-02-01 16:56:11.883192	\N	chat	chat	138.396891	0	f	\N	\N	\N	\N	f	2026-02-01 16:58:30.280091
147	default	2026-02-01 16:38:52.718088	\N	chat	createNote	0.009641	3	f	\N	\N	\N	\N	f	2026-02-01 16:38:52.727733
148	default	2026-02-01 16:41:39.92939	\N	chat	getChannels	0.005288	1	f	\N	\N	\N	\N	f	2026-02-01 16:41:39.934681
149	default	2026-02-01 16:41:40.008223	\N	chat	getNotes	0.003432	1	f	\N	\N	\N	\N	f	2026-02-01 16:41:40.011657
180	default	2026-02-01 16:59:58.117724	\N	chat	getChannels	0.00366	1	f	\N	\N	\N	\N	f	2026-02-01 16:59:58.121388
151	default	2026-02-01 16:41:47.504066	\N	chat	getNotes	0.003738	1	f	\N	\N	\N	\N	f	2026-02-01 16:41:47.507807
181	default	2026-02-01 16:59:58.142654	\N	chat	getNotes	0.004346	1	f	\N	\N	\N	\N	f	2026-02-01 16:59:58.147002
152	default	2026-02-01 16:42:43.653476	\N	chat	createNote	0.010288	3	f	\N	\N	\N	\N	f	2026-02-01 16:42:43.663767
153	default	2026-02-01 16:42:52.547194	\N	chat	createNote	0.008124	3	f	\N	\N	\N	\N	f	2026-02-01 16:42:52.555321
183	default	2026-02-01 16:59:58.245765	\N	chat	getNotes	0.004137	1	f	\N	\N	\N	\N	f	2026-02-01 16:59:58.24991
150	default	2026-02-01 16:41:40.020606	\N	chat	chat	348.132957	0	f	\N	\N	\N	\N	f	2026-02-01 16:47:28.153587
154	default	2026-02-01 16:47:41.6554	\N	chat	getChannels	0.005009	1	f	\N	\N	\N	\N	f	2026-02-01 16:47:41.660412
155	default	2026-02-01 16:47:41.731752	\N	chat	getNotes	0.016258	1	f	\N	\N	\N	\N	f	2026-02-01 16:47:41.748022
178	default	2026-02-01 16:58:26.65961	\N	chat	chat	96.694889	0	f	\N	\N	\N	\N	f	2026-02-01 17:00:03.354507
182	default	2026-02-01 16:59:58.190924	\N	chat	chat	37.317898	0	f	\N	\N	\N	\N	f	2026-02-01 17:00:35.508834
157	default	2026-02-01 16:47:41.908691	\N	chat	getNotes	0.004237	1	f	\N	\N	\N	\N	f	2026-02-01 16:47:41.912932
184	default	2026-02-01 17:00:49.611304	\N	chat	getChannels	0.003783	1	f	\N	\N	\N	\N	f	2026-02-01 17:00:49.615093
158	default	2026-02-01 16:49:11.573561	\N	chat	createChannel	0.004622	1	f	\N	\N	\N	\N	f	2026-02-01 16:49:11.578188
185	default	2026-02-01 17:00:49.679985	\N	chat	getNotes	0.003521	1	f	\N	\N	\N	\N	f	2026-02-01 17:00:49.683509
159	default	2026-02-01 16:49:11.591219	\N	chat	getChannels	0.002857	1	f	\N	\N	\N	\N	f	2026-02-01 16:49:11.594081
160	default	2026-02-01 16:49:11.630713	\N	chat	getNotes	0.004019	1	f	\N	\N	\N	\N	f	2026-02-01 16:49:11.634736
161	default	2026-02-01 16:49:46.824418	\N	chat	getChannels	0.003028	1	f	\N	\N	\N	\N	f	2026-02-01 16:49:46.827449
162	default	2026-02-01 16:49:46.860199	\N	chat	getNotes	0.004324	1	f	\N	\N	\N	\N	f	2026-02-01 16:49:46.864525
187	default	2026-02-01 17:00:49.837012	\N	chat	getNotes	0.004859	1	f	\N	\N	\N	\N	f	2026-02-01 17:00:49.841879
164	default	2026-02-01 16:49:46.935614	\N	chat	getNotes	0.008671	1	f	\N	\N	\N	\N	f	2026-02-01 16:49:46.944288
165	default	2026-02-01 16:49:46.937022	\N	chat	getNotes	0.008462	1	f	\N	\N	\N	\N	f	2026-02-01 16:49:46.945486
156	default	2026-02-01 16:47:41.856598	\N	chat	chat	128.510797	0	f	\N	\N	\N	\N	f	2026-02-01 16:49:50.367415
163	default	2026-02-01 16:49:46.908893	\N	chat	chat	17.791342	0	f	\N	\N	\N	\N	f	2026-02-01 16:50:04.700243
186	default	2026-02-01 17:00:49.840374	\N	chat	chat	468.515498	0	f	\N	\N	\N	\N	f	2026-02-01 17:08:38.355949
188	default	2026-02-01 17:00:49.838413	\N	chat	getNotes	0.00551	1	f	\N	\N	\N	\N	f	2026-02-01 17:00:49.84393
248	default	2026-02-02 05:52:19.679073	\N	chat	createNote	0.013499	3	f	\N	\N	\N	\N	f	2026-02-02 05:52:19.692574
249	default	2026-02-02 05:52:32.172822	\N	chat	deleteNote	0.006382	2	f	\N	\N	\N	\N	f	2026-02-02 05:52:32.179206
250	default	2026-02-02 05:53:10.175203	\N	chat	createNote	0.015112	3	f	\N	\N	\N	\N	f	2026-02-02 05:53:10.190319
251	default	2026-02-02 05:53:23.261338	\N	chat	createNote	0.011499	3	f	\N	\N	\N	\N	f	2026-02-02 05:53:23.27284
252	default	2026-02-02 05:53:54.750091	\N	chat	createNote	0.009464	3	f	\N	\N	\N	\N	f	2026-02-02 05:53:54.759557
253	default	2026-02-02 06:01:45.636214	\N	chat	getChannels	0.025818	1	f	\N	\N	\N	\N	f	2026-02-02 06:01:45.662036
254	default	2026-02-02 06:01:45.763033	\N	chat	getNotes	0.007041	1	f	\N	\N	\N	\N	f	2026-02-02 06:01:45.770077
255	default	2026-02-02 06:01:45.936584	\N	chat	getNotes	0.009242	1	f	\N	\N	\N	\N	f	2026-02-02 06:01:45.945828
257	default	2026-02-02 06:01:45.9389	\N	chat	getNotes	0.054733	1	f	\N	\N	\N	\N	f	2026-02-02 06:01:45.993637
258	default	2026-02-02 06:01:45.940883	\N	chat	getNotes	0.096191	1	f	\N	\N	\N	\N	f	2026-02-02 06:01:46.037076
261	default	2026-02-02 06:02:33.188256	\N	chat	createNote	0.013877	3	f	\N	\N	\N	\N	f	2026-02-02 06:02:33.202136
262	default	2026-02-02 06:02:50.216228	\N	chat	deleteNote	0.008294	2	f	\N	\N	\N	\N	f	2026-02-02 06:02:50.224527
263	default	2026-02-02 06:02:50.723857	\N	chat	deleteNote	0.006475	2	f	\N	\N	\N	\N	f	2026-02-02 06:02:50.730336
264	default	2026-02-02 06:02:51.198904	\N	chat	deleteNote	0.006739	2	f	\N	\N	\N	\N	f	2026-02-02 06:02:51.205648
265	default	2026-02-02 06:02:51.590456	\N	chat	deleteNote	0.005401	2	f	\N	\N	\N	\N	f	2026-02-02 06:02:51.59586
266	default	2026-02-02 06:02:51.98224	\N	chat	deleteNote	0.00531	2	f	\N	\N	\N	\N	f	2026-02-02 06:02:51.987554
267	default	2026-02-02 06:02:55.491483	\N	chat	createNote	0.022297	3	f	\N	\N	\N	\N	f	2026-02-02 06:02:55.513784
268	default	2026-02-02 06:03:10.404001	\N	chat	createNote	0.013279	3	f	\N	\N	\N	\N	f	2026-02-02 06:03:10.417284
260	default	2026-02-02 06:01:45.942088	\N	chat	chat	298.085022	0	f	\N	\N	\N	\N	f	2026-02-02 06:06:44.027127
277	default	2026-02-02 06:07:07.746003	\N	chat	getNotes	0.024292	1	f	\N	\N	\N	\N	f	2026-02-02 06:07:07.770296
279	default	2026-02-02 06:07:07.75528	\N	chat	getNotes	0.014812	1	f	\N	\N	\N	\N	f	2026-02-02 06:07:07.770093
282	default	2026-02-02 06:09:21.948929	\N	chat	createNote	0.011258	3	f	\N	\N	\N	\N	f	2026-02-02 06:09:21.960191
283	default	2026-02-02 06:09:28.715463	\N	chat	createNote	0.007388	3	f	\N	\N	\N	\N	f	2026-02-02 06:09:28.722854
284	default	2026-02-02 06:09:36.38761	\N	chat	createNote	0.009868	3	f	\N	\N	\N	\N	f	2026-02-02 06:09:36.397487
285	default	2026-02-02 06:09:46.554434	\N	chat	createNote	0.005701	3	f	\N	\N	\N	\N	f	2026-02-02 06:09:46.560138
286	default	2026-02-02 06:12:51.841481	\N	chat	getChannels	0.006432	1	f	\N	\N	\N	\N	f	2026-02-02 06:12:51.847917
287	default	2026-02-02 06:12:51.878157	\N	chat	getNotes	0.003112	1	f	\N	\N	\N	\N	f	2026-02-02 06:12:51.881271
289	default	2026-02-02 06:12:52.152274	\N	chat	getNotes	0.007821	1	f	\N	\N	\N	\N	f	2026-02-02 06:12:52.160097
290	default	2026-02-02 06:12:52.153669	\N	chat	getNotes	0.007165	1	f	\N	\N	\N	\N	f	2026-02-02 06:12:52.160835
291	default	2026-02-02 06:12:52.154792	\N	chat	getNotes	0.006392	1	f	\N	\N	\N	\N	f	2026-02-02 06:12:52.161184
292	default	2026-02-02 06:12:52.15306	\N	chat	getNotes	0.008014	1	f	\N	\N	\N	\N	f	2026-02-02 06:12:52.161075
275	default	2026-02-02 06:07:04.298173	\N	chat	chat	351.20507	0	f	\N	\N	\N	\N	f	2026-02-02 06:12:55.503251
288	default	2026-02-02 06:12:51.939086	\N	chat	chat	15.959989	0	f	\N	\N	\N	\N	f	2026-02-02 06:13:07.899082
293	default	2026-02-02 06:13:21.130187	\N	chat	getChannels	0.010834	1	f	\N	\N	\N	\N	f	2026-02-02 06:13:21.141026
294	default	2026-02-02 06:13:21.276772	\N	chat	getNotes	0.002868	1	f	\N	\N	\N	\N	f	2026-02-02 06:13:21.279644
296	default	2026-02-02 06:13:21.666155	\N	chat	getNotes	0.008319	1	f	\N	\N	\N	\N	f	2026-02-02 06:13:21.674478
299	default	2026-02-02 06:13:21.66697	\N	chat	getNotes	0.010795	1	f	\N	\N	\N	\N	f	2026-02-02 06:13:21.677767
298	default	2026-02-02 06:13:21.667687	\N	chat	getNotes	0.010355	1	f	\N	\N	\N	\N	f	2026-02-02 06:13:21.678043
300	default	2026-02-02 06:13:21.668725	\N	chat	getNotes	0.009209	1	f	\N	\N	\N	\N	f	2026-02-02 06:13:21.677935
297	default	2026-02-02 06:13:21.667325	\N	chat	getNotes	0.010015	1	f	\N	\N	\N	\N	f	2026-02-02 06:13:21.677343
301	default	2026-02-02 06:13:31.127258	\N	chat	createNote	0.010365	3	f	\N	\N	\N	\N	f	2026-02-02 06:13:31.137627
302	default	2026-02-02 06:13:34.942407	\N	chat	createNote	0.013451	3	f	\N	\N	\N	\N	f	2026-02-02 06:13:34.955863
303	default	2026-02-02 06:13:39.872846	\N	chat	createNote	0.013992	3	f	\N	\N	\N	\N	f	2026-02-02 06:13:39.886842
304	default	2026-02-02 06:15:22.192924	\N	chat	createChannel	0.006261	1	f	\N	\N	\N	\N	f	2026-02-02 06:15:22.199188
305	default	2026-02-02 06:15:22.211818	\N	chat	getChannels	0.002295	1	f	\N	\N	\N	\N	f	2026-02-02 06:15:22.214115
306	default	2026-02-02 06:15:22.256777	\N	chat	getNotes	0.004611	1	f	\N	\N	\N	\N	f	2026-02-02 06:15:22.261391
295	default	2026-02-02 06:13:21.295642	\N	chat	chat	196.333149	0	f	\N	\N	\N	\N	f	2026-02-02 06:16:37.62881
307	default	2026-02-02 06:16:49.673117	\N	chat	getChannels	0.004088	1	f	\N	\N	\N	\N	f	2026-02-02 06:16:49.677209
308	default	2026-02-02 06:16:49.747285	\N	chat	getNotes	0.004329	1	f	\N	\N	\N	\N	f	2026-02-02 06:16:49.751616
310	default	2026-02-02 06:16:49.934873	\N	chat	getNotes	0.006022	1	f	\N	\N	\N	\N	f	2026-02-02 06:16:49.940897
311	default	2026-02-02 06:16:49.935721	\N	chat	getNotes	0.005874	1	f	\N	\N	\N	\N	f	2026-02-02 06:16:49.9416
312	default	2026-02-02 06:16:49.936515	\N	chat	getNotes	0.009874	1	f	\N	\N	\N	\N	f	2026-02-02 06:16:49.946394
313	default	2026-02-02 06:16:49.936845	\N	chat	getNotes	0.010227	1	f	\N	\N	\N	\N	f	2026-02-02 06:16:49.947073
315	default	2026-02-02 06:16:49.937576	\N	chat	getNotes	0.010547	1	f	\N	\N	\N	\N	f	2026-02-02 06:16:49.948124
314	default	2026-02-02 06:16:49.936175	\N	chat	getNotes	0.010695	1	f	\N	\N	\N	\N	f	2026-02-02 06:16:49.946871
316	default	2026-02-02 06:16:54.130804	\N	chat	updateChannel	0.005599	2	f	\N	\N	\N	\N	f	2026-02-02 06:16:54.136408
317	default	2026-02-02 06:16:54.154222	\N	chat	getChannels	0.003514	1	f	\N	\N	\N	\N	f	2026-02-02 06:16:54.15774
318	default	2026-02-02 06:16:59.832536	\N	chat	createNote	0.012543	3	f	\N	\N	\N	\N	f	2026-02-02 06:16:59.845082
319	default	2026-02-02 06:17:07.413158	\N	chat	createNote	0.011928	3	f	\N	\N	\N	\N	f	2026-02-02 06:17:07.42509
320	default	2026-02-02 06:17:17.184299	\N	chat	createNote	0.008509	3	f	\N	\N	\N	\N	f	2026-02-02 06:17:17.192811
321	default	2026-02-02 06:17:23.805517	\N	chat	createNote	0.011602	3	f	\N	\N	\N	\N	f	2026-02-02 06:17:23.817123
322	default	2026-02-02 06:17:34.871653	\N	chat	createNote	0.008307	3	f	\N	\N	\N	\N	f	2026-02-02 06:17:34.879963
323	default	2026-02-02 06:17:41.350178	\N	chat	createNote	0.015008	3	f	\N	\N	\N	\N	f	2026-02-02 06:17:41.365189
324	default	2026-02-02 06:17:45.695669	\N	chat	createNote	0.006785	3	f	\N	\N	\N	\N	f	2026-02-02 06:17:45.702457
325	default	2026-02-02 06:17:54.471736	\N	chat	createNote	0.008376	3	f	\N	\N	\N	\N	f	2026-02-02 06:17:54.480114
326	default	2026-02-02 06:18:59.167292	\N	chat	createNote	0.01136	3	f	\N	\N	\N	\N	f	2026-02-02 06:18:59.178655
309	default	2026-02-02 06:16:49.865434	\N	chat	chat	238.953682	0	f	\N	\N	\N	\N	f	2026-02-02 06:20:48.819132
327	default	2026-02-02 06:21:07.256967	\N	chat	getChannels	0.008846	1	f	\N	\N	\N	\N	f	2026-02-02 06:21:07.265817
328	default	2026-02-02 06:21:07.345054	\N	chat	getNotes	0.003815	1	f	\N	\N	\N	\N	f	2026-02-02 06:21:07.348871
329	default	2026-02-02 06:21:07.359914	\N	chat	chat	251.949672	0	f	\N	\N	\N	\N	f	2026-02-02 06:25:19.309634
189	default	2026-02-01 17:02:35.50113	\N	chat	createNote	0.010201	3	f	\N	\N	\N	\N	f	2026-02-01 17:02:35.511347
345	default	2026-02-02 06:38:08.078741	\N	chat	getChannels	0.006104	1	f	\N	\N	\N	\N	f	2026-02-02 06:38:08.084848
190	default	2026-02-01 17:02:38.091122	\N	chat	createNote	0.009438	3	f	\N	\N	\N	\N	f	2026-02-01 17:02:38.100564
191	default	2026-02-02 05:22:32.273706	\N	chat	getChannels	0.047945	1	f	\N	\N	\N	\N	f	2026-02-02 05:22:32.321654
238	default	2026-02-02 05:50:38.831527	\N	chat	chat	629.246835	0	f	\N	\N	\N	\N	f	2026-02-02 06:01:08.078477
192	default	2026-02-02 05:22:32.34001	\N	chat	getNotes	0.002885	1	f	\N	\N	\N	\N	f	2026-02-02 05:22:32.342898
256	default	2026-02-02 06:01:45.938027	\N	chat	getNotes	0.009349	1	f	\N	\N	\N	\N	f	2026-02-02 06:01:45.947379
194	default	2026-02-02 05:22:32.511773	\N	chat	getNotes	0.008405	1	f	\N	\N	\N	\N	f	2026-02-02 05:22:32.520184
195	default	2026-02-02 05:22:43.490178	\N	chat	createNote	0.009079	3	f	\N	\N	\N	\N	f	2026-02-02 05:22:43.499259
259	default	2026-02-02 06:01:45.941702	\N	chat	getNotes	0.110939	1	f	\N	\N	\N	\N	f	2026-02-02 06:01:46.052643
196	default	2026-02-02 05:22:53.093426	\N	chat	createNote	0.008349	3	f	\N	\N	\N	\N	f	2026-02-02 05:22:53.101778
269	default	2026-02-02 06:03:28.673172	\N	chat	createNote	0.01514	3	f	\N	\N	\N	\N	f	2026-02-02 06:03:28.688316
197	default	2026-02-02 05:23:00.527457	\N	chat	createNote	0.010292	3	f	\N	\N	\N	\N	f	2026-02-02 05:23:00.53775
198	default	2026-02-02 05:23:20.418077	\N	chat	createNote	0.009466	3	f	\N	\N	\N	\N	f	2026-02-02 05:23:20.427546
270	default	2026-02-02 06:03:54.461643	\N	chat	createNote	0.015947	3	f	\N	\N	\N	\N	f	2026-02-02 06:03:54.477594
199	default	2026-02-02 05:27:01.962223	\N	chat	getChannels	0.006621	1	f	\N	\N	\N	\N	f	2026-02-02 05:27:01.968849
271	default	2026-02-02 06:04:01.648381	\N	chat	createNote	0.012051	3	f	\N	\N	\N	\N	f	2026-02-02 06:04:01.660435
200	default	2026-02-02 05:27:02.001779	\N	chat	getNotes	0.003557	1	f	\N	\N	\N	\N	f	2026-02-02 05:27:02.005341
272	default	2026-02-02 06:05:05.804369	\N	chat	createNote	0.013839	3	f	\N	\N	\N	\N	f	2026-02-02 06:05:05.818212
202	default	2026-02-02 05:27:02.12659	\N	chat	getNotes	0.003801	1	f	\N	\N	\N	\N	f	2026-02-02 05:27:02.130393
193	default	2026-02-02 05:22:32.43823	\N	chat	chat	273.242047	0	f	\N	\N	\N	\N	f	2026-02-02 05:27:05.680299
201	default	2026-02-02 05:27:02.058779	\N	chat	chat	23.788452	0	f	\N	\N	\N	\N	f	2026-02-02 05:27:25.847239
203	default	2026-02-02 05:27:38.282475	\N	chat	getChannels	0.003342	1	f	\N	\N	\N	\N	f	2026-02-02 05:27:38.28582
273	default	2026-02-02 06:07:04.221489	\N	chat	getChannels	0.008938	1	f	\N	\N	\N	\N	f	2026-02-02 06:07:04.23043
204	default	2026-02-02 05:27:38.351127	\N	chat	getNotes	0.004469	1	f	\N	\N	\N	\N	f	2026-02-02 05:27:38.3556
274	default	2026-02-02 06:07:04.290548	\N	chat	getNotes	0.003393	1	f	\N	\N	\N	\N	f	2026-02-02 06:07:04.293943
206	default	2026-02-02 05:27:38.556517	\N	chat	getNotes	0.003949	1	f	\N	\N	\N	\N	f	2026-02-02 05:27:38.560474
207	default	2026-02-02 05:27:41.971494	\N	chat	createNote	0.008538	3	f	\N	\N	\N	\N	f	2026-02-02 05:27:41.980034
208	default	2026-02-02 05:27:47.628826	\N	chat	createNote	0.007394	3	f	\N	\N	\N	\N	f	2026-02-02 05:27:47.636223
209	default	2026-02-02 05:27:50.801845	\N	chat	createNote	0.008667	3	f	\N	\N	\N	\N	f	2026-02-02 05:27:50.810517
276	default	2026-02-02 06:07:07.744749	\N	chat	getNotes	0.022213	1	f	\N	\N	\N	\N	f	2026-02-02 06:07:07.766966
210	default	2026-02-02 05:27:57.831158	\N	chat	createNote	0.012855	3	f	\N	\N	\N	\N	f	2026-02-02 05:27:57.844029
278	default	2026-02-02 06:07:07.749808	\N	chat	getNotes	0.019857	1	f	\N	\N	\N	\N	f	2026-02-02 06:07:07.769668
280	default	2026-02-02 06:07:07.757397	\N	chat	getNotes	0.014034	1	f	\N	\N	\N	\N	f	2026-02-02 06:07:07.771433
211	default	2026-02-02 05:28:00.277845	\N	chat	createNote	0.007232	3	f	\N	\N	\N	\N	f	2026-02-02 05:28:00.28508
281	default	2026-02-02 06:07:53.880202	\N	chat	createNote	0.008356	3	f	\N	\N	\N	\N	f	2026-02-02 06:07:53.88856
212	default	2026-02-02 05:34:54.312127	\N	chat	getChannels	0.007239	1	f	\N	\N	\N	\N	f	2026-02-02 05:34:54.31937
213	default	2026-02-02 05:34:54.398341	\N	chat	getNotes	0.004815	1	f	\N	\N	\N	\N	f	2026-02-02 05:34:54.403158
205	default	2026-02-02 05:27:38.460841	\N	chat	chat	439.014828	0	f	\N	\N	\N	\N	f	2026-02-02 05:34:57.475676
215	default	2026-02-02 05:35:29.19554	\N	chat	getNotes	0.004425	1	f	\N	\N	\N	\N	f	2026-02-02 05:35:29.199972
216	default	2026-02-02 05:40:38.984069	\N	chat	createNote	0.018794	3	f	\N	\N	\N	\N	f	2026-02-02 05:40:39.002867
217	default	2026-02-02 05:40:42.881589	\N	chat	createNote	0.006994	3	f	\N	\N	\N	\N	f	2026-02-02 05:40:42.888585
218	default	2026-02-02 05:41:17.837228	\N	chat	deleteNote	0.006266	2	f	\N	\N	\N	\N	f	2026-02-02 05:41:17.843499
219	default	2026-02-02 05:41:18.267388	\N	chat	deleteNote	0.010896	2	f	\N	\N	\N	\N	f	2026-02-02 05:41:18.278289
220	default	2026-02-02 05:41:18.426138	\N	chat	deleteNote	0.006743	2	f	\N	\N	\N	\N	f	2026-02-02 05:41:18.432884
221	default	2026-02-02 05:41:18.584127	\N	chat	deleteNote	0.006558	2	f	\N	\N	\N	\N	f	2026-02-02 05:41:18.590689
222	default	2026-02-02 05:41:18.734437	\N	chat	deleteNote	0.006462	2	f	\N	\N	\N	\N	f	2026-02-02 05:41:18.740908
223	default	2026-02-02 05:41:18.891994	\N	chat	deleteNote	0.006003	2	f	\N	\N	\N	\N	f	2026-02-02 05:41:18.898001
224	default	2026-02-02 05:41:19.04197	\N	chat	deleteNote	0.005957	2	f	\N	\N	\N	\N	f	2026-02-02 05:41:19.047931
225	default	2026-02-02 05:41:19.20861	\N	chat	deleteNote	0.006306	2	f	\N	\N	\N	\N	f	2026-02-02 05:41:19.21492
226	default	2026-02-02 05:41:28.42082	\N	chat	createChannel	0.004979	1	f	\N	\N	\N	\N	f	2026-02-02 05:41:28.425802
227	default	2026-02-02 05:41:28.44548	\N	chat	getChannels	0.002867	1	f	\N	\N	\N	\N	f	2026-02-02 05:41:28.448348
228	default	2026-02-02 05:41:28.483753	\N	chat	getNotes	0.003177	1	f	\N	\N	\N	\N	f	2026-02-02 05:41:28.486932
229	default	2026-02-02 05:42:00.154319	\N	chat	createChannel	0.004019	1	f	\N	\N	\N	\N	f	2026-02-02 05:42:00.15834
230	default	2026-02-02 05:42:00.171767	\N	chat	getChannels	0.002448	1	f	\N	\N	\N	\N	f	2026-02-02 05:42:00.174217
231	default	2026-02-02 05:42:00.204297	\N	chat	getNotes	0.00307	1	f	\N	\N	\N	\N	f	2026-02-02 05:42:00.20737
232	default	2026-02-02 05:42:08.492929	\N	chat	createNote	0.008894	3	f	\N	\N	\N	\N	f	2026-02-02 05:42:08.501826
233	default	2026-02-02 05:42:16.811193	\N	chat	createNote	0.008635	3	f	\N	\N	\N	\N	f	2026-02-02 05:42:16.819833
234	default	2026-02-02 05:42:21.995778	\N	chat	createNote	0.008797	3	f	\N	\N	\N	\N	f	2026-02-02 05:42:22.00458
235	default	2026-02-02 05:48:23.694526	\N	chat	createNote	0.0142	3	f	\N	\N	\N	\N	f	2026-02-02 05:48:23.708729
214	default	2026-02-02 05:34:54.401375	\N	chat	chat	930.26891	0	f	\N	\N	\N	\N	f	2026-02-02 05:50:24.67033
236	default	2026-02-02 05:50:38.650196	\N	chat	getChannels	0.010088	1	f	\N	\N	\N	\N	f	2026-02-02 05:50:38.66029
237	default	2026-02-02 05:50:38.724166	\N	chat	getNotes	0.002865	1	f	\N	\N	\N	\N	f	2026-02-02 05:50:38.727033
239	default	2026-02-02 05:50:38.930045	\N	chat	getNotes	0.006256	1	f	\N	\N	\N	\N	f	2026-02-02 05:50:38.936304
240	default	2026-02-02 05:50:38.931028	\N	chat	getNotes	0.022945	1	f	\N	\N	\N	\N	f	2026-02-02 05:50:38.953975
241	default	2026-02-02 05:50:38.931658	\N	chat	getNotes	0.0378	1	f	\N	\N	\N	\N	f	2026-02-02 05:50:38.96946
242	default	2026-02-02 05:51:34.9597	\N	chat	createNote	0.010155	3	f	\N	\N	\N	\N	f	2026-02-02 05:51:34.969859
243	default	2026-02-02 05:51:45.687043	\N	chat	createNote	0.01335	3	f	\N	\N	\N	\N	f	2026-02-02 05:51:45.700395
244	default	2026-02-02 05:51:59.977614	\N	chat	createChannel	0.004042	1	f	\N	\N	\N	\N	f	2026-02-02 05:51:59.981659
245	default	2026-02-02 05:51:59.99742	\N	chat	getChannels	0.002858	1	f	\N	\N	\N	\N	f	2026-02-02 05:52:00.00028
246	default	2026-02-02 05:52:00.047055	\N	chat	getNotes	0.00331	1	f	\N	\N	\N	\N	f	2026-02-02 05:52:00.050368
247	default	2026-02-02 05:52:06.46767	\N	chat	createNote	0.010794	3	f	\N	\N	\N	\N	f	2026-02-02 05:52:06.478466
338	default	2026-02-02 06:25:30.694062	\N	chat	chat	440.916857	0	f	\N	\N	\N	\N	f	2026-02-02 06:32:51.610969
330	default	2026-02-02 06:21:08.456595	\N	chat	getNotes	0.014171	1	f	\N	\N	\N	\N	f	2026-02-02 06:21:08.470773
465	default	2026-02-02 10:59:42.018969	\N	chat	getChannels	0.012224	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:42.031203
336	default	2026-02-02 06:25:30.517712	\N	chat	getChannels	0.005078	1	f	\N	\N	\N	\N	f	2026-02-02 06:25:30.522795
346	default	2026-02-02 06:38:08.148417	\N	chat	getNotes	0.002605	1	f	\N	\N	\N	\N	f	2026-02-02 06:38:08.151024
337	default	2026-02-02 06:25:30.595643	\N	chat	getNotes	0.003066	1	f	\N	\N	\N	\N	f	2026-02-02 06:25:30.598712
612	default	2026-02-02 18:05:59.678635	\N	chat	getChannels	0.005332	1	f	\N	\N	\N	\N	f	2026-02-02 18:05:59.683974
466	default	2026-02-02 10:59:42.119481	\N	chat	getNotes	0.004455	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:42.12395
339	default	2026-02-02 06:25:30.7464	\N	chat	getNotes	0.011163	1	f	\N	\N	\N	\N	f	2026-02-02 06:25:30.757568
807	default	2026-02-02 18:46:55.892227	\N	chat	createChannel	0.006455	1	f	\N	\N	\N	\N	f	2026-02-02 18:46:55.898687
348	default	2026-02-02 06:38:08.289918	\N	chat	getNotes	0.006964	1	f	\N	\N	\N	\N	f	2026-02-02 06:38:08.296884
613	default	2026-02-02 18:05:59.730546	\N	chat	getNotes	0.005344	1	f	\N	\N	\N	\N	f	2026-02-02 18:05:59.735894
347	default	2026-02-02 06:38:08.243116	\N	chat	chat	137.672249	0	f	\N	\N	\N	\N	f	2026-02-02 06:40:25.915573
469	default	2026-02-02 10:59:42.305599	\N	chat	getNotes	0.013273	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:42.318875
354	default	2026-02-02 06:40:43.746291	\N	chat	getChannels	0.007884	1	f	\N	\N	\N	\N	f	2026-02-02 06:40:43.754178
355	default	2026-02-02 06:40:43.817196	\N	chat	getNotes	0.002886	1	f	\N	\N	\N	\N	f	2026-02-02 06:40:43.820084
474	default	2026-02-02 10:59:42.396531	\N	chat	getNotes	0.023491	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:42.420027
357	default	2026-02-02 06:40:43.990688	\N	chat	getNotes	0.007303	1	f	\N	\N	\N	\N	f	2026-02-02 06:40:43.997993
475	default	2026-02-02 10:59:49.218175	\N	chat	getChannels	0.002792	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:49.220978
356	default	2026-02-02 06:40:43.941625	\N	chat	chat	2305.213355	0	f	\N	\N	\N	\N	f	2026-02-02 07:19:09.155024
617	default	2026-02-02 18:05:59.917168	\N	chat	getNotes	0.011981	1	f	\N	\N	\N	\N	f	2026-02-02 18:05:59.92915
370	default	2026-02-02 10:01:29.241889	\N	chat	getNotes	0.015771	1	f	\N	\N	\N	\N	f	2026-02-02 10:01:29.257662
476	default	2026-02-02 10:59:49.267659	\N	chat	getNotes	0.002455	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:49.270119
380	default	2026-02-02 10:02:31.288402	\N	chat	getNotes	0.022942	1	f	\N	\N	\N	\N	f	2026-02-02 10:02:31.311345
395	default	2026-02-02 10:03:37.924201	\N	chat	getNotes	0.015752	1	f	\N	\N	\N	\N	f	2026-02-02 10:03:37.939954
403	default	2026-02-02 10:07:36.506707	\N	chat	getNotes	0.007057	1	f	\N	\N	\N	\N	f	2026-02-02 10:07:36.513766
479	default	2026-02-02 10:59:49.409995	\N	chat	getNotes	0.010506	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:49.420505
415	default	2026-02-02 10:09:25.783339	\N	chat	getNotes	0.010201	1	f	\N	\N	\N	\N	f	2026-02-02 10:09:25.793541
620	default	2026-02-02 18:06:02.364328	\N	/media/channels/16/16/thumbnails/51015af6-0e47-4c3d-8181-667e75302b79_thumb.jpg	\N	0.000647	0	f	\N	\N	\N	\N	f	2026-02-02 18:06:02.364992
430	default	2026-02-02 10:16:48.847173	\N	chat	getNotes	0.044294	1	f	\N	\N	\N	\N	f	2026-02-02 10:16:48.891486
484	default	2026-02-02 10:59:49.432713	\N	chat	getNotes	0.002321	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:49.435036
467	default	2026-02-02 10:59:42.134433	\N	chat	chat	10.788219	0	f	\N	\N	\N	\N	f	2026-02-02 10:59:52.922693
485	default	2026-02-02 10:59:53.734512	\N	chat	getChannels	0.004602	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:53.739116
621	default	2026-02-02 18:06:03.073615	\N	/media/channels/15/thumbnails/3578d03d-70c7-4e4c-96e0-6e2b319075ec_thumb.jpg	\N	0.002531	0	f	\N	\N	\N	\N	f	2026-02-02 18:06:03.076152
486	default	2026-02-02 10:59:53.760147	\N	chat	getNotes	0.003913	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:53.764063
623	default	2026-02-02 18:06:05.520983	\N	/media/channels/15/3578d03d-70c7-4e4c-96e0-6e2b319075ec.png	\N	0.002387	0	f	\N	\N	\N	\N	f	2026-02-02 18:06:05.523384
491	default	2026-02-02 10:59:53.933528	\N	chat	getNotes	0.011445	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:53.944975
477	default	2026-02-02 10:59:49.364217	\N	chat	chat	9.497353	0	f	\N	\N	\N	\N	f	2026-02-02 10:59:58.861578
624	default	2026-02-02 18:06:33.178604	\N	/media/channels/15/thumbnails/3578d03d-70c7-4e4c-96e0-6e2b319075ec_thumb.jpg	\N	0.000304	0	f	\N	\N	\N	\N	f	2026-02-02 18:06:33.178913
487	default	2026-02-02 10:59:53.811128	\N	chat	chat	184.885065	0	f	\N	\N	\N	\N	f	2026-02-02 11:02:58.696202
528	default	2026-02-02 17:18:34.967588	\N	InternalSession	\N	0.004669	1	f	\N	\N	\N	\N	f	2026-02-02 17:18:34.972281
625	default	2026-02-02 18:07:04.736524	\N	/media/channels/15/thumbnails/3578d03d-70c7-4e4c-96e0-6e2b319075ec_thumb.jpg	\N	0.000374	0	f	\N	\N	\N	\N	f	2026-02-02 18:07:04.736904
553	default	2026-02-02 17:42:44.08752	\N	chat	chat	282.528333	0	f	\N	\N	\N	\N	f	2026-02-02 17:47:26.615936
588	default	2026-02-02 17:57:39.265963	\N	chat	deleteChannel	0.00908	2	f	\N	\N	\N	\N	f	2026-02-02 17:57:39.27505
626	default	2026-02-02 18:07:12.716387	\N	/media/channels/15/thumbnails/3578d03d-70c7-4e4c-96e0-6e2b319075ec_thumb.jpg	\N	0.000753	0	f	\N	\N	\N	\N	f	2026-02-02 18:07:12.717147
589	default	2026-02-02 17:57:39.292196	\N	chat	getChannels	0.004587	1	f	\N	\N	\N	\N	f	2026-02-02 17:57:39.296798
590	default	2026-02-02 17:58:12.24518	\N	/media/channels/16/thumbnails/8b31d2ac-84c0-479a-b6d1-9e6cdae21c44_thumb.jpg	\N	0.0091	0	f	\N	\N	\N	\N	f	2026-02-02 17:58:12.254289
627	default	2026-02-02 18:07:58.850672	\N	chat	getChannels	0.003063	1	f	\N	\N	\N	\N	f	2026-02-02 18:07:58.853738
591	default	2026-02-02 17:58:16.973991	\N	/media/channels/16/8b31d2ac-84c0-479a-b6d1-9e6cdae21c44.jpg	\N	0.002211	0	f	\N	\N	\N	\N	f	2026-02-02 17:58:16.976209
628	default	2026-02-02 18:07:58.890049	\N	chat	getNotes	0.00605	1	f	\N	\N	\N	\N	f	2026-02-02 18:07:58.896103
614	default	2026-02-02 18:05:59.788769	\N	chat	chat	128.208069	0	f	\N	\N	\N	\N	f	2026-02-02 18:08:07.99684
633	default	2026-02-02 18:08:20.074318	\N	chat	getNotes	0.028917	1	f	\N	\N	\N	\N	f	2026-02-02 18:08:20.103237
642	default	2026-02-02 18:08:24.472897	\N	chat	getNotes	0.018228	1	f	\N	\N	\N	\N	f	2026-02-02 18:08:24.491129
664	default	2026-02-02 18:20:24.925075	\N	InternalSession	\N	0.006398	1	f	\N	\N	\N	\N	f	2026-02-02 18:20:24.931512
665	default	2026-02-02 18:20:40.882796	\N	chat	getChannels	0.008915	1	f	\N	\N	\N	\N	f	2026-02-02 18:20:40.891718
666	default	2026-02-02 18:20:40.964403	\N	chat	getNotes	0.009984	1	f	\N	\N	\N	\N	f	2026-02-02 18:20:40.974391
668	default	2026-02-02 18:20:43.209102	\N	chat	getNotes	0.020022	1	f	\N	\N	\N	\N	f	2026-02-02 18:20:43.229181
673	default	2026-02-02 18:20:44.679802	\N	/media/channels/16/16/thumbnails/51015af6-0e47-4c3d-8181-667e75302b79_thumb.jpg	\N	0.000361	0	f	\N	\N	\N	\N	f	2026-02-02 18:20:44.680173
675	default	2026-02-02 18:30:33.37603	\N	chat	getChannels	0.004524	1	f	\N	\N	\N	\N	f	2026-02-02 18:30:33.380558
676	default	2026-02-02 18:30:33.445648	\N	chat	getNotes	0.006672	1	f	\N	\N	\N	\N	f	2026-02-02 18:30:33.452323
678	default	2026-02-02 18:30:33.607541	\N	chat	getNotes	0.010173	1	f	\N	\N	\N	\N	f	2026-02-02 18:30:33.617717
683	default	2026-02-02 18:30:34.778594	\N	/media/channels/19/thumbnails/69cbcbc4-1322-4f70-b38d-ae5c5fa656e4_thumb.jpg	\N	0.001538	0	f	\N	\N	\N	\N	f	2026-02-02 18:30:34.780138
684	default	2026-02-02 18:30:35.454372	\N	/media/channels/18/thumbnails/58ae599c-715a-47da-9da1-cbbf90d2796b_thumb.jpg	\N	0.002605	0	f	\N	\N	\N	\N	f	2026-02-02 18:30:35.456988
685	default	2026-02-02 18:30:36.401028	\N	/media/channels/16/16/thumbnails/51015af6-0e47-4c3d-8181-667e75302b79_thumb.jpg	\N	0.000164	0	f	\N	\N	\N	\N	f	2026-02-02 18:30:36.4012
687	default	2026-02-02 18:31:57.089974	\N	/media/channels/16/thumbnails/8b31d2ac-84c0-479a-b6d1-9e6cdae21c44_thumb.jpg	\N	0.000308	0	f	\N	\N	\N	\N	f	2026-02-02 18:31:57.090286
677	default	2026-02-02 18:30:33.549584	\N	chat	chat	162.51112	0	f	\N	\N	\N	\N	f	2026-02-02 18:33:16.060717
331	default	2026-02-02 06:21:08.457544	\N	chat	getNotes	0.015776	1	f	\N	\N	\N	\N	f	2026-02-02 06:21:08.473322
349	default	2026-02-02 06:38:08.292113	\N	chat	getNotes	0.008244	1	f	\N	\N	\N	\N	f	2026-02-02 06:38:08.300358
340	default	2026-02-02 06:25:30.751507	\N	chat	getNotes	0.014532	1	f	\N	\N	\N	\N	f	2026-02-02 06:25:30.766041
456	default	2026-02-02 10:22:05.002927	\N	chat	chat	2245.03932	0	f	\N	\N	\N	\N	f	2026-02-02 10:59:30.04246
359	default	2026-02-02 06:40:43.994566	\N	chat	getNotes	0.008262	1	f	\N	\N	\N	\N	f	2026-02-02 06:40:44.002829
615	default	2026-02-02 18:05:59.921484	\N	/media/channels/18/thumbnails/58ae599c-715a-47da-9da1-cbbf90d2796b_thumb.jpg	\N	0.003073	0	f	\N	\N	\N	\N	f	2026-02-02 18:05:59.924574
371	default	2026-02-02 10:01:29.242991	\N	chat	getNotes	0.014232	1	f	\N	\N	\N	\N	f	2026-02-02 10:01:29.257225
468	default	2026-02-02 10:59:42.311323	\N	chat	getNotes	0.008888	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:42.320212
384	default	2026-02-02 10:02:31.288895	\N	chat	getNotes	0.022657	1	f	\N	\N	\N	\N	f	2026-02-02 10:02:31.311553
436	default	2026-02-02 10:17:05.194049	\N	chat	createNote	0.01085	3	f	\N	\N	\N	\N	f	2026-02-02 10:17:05.204909
483	default	2026-02-02 10:59:49.414832	\N	chat	getNotes	0.008746	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:49.423582
437	default	2026-02-02 10:18:22.595391	\N	chat	createNote	0.009079	3	f	\N	\N	\N	\N	f	2026-02-02 10:18:22.604482
640	default	2026-02-02 18:08:24.473796	\N	/media/channels/15/thumbnails/77cc9738-8a79-4773-9b06-94f8f66bcbc7_thumb.jpg	\N	0.009242	0	f	\N	\N	\N	\N	f	2026-02-02 18:08:24.483042
438	default	2026-02-02 10:18:29.582561	\N	chat	createNote	0.009785	3	f	\N	\N	\N	\N	f	2026-02-02 10:18:29.59235
489	default	2026-02-02 10:59:53.938186	\N	chat	getNotes	0.006368	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:53.944556
439	default	2026-02-02 10:18:34.838833	\N	chat	createNote	0.009567	3	f	\N	\N	\N	\N	f	2026-02-02 10:18:34.848404
440	default	2026-02-02 10:18:43.443021	\N	chat	createNote	0.010954	3	f	\N	\N	\N	\N	f	2026-02-02 10:18:43.45398
529	default	2026-02-02 17:33:37.71691	\N	InternalSession	\N	0.005272	1	f	\N	\N	\N	\N	f	2026-02-02 17:33:37.722212
441	default	2026-02-02 10:19:26.905866	\N	chat	createNote	0.016125	3	f	\N	\N	\N	\N	f	2026-02-02 10:19:26.922011
442	default	2026-02-02 10:19:34.827879	\N	chat	getChannels	0.003225	1	f	\N	\N	\N	\N	f	2026-02-02 10:19:34.831107
530	default	2026-02-02 17:37:14.767421	\N	chat	getChannels	0.006592	1	f	\N	\N	\N	\N	f	2026-02-02 17:37:14.774021
443	default	2026-02-02 10:19:34.861403	\N	chat	getNotes	0.004521	1	f	\N	\N	\N	\N	f	2026-02-02 10:19:34.865928
671	default	2026-02-02 18:20:43.210873	\N	chat	getNotes	0.03389	1	f	\N	\N	\N	\N	f	2026-02-02 18:20:43.244783
531	default	2026-02-02 17:37:14.836054	\N	chat	getNotes	0.006953	1	f	\N	\N	\N	\N	f	2026-02-02 17:37:14.843012
445	default	2026-02-02 10:19:35.117586	\N	chat	getNotes	0.009916	1	f	\N	\N	\N	\N	f	2026-02-02 10:19:35.127505
451	default	2026-02-02 10:19:39.183011	\N	chat	createNote	0.013627	3	f	\N	\N	\N	\N	f	2026-02-02 10:19:39.196641
533	default	2026-02-02 17:37:14.989747	\N	chat	getNotes	0.02054	1	f	\N	\N	\N	\N	f	2026-02-02 17:37:15.010306
452	default	2026-02-02 10:19:42.067943	\N	chat	createNote	0.012715	3	f	\N	\N	\N	\N	f	2026-02-02 10:19:42.080661
674	default	2026-02-02 18:20:44.676777	\N	/media/channels/16/thumbnails/8b31d2ac-84c0-479a-b6d1-9e6cdae21c44_thumb.jpg	\N	0.014872	0	f	\N	\N	\N	\N	f	2026-02-02 18:20:44.691658
535	default	2026-02-02 17:37:24.669519	\N	chat	createNote	0.019775	3	f	\N	\N	\N	\N	f	2026-02-02 17:37:24.689305
453	default	2026-02-02 10:20:38.699067	\N	chat	createNote	0.013008	3	f	\N	\N	\N	\N	f	2026-02-02 10:20:38.712094
555	default	2026-02-02 17:47:35.127381	\N	InternalSession	\N	0.005903	1	f	\N	\N	\N	\N	f	2026-02-02 17:47:35.133308
454	default	2026-02-02 10:22:04.923179	\N	chat	getChannels	0.008941	1	f	\N	\N	\N	\N	f	2026-02-02 10:22:04.932128
667	default	2026-02-02 18:20:40.976866	\N	chat	chat	142.756572	0	f	\N	\N	\N	\N	f	2026-02-02 18:23:03.733523
455	default	2026-02-02 10:22:04.950817	\N	chat	getNotes	0.00391	1	f	\N	\N	\N	\N	f	2026-02-02 10:22:04.954747
556	default	2026-02-02 17:47:41.086132	\N	chat	getChannels	0.007471	1	f	\N	\N	\N	\N	f	2026-02-02 17:47:41.093611
457	default	2026-02-02 10:22:05.187137	\N	chat	getNotes	0.022127	1	f	\N	\N	\N	\N	f	2026-02-02 10:22:05.209271
679	default	2026-02-02 18:30:33.609057	\N	chat	getNotes	0.012748	1	f	\N	\N	\N	\N	f	2026-02-02 18:30:33.621807
444	default	2026-02-02 10:19:34.916411	\N	chat	chat	154.76554	0	f	\N	\N	\N	\N	f	2026-02-02 10:22:09.681953
463	default	2026-02-02 10:22:09.666553	\N	chat	createNote	0.014754	3	f	\N	\N	\N	\N	f	2026-02-02 10:22:09.68131
557	default	2026-02-02 17:47:41.145034	\N	chat	getNotes	0.009461	1	f	\N	\N	\N	\N	f	2026-02-02 17:47:41.154518
464	default	2026-02-02 10:22:37.800245	\N	chat	createNote	0.015624	3	f	\N	\N	\N	\N	f	2026-02-02 10:22:37.815872
686	default	2026-02-02 18:30:36.400305	\N	/media/channels/16/thumbnails/8b31d2ac-84c0-479a-b6d1-9e6cdae21c44_thumb.jpg	\N	0.001488	0	f	\N	\N	\N	\N	f	2026-02-02 18:30:36.401795
559	default	2026-02-02 17:47:41.35579	\N	chat	getNotes	0.003701	1	f	\N	\N	\N	\N	f	2026-02-02 17:47:41.359496
560	default	2026-02-02 17:47:52.777205	\N	chat	createChannel	0.006006	1	f	\N	\N	\N	\N	f	2026-02-02 17:47:52.783221
694	default	2026-02-02 18:33:38.201047	\N	chat	getNotes	0.019017	1	f	\N	\N	\N	\N	f	2026-02-02 18:33:38.220068
561	default	2026-02-02 17:47:52.79662	\N	chat	getChannels	0.003454	1	f	\N	\N	\N	\N	f	2026-02-02 17:47:52.80008
562	default	2026-02-02 17:47:52.825329	\N	chat	getNotes	0.003069	1	f	\N	\N	\N	\N	f	2026-02-02 17:47:52.828401
705	default	2026-02-02 18:33:50.947624	\N	chat	getNotes	0.026793	1	f	\N	\N	\N	\N	f	2026-02-02 18:33:50.974418
563	default	2026-02-02 17:47:57.555138	\N	media	uploadMediaAndCreateNote	0.2199	4	f	\N	\N	\N	\N	f	2026-02-02 17:47:57.775042
564	default	2026-02-02 17:48:10.339449	\N	chat	createNote	0.010828	3	f	\N	\N	\N	\N	f	2026-02-02 17:48:10.350281
565	default	2026-02-02 17:49:33.378874	\N	media	channels	0.000691	0	f	\N	\N	\N	\N	f	2026-02-02 17:49:33.379571
566	default	2026-02-02 17:49:38.061517	\N	/media/channels/16/51015af6-0e47-4c3d-8181-667e75302b79.jpg	\N	0.013779	0	f	\N	\N	\N	\N	f	2026-02-02 17:49:38.075306
567	default	2026-02-02 17:50:27.688753	\N	/media/channels/16/5101	\N	0.000712	0	f	\N	\N	\N	\N	f	2026-02-02 17:50:27.689478
558	default	2026-02-02 17:47:41.222158	\N	chat	chat	176.510518	0	f	\N	\N	\N	\N	f	2026-02-02 17:50:37.732697
592	default	2026-02-02 17:59:58.599468	\N	chat	getChannels	0.003766	1	f	\N	\N	\N	\N	f	2026-02-02 17:59:58.603238
593	default	2026-02-02 17:59:58.670142	\N	chat	getNotes	0.002973	1	f	\N	\N	\N	\N	f	2026-02-02 17:59:58.673118
595	default	2026-02-02 17:59:58.824059	\N	chat	getNotes	0.006551	1	f	\N	\N	\N	\N	f	2026-02-02 17:59:58.830614
598	default	2026-02-02 18:00:08.126009	\N	media	uploadMediaAndCreateNote	0.149498	4	f	\N	\N	\N	\N	f	2026-02-02 18:00:08.275511
599	default	2026-02-02 18:00:39.916389	\N	chat	createNote	0.009092	3	f	\N	\N	\N	\N	f	2026-02-02 18:00:39.925499
600	default	2026-02-02 18:00:41.751098	\N	chat	createNote	0.007931	3	f	\N	\N	\N	\N	f	2026-02-02 18:00:41.759034
601	default	2026-02-02 18:01:48.108635	\N	media	uploadMediaAndCreateNote	0.154195	4	f	\N	\N	\N	\N	f	2026-02-02 18:01:48.262843
594	default	2026-02-02 17:59:58.771466	\N	chat	chat	249.717272	0	f	\N	\N	\N	\N	f	2026-02-02 18:04:08.488748
602	default	2026-02-02 18:04:35.415832	\N	chat	getChannels	0.002823	1	f	\N	\N	\N	\N	f	2026-02-02 18:04:35.418658
603	default	2026-02-02 18:04:35.493489	\N	chat	getNotes	0.002793	1	f	\N	\N	\N	\N	f	2026-02-02 18:04:35.496285
605	default	2026-02-02 18:04:35.644077	\N	chat	getNotes	0.00536	1	f	\N	\N	\N	\N	f	2026-02-02 18:04:35.649443
608	default	2026-02-02 18:04:48.41652	\N	chat	createChannel	0.005473	1	f	\N	\N	\N	\N	f	2026-02-02 18:04:48.422002
609	default	2026-02-02 18:04:48.451139	\N	chat	getChannels	0.003904	1	f	\N	\N	\N	\N	f	2026-02-02 18:04:48.455046
611	default	2026-02-02 18:04:55.75166	\N	media	uploadMediaAndCreateNote	0.148914	4	f	\N	\N	\N	\N	f	2026-02-02 18:04:55.900578
333	default	2026-02-02 06:21:08.458112	\N	chat	getNotes	0.015498	1	f	\N	\N	\N	\N	f	2026-02-02 06:21:08.473611
350	default	2026-02-02 06:38:08.290845	\N	chat	getNotes	0.009079	1	f	\N	\N	\N	\N	f	2026-02-02 06:38:08.299926
344	default	2026-02-02 06:25:30.752984	\N	chat	getNotes	0.012281	1	f	\N	\N	\N	\N	f	2026-02-02 06:25:30.765267
470	default	2026-02-02 10:59:42.307627	\N	chat	getNotes	0.011703	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:42.319331
358	default	2026-02-02 06:40:43.992305	\N	chat	getNotes	0.006831	1	f	\N	\N	\N	\N	f	2026-02-02 06:40:43.999284
372	default	2026-02-02 10:01:29.243394	\N	chat	getNotes	0.011982	1	f	\N	\N	\N	\N	f	2026-02-02 10:01:29.255387
616	default	2026-02-02 18:05:59.918263	\N	chat	getNotes	0.010448	1	f	\N	\N	\N	\N	f	2026-02-02 18:05:59.928718
383	default	2026-02-02 10:02:31.29043	\N	chat	getNotes	0.021321	1	f	\N	\N	\N	\N	f	2026-02-02 10:02:31.311752
481	default	2026-02-02 10:59:49.411223	\N	chat	getNotes	0.013789	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:49.425014
809	default	2026-02-02 18:46:55.916964	\N	chat	getChannels	0.006851	1	f	\N	\N	\N	\N	f	2026-02-02 18:46:55.923817
488	default	2026-02-02 10:59:53.93507	\N	chat	getNotes	0.011343	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:53.946415
619	default	2026-02-02 18:06:02.363247	\N	/media/channels/16/thumbnails/8b31d2ac-84c0-479a-b6d1-9e6cdae21c44_thumb.jpg	\N	0.002317	0	f	\N	\N	\N	\N	f	2026-02-02 18:06:02.365566
449	default	2026-02-02 10:19:35.119755	\N	chat	getNotes	0.014474	1	f	\N	\N	\N	\N	f	2026-02-02 10:19:35.134231
450	default	2026-02-02 10:19:35.120945	\N	chat	getNotes	0.012826	1	f	\N	\N	\N	\N	f	2026-02-02 10:19:35.133774
447	default	2026-02-02 10:19:35.122537	\N	chat	getNotes	0.012827	1	f	\N	\N	\N	\N	f	2026-02-02 10:19:35.135365
448	default	2026-02-02 10:19:35.121989	\N	chat	getNotes	0.01265	1	f	\N	\N	\N	\N	f	2026-02-02 10:19:35.134647
532	default	2026-02-02 17:37:14.999121	\N	chat	chat	\N	\N	\N	\N	\N	\N	\N	f	2026-02-02 17:38:00.040482
622	default	2026-02-02 18:06:03.075423	\N	/media/channels/15/thumbnails/77cc9738-8a79-4773-9b06-94f8f66bcbc7_thumb.jpg	\N	0.001159	0	f	\N	\N	\N	\N	f	2026-02-02 18:06:03.076585
568	default	2026-02-02 17:50:45.60209	\N	InternalSession	\N	0.005678	1	f	\N	\N	\N	\N	f	2026-02-02 17:50:45.607792
458	default	2026-02-02 10:22:05.191167	\N	chat	getNotes	0.021118	1	f	\N	\N	\N	\N	f	2026-02-02 10:22:05.212285
460	default	2026-02-02 10:22:05.190833	\N	chat	getNotes	0.02085	1	f	\N	\N	\N	\N	f	2026-02-02 10:22:05.211685
462	default	2026-02-02 10:22:05.18855	\N	chat	getNotes	0.024025	1	f	\N	\N	\N	\N	f	2026-02-02 10:22:05.212576
459	default	2026-02-02 10:22:05.189972	\N	chat	getNotes	0.02211	1	f	\N	\N	\N	\N	f	2026-02-02 10:22:05.212084
569	default	2026-02-02 17:50:51.990539	\N	/v1/websocket	\N	0.00148	0	f	\N	\N	\N	\N	f	2026-02-02 17:50:51.99203
828	default	2026-02-02 18:47:43.231799	\N	chat	createNote	0.008034	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:43.239837
570	default	2026-02-02 17:51:14.250577	\N	/v1/websocket	\N	0.000213	0	f	\N	\N	\N	\N	f	2026-02-02 17:51:14.250795
629	default	2026-02-02 18:07:58.903091	\N	chat	chat	9.09403	0	f	\N	\N	\N	\N	f	2026-02-02 18:08:07.997123
571	default	2026-02-02 17:51:16.791969	\N	/v1/websocket	\N	0.000216	0	f	\N	\N	\N	\N	f	2026-02-02 17:51:16.792192
596	default	2026-02-02 17:59:58.825666	\N	chat	getNotes	0.006947	1	f	\N	\N	\N	\N	f	2026-02-02 17:59:58.83262
651	default	2026-02-02 18:09:01.066528	\N	chat	getChannels	0.00307	1	f	\N	\N	\N	\N	f	2026-02-02 18:09:01.069601
607	default	2026-02-02 18:04:35.645392	\N	chat	getNotes	0.00667	1	f	\N	\N	\N	\N	f	2026-02-02 18:04:35.652064
829	default	2026-02-02 18:47:43.644467	\N	chat	createNote	0.007662	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:43.652133
652	default	2026-02-02 18:09:01.142445	\N	chat	getNotes	0.003285	1	f	\N	\N	\N	\N	f	2026-02-02 18:09:01.145733
653	default	2026-02-02 18:09:01.287928	\N	chat	getNotes	0.005617	1	f	\N	\N	\N	\N	f	2026-02-02 18:09:01.293552
830	default	2026-02-02 18:47:44.295101	\N	chat	createNote	0.0101	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:44.305205
659	default	2026-02-02 18:09:02.784019	\N	/media/channels/19/thumbnails/69cbcbc4-1322-4f70-b38d-ae5c5fa656e4_thumb.jpg	\N	0.000399	0	f	\N	\N	\N	\N	f	2026-02-02 18:09:02.784424
660	default	2026-02-02 18:09:03.46453	\N	/media/channels/18/thumbnails/58ae599c-715a-47da-9da1-cbbf90d2796b_thumb.jpg	\N	0.002506	0	f	\N	\N	\N	\N	f	2026-02-02 18:09:03.467044
801	default	2026-02-02 18:46:25.348838	\N	chat	chat	309.819283	0	f	\N	\N	\N	\N	f	2026-02-02 18:51:35.168136
661	default	2026-02-02 18:09:04.609302	\N	/media/channels/18/58ae599c-715a-47da-9da1-cbbf90d2796b.jpg	\N	0.003182	0	f	\N	\N	\N	\N	f	2026-02-02 18:09:04.612491
662	default	2026-02-02 18:09:25.61506	\N	/media/channels/18/58ae599c-715a-47da-9da1-cbbf90d2796b.jpg	\N	0.000342	0	f	\N	\N	\N	\N	f	2026-02-02 18:09:25.615409
842	default	2026-02-03 06:36:59.856476	\N	chat	getNotes	0.011079	1	f	\N	\N	\N	\N	f	2026-02-03 06:36:59.867566
669	default	2026-02-02 18:20:43.215743	\N	chat	getNotes	0.019797	1	f	\N	\N	\N	\N	f	2026-02-02 18:20:43.235549
682	default	2026-02-02 18:30:33.609495	\N	chat	getNotes	0.01347	1	f	\N	\N	\N	\N	f	2026-02-02 18:30:33.623
695	default	2026-02-02 18:33:38.198427	\N	chat	getNotes	0.022819	1	f	\N	\N	\N	\N	f	2026-02-02 18:33:38.221258
704	default	2026-02-02 18:33:50.946338	\N	chat	getNotes	0.027493	1	f	\N	\N	\N	\N	f	2026-02-02 18:33:50.973834
708	default	2026-02-02 18:33:51.855416	\N	/media/channels/19/thumbnails/69cbcbc4-1322-4f70-b38d-ae5c5fa656e4_thumb.jpg	\N	0.00152	0	f	\N	\N	\N	\N	f	2026-02-02 18:33:51.856938
719	default	2026-02-02 18:37:38.013209	\N	chat	getNotes	0.027669	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:38.040888
727	default	2026-02-02 18:37:41.644973	\N	chat	getNotes	0.011395	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:41.65637
780	default	2026-02-02 18:45:21.098482	\N	InternalSession	\N	0.004833	1	f	\N	\N	\N	\N	f	2026-02-02 18:45:21.10334
781	default	2026-02-02 18:45:28.259105	\N	chat	getChannels	0.007997	1	f	\N	\N	\N	\N	f	2026-02-02 18:45:28.267109
782	default	2026-02-02 18:45:28.311737	\N	chat	getNotes	0.01816	1	f	\N	\N	\N	\N	f	2026-02-02 18:45:28.329902
785	default	2026-02-02 18:45:29.506568	\N	chat	getNotes	0.013036	1	f	\N	\N	\N	\N	f	2026-02-02 18:45:29.519613
787	default	2026-02-02 18:45:40.314506	\N	chat	deleteChannel	0.013168	2	f	\N	\N	\N	\N	f	2026-02-02 18:45:40.32768
788	default	2026-02-02 18:45:40.343193	\N	chat	getChannels	0.004721	1	f	\N	\N	\N	\N	f	2026-02-02 18:45:40.347922
789	default	2026-02-02 18:45:41.933017	\N	chat	deleteChannel	0.009432	2	f	\N	\N	\N	\N	f	2026-02-02 18:45:41.942454
790	default	2026-02-02 18:45:41.956672	\N	chat	getChannels	0.028478	1	f	\N	\N	\N	\N	f	2026-02-02 18:45:41.985158
791	default	2026-02-02 18:46:03.311766	\N	chat	getChannels	0.023246	1	f	\N	\N	\N	\N	f	2026-02-02 18:46:03.335019
792	default	2026-02-02 18:46:03.39503	\N	chat	getNotes	0.017294	1	f	\N	\N	\N	\N	f	2026-02-02 18:46:03.412329
794	default	2026-02-02 18:46:03.937431	\N	chat	getNotes	0.017314	1	f	\N	\N	\N	\N	f	2026-02-02 18:46:03.954804
795	default	2026-02-02 18:46:04.432401	\N	chat	getChannels	0.003596	1	f	\N	\N	\N	\N	f	2026-02-02 18:46:04.436001
796	default	2026-02-02 18:46:04.489045	\N	chat	getNotes	0.00345	1	f	\N	\N	\N	\N	f	2026-02-02 18:46:04.492499
798	default	2026-02-02 18:46:04.671853	\N	chat	getNotes	0.006058	1	f	\N	\N	\N	\N	f	2026-02-02 18:46:04.677916
799	default	2026-02-02 18:46:25.183946	\N	chat	getChannels	0.002554	1	f	\N	\N	\N	\N	f	2026-02-02 18:46:25.186503
800	default	2026-02-02 18:46:25.252509	\N	chat	getNotes	0.003251	1	f	\N	\N	\N	\N	f	2026-02-02 18:46:25.255763
802	default	2026-02-02 18:46:25.392267	\N	chat	getNotes	0.006345	1	f	\N	\N	\N	\N	f	2026-02-02 18:46:25.398616
803	default	2026-02-02 18:46:46.342526	\N	chat	getChannels	0.004199	1	f	\N	\N	\N	\N	f	2026-02-02 18:46:46.34673
804	default	2026-02-02 18:46:46.396248	\N	chat	getNotes	0.00518	1	f	\N	\N	\N	\N	f	2026-02-02 18:46:46.401435
806	default	2026-02-02 18:46:46.506868	\N	chat	getNotes	0.012781	1	f	\N	\N	\N	\N	f	2026-02-02 18:46:46.519658
797	default	2026-02-02 18:46:04.642008	\N	chat	chat	46.157899	0	f	\N	\N	\N	\N	f	2026-02-02 18:46:50.800056
334	default	2026-02-02 06:21:08.461588	\N	chat	getNotes	0.012169	1	f	\N	\N	\N	\N	f	2026-02-02 06:21:08.473757
351	default	2026-02-02 06:38:08.292817	\N	chat	getNotes	0.010206	1	f	\N	\N	\N	\N	f	2026-02-02 06:38:08.303025
343	default	2026-02-02 06:25:30.754396	\N	chat	getNotes	0.010377	1	f	\N	\N	\N	\N	f	2026-02-02 06:25:30.764778
472	default	2026-02-02 10:59:42.308858	\N	chat	getNotes	0.013501	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:42.322361
361	default	2026-02-02 06:40:43.995165	\N	chat	getNotes	0.007107	1	f	\N	\N	\N	\N	f	2026-02-02 06:40:44.002273
618	default	2026-02-02 18:05:59.919148	\N	chat	getNotes	0.01348	1	f	\N	\N	\N	\N	f	2026-02-02 18:05:59.932636
387	default	2026-02-02 10:03:37.699517	\N	chat	getChannels	0.00625	1	f	\N	\N	\N	\N	f	2026-02-02 10:03:37.705784
478	default	2026-02-02 10:59:49.414225	\N	chat	getNotes	0.006929	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:49.421155
388	default	2026-02-02 10:03:37.730701	\N	chat	getNotes	0.00315	1	f	\N	\N	\N	\N	f	2026-02-02 10:03:37.733855
492	default	2026-02-02 10:59:53.937651	\N	chat	getNotes	0.0064	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:53.944056
390	default	2026-02-02 10:03:37.919343	\N	chat	getNotes	0.011955	1	f	\N	\N	\N	\N	f	2026-02-02 10:03:37.931303
389	default	2026-02-02 10:03:37.78908	\N	chat	chat	202.138944	0	f	\N	\N	\N	\N	f	2026-02-02 10:06:59.928126
534	default	2026-02-02 17:37:14.991543	\N	chat	getNotes	0.019599	1	f	\N	\N	\N	\N	f	2026-02-02 17:37:15.011144
396	default	2026-02-02 10:07:11.141537	\N	chat	getChannels	0.011335	1	f	\N	\N	\N	\N	f	2026-02-02 10:07:11.152892
656	default	2026-02-02 18:09:01.289593	\N	chat	getNotes	0.006039	1	f	\N	\N	\N	\N	f	2026-02-02 18:09:01.295635
397	default	2026-02-02 10:07:11.255333	\N	chat	getNotes	0.006863	1	f	\N	\N	\N	\N	f	2026-02-02 10:07:11.262203
572	default	2026-02-02 17:51:28.572469	\N	InternalSession	\N	0.005363	1	f	\N	\N	\N	\N	f	2026-02-02 17:51:28.577858
402	default	2026-02-02 10:07:36.497071	\N	chat	getNotes	0.015377	1	f	\N	\N	\N	\N	f	2026-02-02 10:07:36.512453
573	default	2026-02-02 17:51:32.55499	\N	/v1/websocket	\N	0.001266	0	f	\N	\N	\N	\N	f	2026-02-02 17:51:32.556265
405	default	2026-02-02 10:07:36.545663	\N	chat	getNotes	0.008217	1	f	\N	\N	\N	\N	f	2026-02-02 10:07:36.553883
654	default	2026-02-02 18:09:01.294519	\N	chat	chat	131.334138	0	f	\N	\N	\N	\N	f	2026-02-02 18:11:12.628697
406	default	2026-02-02 10:07:40.776772	\N	chat	createNote	0.015838	3	f	\N	\N	\N	\N	f	2026-02-02 10:07:40.792616
597	default	2026-02-02 17:59:58.825166	\N	chat	getNotes	0.008509	1	f	\N	\N	\N	\N	f	2026-02-02 17:59:58.833679
407	default	2026-02-02 10:08:39.520775	\N	chat	createNote	0.012557	3	f	\N	\N	\N	\N	f	2026-02-02 10:08:39.533338
606	default	2026-02-02 18:04:35.644817	\N	chat	getNotes	0.005538	1	f	\N	\N	\N	\N	f	2026-02-02 18:04:35.650357
408	default	2026-02-02 10:08:53.93925	\N	chat	createNote	0.012644	3	f	\N	\N	\N	\N	f	2026-02-02 10:08:53.951902
670	default	2026-02-02 18:20:43.2178	\N	chat	getNotes	0.018972	1	f	\N	\N	\N	\N	f	2026-02-02 18:20:43.236783
610	default	2026-02-02 18:04:48.451932	\N	chat	getNotes	0.00273	1	f	\N	\N	\N	\N	f	2026-02-02 18:04:48.454665
410	default	2026-02-02 10:09:07.750554	\N	chat	getChannels	0.00507	1	f	\N	\N	\N	\N	f	2026-02-02 10:09:07.755627
411	default	2026-02-02 10:09:07.795695	\N	chat	getNotes	0.003861	1	f	\N	\N	\N	\N	f	2026-02-02 10:09:07.799558
398	default	2026-02-02 10:07:11.370645	\N	chat	chat	119.605575	0	f	\N	\N	\N	\N	f	2026-02-02 10:09:10.976244
681	default	2026-02-02 18:30:33.610033	\N	chat	getNotes	0.012209	1	f	\N	\N	\N	\N	f	2026-02-02 18:30:33.622244
417	default	2026-02-02 10:09:25.774249	\N	chat	getNotes	0.018796	1	f	\N	\N	\N	\N	f	2026-02-02 10:09:25.793049
419	default	2026-02-02 10:09:27.480531	\N	chat	createNote	0.01387	3	f	\N	\N	\N	\N	f	2026-02-02 10:09:27.49441
696	default	2026-02-02 18:33:38.198949	\N	chat	getNotes	0.019948	1	f	\N	\N	\N	\N	f	2026-02-02 18:33:38.218901
420	default	2026-02-02 10:09:56.587366	\N	chat	createChannel	0.005218	1	f	\N	\N	\N	\N	f	2026-02-02 10:09:56.592589
421	default	2026-02-02 10:09:56.608484	\N	chat	getChannels	0.00332	1	f	\N	\N	\N	\N	f	2026-02-02 10:09:56.611808
706	default	2026-02-02 18:33:50.94704	\N	chat	getNotes	0.023898	1	f	\N	\N	\N	\N	f	2026-02-02 18:33:50.97098
422	default	2026-02-02 10:09:56.638487	\N	chat	getNotes	0.003691	1	f	\N	\N	\N	\N	f	2026-02-02 10:09:56.64218
423	default	2026-02-02 10:09:59.529153	\N	chat	deleteChannel	0.010505	2	f	\N	\N	\N	\N	f	2026-02-02 10:09:59.539685
750	default	2026-02-02 18:38:07.588932	\N	chat	getNotes	0.004507	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:07.593443
424	default	2026-02-02 10:09:59.556959	\N	chat	getChannels	0.00349	1	f	\N	\N	\N	\N	f	2026-02-02 10:09:59.560452
425	default	2026-02-02 10:15:58.906856	\N	chat	createNote	0.022445	3	f	\N	\N	\N	\N	f	2026-02-02 10:15:58.929323
751	default	2026-02-02 18:38:07.60566	\N	chat	getNotes	0.005656	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:07.611322
426	default	2026-02-02 10:16:25.342329	\N	chat	getChannels	0.003711	1	f	\N	\N	\N	\N	f	2026-02-02 10:16:25.346046
427	default	2026-02-02 10:16:25.422103	\N	chat	getNotes	0.002983	1	f	\N	\N	\N	\N	f	2026-02-02 10:16:25.425089
752	default	2026-02-02 18:38:33.094152	\N	chat	getChannels	0.003894	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:33.098051
429	default	2026-02-02 10:16:48.832747	\N	chat	getNotes	0.031698	1	f	\N	\N	\N	\N	f	2026-02-02 10:16:48.864461
754	default	2026-02-02 18:38:33.129905	\N	chat	getNotes	0.004541	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:33.134449
435	default	2026-02-02 10:16:48.988993	\N	chat	getNotes	0.00489	1	f	\N	\N	\N	\N	f	2026-02-02 10:16:48.993888
755	default	2026-02-02 18:38:33.851825	\N	chat	getNotes	0.04114	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:33.89297
756	default	2026-02-02 18:38:37.235443	\N	chat	createChannel	0.003936	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:37.239384
446	default	2026-02-02 10:19:35.121585	\N	chat	getNotes	0.013563	1	f	\N	\N	\N	\N	f	2026-02-02 10:19:35.13515
428	default	2026-02-02 10:16:25.431887	\N	chat	chat	193.019056	0	f	\N	\N	\N	\N	f	2026-02-02 10:19:38.45097
461	default	2026-02-02 10:22:05.190469	\N	chat	getNotes	0.021969	1	f	\N	\N	\N	\N	f	2026-02-02 10:22:05.212438
758	default	2026-02-02 18:38:37.25289	\N	chat	getChannels	0.004898	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:37.257794
759	default	2026-02-02 18:38:37.281015	\N	chat	getNotes	0.005717	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:37.286735
761	default	2026-02-02 18:38:44.97327	\N	media	uploadMediaAndCreateNote	0.258091	4	f	\N	\N	\N	\N	f	2026-02-02 18:38:45.231367
762	default	2026-02-02 18:38:45.270224	\N	/media/channels/21/thumbnails/489a3437-b2eb-4153-9158-186980baec2b_thumb.jpg	\N	0.002085	0	f	\N	\N	\N	\N	f	2026-02-02 18:38:45.272317
763	default	2026-02-02 18:38:52.705341	\N	chat	deleteChannel	0.007338	2	f	\N	\N	\N	\N	f	2026-02-02 18:38:52.712685
764	default	2026-02-02 18:38:52.722971	\N	chat	getChannels	0.003859	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:52.726836
766	default	2026-02-02 18:38:56.471799	\N	chat	createChannel	0.004349	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:56.476154
767	default	2026-02-02 18:38:56.484981	\N	chat	getChannels	0.003015	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:56.488013
769	default	2026-02-02 18:38:56.509347	\N	chat	getNotes	0.002961	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:56.512312
770	default	2026-02-02 18:38:56.519288	\N	chat	getNotes	0.005147	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:56.524441
771	default	2026-02-02 18:39:01.204104	\N	media	uploadMediaAndCreateNote	0.294741	4	f	\N	\N	\N	\N	f	2026-02-02 18:39:01.498848
772	default	2026-02-02 18:39:01.529417	\N	/media/channels/22/thumbnails/deaa9dd4-6bc3-45a0-a9aa-90e20c07e8fb_thumb.jpg	\N	0.001789	0	f	\N	\N	\N	\N	f	2026-02-02 18:39:01.531219
773	default	2026-02-02 18:39:08.776366	\N	chat	deleteNote	0.008173	2	f	\N	\N	\N	\N	f	2026-02-02 18:39:08.784548
774	default	2026-02-02 18:39:14.05171	\N	chat	deleteNote	0.006418	2	f	\N	\N	\N	\N	f	2026-02-02 18:39:14.058155
753	default	2026-02-02 18:38:33.133545	\N	chat	chat	47.964769	0	f	\N	\N	\N	\N	f	2026-02-02 18:39:21.098352
714	default	2026-02-02 18:37:36.691675	\N	chat	chat	459.119471	0	f	\N	\N	\N	\N	f	2026-02-02 18:45:15.811179
352	default	2026-02-02 06:38:08.291684	\N	chat	getNotes	0.011983	1	f	\N	\N	\N	\N	f	2026-02-02 06:38:08.303669
471	default	2026-02-02 10:59:42.308415	\N	chat	getNotes	0.013051	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:42.321469
360	default	2026-02-02 06:40:43.994107	\N	chat	getNotes	0.007922	1	f	\N	\N	\N	\N	f	2026-02-02 06:40:44.002032
391	default	2026-02-02 10:03:37.923494	\N	chat	getNotes	0.014266	1	f	\N	\N	\N	\N	f	2026-02-02 10:03:37.937763
482	default	2026-02-02 10:59:49.413539	\N	chat	getNotes	0.01112	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:49.42466
401	default	2026-02-02 10:07:36.506305	\N	chat	getNotes	0.006637	1	f	\N	\N	\N	\N	f	2026-02-02 10:07:36.512944
418	default	2026-02-02 10:09:25.783	\N	chat	getNotes	0.009089	1	f	\N	\N	\N	\N	f	2026-02-02 10:09:25.792102
490	default	2026-02-02 10:59:53.937156	\N	chat	getNotes	0.008805	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:53.945963
432	default	2026-02-02 10:16:48.845817	\N	chat	getNotes	0.100819	1	f	\N	\N	\N	\N	f	2026-02-02 10:16:48.946637
604	default	2026-02-02 18:04:35.646228	\N	chat	chat	212.349993	0	f	\N	\N	\N	\N	f	2026-02-02 18:08:07.99623
536	default	2026-02-02 17:38:23.632007	\N	media	uploadMediaAndCreateNote	0.079734	0	f	Exception: User must be signed in to upload media	#0      MediaEndpoint.uploadMediaAndCreateNote (package:on_air_server/src/media/media_endpoint.dart:56:7)\n<asynchronous suspension>\n#1      Server._handleEndpointCall (package:serverpod/src/server/server.dart:444:22)\n<asynchronous suspension>\n#2      Server._endpoints (package:serverpod/src/server/server.dart:311:12)\n<asynchronous suspension>\n#3      Server._reportException.<anonymous closure> (package:serverpod/src/server/server.dart:205:16)\n<asynchronous suspension>\n#4      Server._headers.<anonymous closure> (package:serverpod/src/server/server.dart:286:22)\n<asynchronous suspension>\n#5      _RoutingMiddlewareBuilder.call.<anonymous closure> (package:relic/src/middleware/routing_middleware.dart:121:18)\n<asynchronous suspension>\n#6      _RelicServer._wrapHandlerWithMiddleware.<anonymous closure> (package:relic/src/relic_server.dart:151:24)\n<asynchronous suspension>\n#7      _RelicServer._handleRequest (package:relic/src/relic_server.dart:127:22)\n<asynchronous suspension>\n	\N	\N	f	2026-02-02 17:38:23.711755
574	default	2026-02-02 17:55:49.396625	\N	InternalSession	\N	0.006782	1	f	\N	\N	\N	\N	f	2026-02-02 17:55:49.403437
630	default	2026-02-02 18:08:13.676564	\N	InternalSession	\N	0.005274	1	f	\N	\N	\N	\N	f	2026-02-02 18:08:13.681869
575	default	2026-02-02 17:56:01.418349	\N	chat	getChannels	0.005745	1	f	\N	\N	\N	\N	f	2026-02-02 17:56:01.424101
576	default	2026-02-02 17:56:01.482196	\N	chat	getNotes	0.004698	1	f	\N	\N	\N	\N	f	2026-02-02 17:56:01.4869
631	default	2026-02-02 18:08:20.071656	\N	chat	getNotes	0.028579	1	f	\N	\N	\N	\N	f	2026-02-02 18:08:20.100248
578	default	2026-02-02 17:56:01.627574	\N	chat	getNotes	0.015567	1	f	\N	\N	\N	\N	f	2026-02-02 17:56:01.643151
581	default	2026-02-02 17:56:16.752112	\N	media	uploadMediaAndCreateNote	0.263467	4	f	\N	\N	\N	\N	f	2026-02-02 17:56:17.015583
636	default	2026-02-02 18:08:24.054894	\N	chat	getChannels	0.006156	1	f	\N	\N	\N	\N	f	2026-02-02 18:08:24.061055
582	default	2026-02-02 17:56:20.755233	\N	chat	createNote	0.013081	3	f	\N	\N	\N	\N	f	2026-02-02 17:56:20.768319
583	default	2026-02-02 17:56:30.803772	\N	chat	createChannel	0.00535	1	f	\N	\N	\N	\N	f	2026-02-02 17:56:30.809128
637	default	2026-02-02 18:08:24.091713	\N	chat	getNotes	0.005226	1	f	\N	\N	\N	\N	f	2026-02-02 18:08:24.09695
584	default	2026-02-02 17:56:30.82362	\N	chat	getChannels	0.003929	1	f	\N	\N	\N	\N	f	2026-02-02 17:56:30.827553
585	default	2026-02-02 17:56:30.847815	\N	chat	getNotes	0.003445	1	f	\N	\N	\N	\N	f	2026-02-02 17:56:30.851263
641	default	2026-02-02 18:08:24.471608	\N	chat	getNotes	0.017219	1	f	\N	\N	\N	\N	f	2026-02-02 18:08:24.488832
586	default	2026-02-02 17:56:37.247925	\N	media	uploadMediaAndCreateNote	0.138686	4	f	\N	\N	\N	\N	f	2026-02-02 17:56:37.386615
587	default	2026-02-02 17:56:39.640838	\N	chat	createNote	0.009976	3	f	\N	\N	\N	\N	f	2026-02-02 17:56:39.650818
644	default	2026-02-02 18:08:31.456542	\N	/media/channels/16/16/thumbnails/51015af6-0e47-4c3d-8181-667e75302b79_thumb.jpg	\N	0.000539	0	f	\N	\N	\N	\N	f	2026-02-02 18:08:31.457086
646	default	2026-02-02 18:08:35.285829	\N	chat	createChannel	0.006689	1	f	\N	\N	\N	\N	f	2026-02-02 18:08:35.292525
647	default	2026-02-02 18:08:35.305765	\N	chat	getChannels	0.002992	1	f	\N	\N	\N	\N	f	2026-02-02 18:08:35.308761
648	default	2026-02-02 18:08:35.333299	\N	chat	getNotes	0.003018	1	f	\N	\N	\N	\N	f	2026-02-02 18:08:35.336321
649	default	2026-02-02 18:08:38.742234	\N	media	uploadMediaAndCreateNote	0.262803	4	f	\N	\N	\N	\N	f	2026-02-02 18:08:39.005041
650	default	2026-02-02 18:08:39.040968	\N	/media/channels/19/thumbnails/69cbcbc4-1322-4f70-b38d-ae5c5fa656e4_thumb.jpg	\N	0.001285	0	f	\N	\N	\N	\N	f	2026-02-02 18:08:39.04226
655	default	2026-02-02 18:09:01.289177	\N	chat	getNotes	0.007345	1	f	\N	\N	\N	\N	f	2026-02-02 18:09:01.296525
672	default	2026-02-02 18:20:43.219148	\N	chat	getNotes	0.020336	1	f	\N	\N	\N	\N	f	2026-02-02 18:20:43.239501
680	default	2026-02-02 18:30:33.610562	\N	chat	getNotes	0.010802	1	f	\N	\N	\N	\N	f	2026-02-02 18:30:33.621368
712	default	2026-02-02 18:36:48.057958	\N	InternalSession	\N	0.004868	1	f	\N	\N	\N	\N	f	2026-02-02 18:36:48.062851
713	default	2026-02-02 18:37:36.59103	\N	chat	getChannels	0.008022	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:36.599059
715	default	2026-02-02 18:37:36.677236	\N	chat	getNotes	0.01848	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:36.69572
716	default	2026-02-02 18:37:38.005909	\N	chat	getNotes	0.018666	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:38.024584
721	default	2026-02-02 18:37:41.487078	\N	chat	getChannels	0.005117	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:41.492203
722	default	2026-02-02 18:37:41.539756	\N	chat	getNotes	0.003673	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:41.543433
724	default	2026-02-02 18:37:41.642483	\N	chat	getNotes	0.007967	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:41.650455
729	default	2026-02-02 18:37:42.332618	\N	/media/channels/18/thumbnails/58ae599c-715a-47da-9da1-cbbf90d2796b_thumb.jpg	\N	0.013015	0	f	\N	\N	\N	\N	f	2026-02-02 18:37:42.345643
731	default	2026-02-02 18:37:45.446482	\N	/media/channels/19/thumbnails/69cbcbc4-1322-4f70-b38d-ae5c5fa656e4_thumb.jpg	\N	0.002851	0	f	\N	\N	\N	\N	f	2026-02-02 18:37:45.44934
732	default	2026-02-02 18:37:46.637772	\N	chat	deleteChannel	0.011898	2	f	\N	\N	\N	\N	f	2026-02-02 18:37:46.649682
733	default	2026-02-02 18:37:46.666558	\N	chat	getChannels	0.00734	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:46.6739
735	default	2026-02-02 18:37:48.554608	\N	chat	deleteChannel	0.009903	2	f	\N	\N	\N	\N	f	2026-02-02 18:37:48.564521
736	default	2026-02-02 18:37:48.580033	\N	chat	getChannels	0.029254	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:48.609291
739	default	2026-02-02 18:37:49.185203	\N	/media/channels/15/thumbnails/3578d03d-70c7-4e4c-96e0-6e2b319075ec_thumb.jpg	\N	0.002692	0	f	\N	\N	\N	\N	f	2026-02-02 18:37:49.187903
740	default	2026-02-02 18:37:50.514609	\N	chat	deleteChannel	0.015698	2	f	\N	\N	\N	\N	f	2026-02-02 18:37:50.530312
743	default	2026-02-02 18:37:51.147592	\N	/media/channels/16/thumbnails/8b31d2ac-84c0-479a-b6d1-9e6cdae21c44_thumb.jpg	\N	0.001674	0	f	\N	\N	\N	\N	f	2026-02-02 18:37:51.149276
744	default	2026-02-02 18:37:52.742545	\N	chat	deleteChannel	0.009452	2	f	\N	\N	\N	\N	f	2026-02-02 18:37:52.752002
746	default	2026-02-02 18:37:52.764767	\N	chat	getChannels	0.00647	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:52.77124
747	default	2026-02-02 18:38:07.551287	\N	chat	createChannel	0.005835	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:07.557129
748	default	2026-02-02 18:38:07.56459	\N	chat	getChannels	0.002547	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:07.567141
749	default	2026-02-02 18:38:07.575045	\N	chat	getChannels	0.005794	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:07.580844
723	default	2026-02-02 18:37:41.594457	\N	chat	chat	55.646829	0	f	\N	\N	\N	\N	f	2026-02-02 18:38:37.241317
808	default	2026-02-02 18:46:55.915307	\N	chat	getChannels	0.007498	1	f	\N	\N	\N	\N	f	2026-02-02 18:46:55.922807
335	default	2026-02-02 06:21:08.459066	\N	chat	getNotes	0.015033	1	f	\N	\N	\N	\N	f	2026-02-02 06:21:08.474099
353	default	2026-02-02 06:38:08.292525	\N	chat	getNotes	0.010838	1	f	\N	\N	\N	\N	f	2026-02-02 06:38:08.303364
341	default	2026-02-02 06:25:30.753798	\N	chat	getNotes	0.012014	1	f	\N	\N	\N	\N	f	2026-02-02 06:25:30.765813
473	default	2026-02-02 10:59:42.309644	\N	chat	getNotes	0.013296	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:42.322943
362	default	2026-02-02 06:40:43.994932	\N	chat	getNotes	0.007562	1	f	\N	\N	\N	\N	f	2026-02-02 06:40:44.0025
632	default	2026-02-02 18:08:20.076677	\N	/media/channels/15/thumbnails/3578d03d-70c7-4e4c-96e0-6e2b319075ec_thumb.jpg	\N	0.029792	0	f	\N	\N	\N	\N	f	2026-02-02 18:08:20.106479
392	default	2026-02-02 10:03:37.921569	\N	chat	getNotes	0.01885	1	f	\N	\N	\N	\N	f	2026-02-02 10:03:37.94042
480	default	2026-02-02 10:59:49.414595	\N	chat	getNotes	0.009695	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:49.424292
404	default	2026-02-02 10:07:36.50532	\N	chat	getNotes	0.009629	1	f	\N	\N	\N	\N	f	2026-02-02 10:07:36.514951
416	default	2026-02-02 10:09:25.781839	\N	chat	getNotes	0.012188	1	f	\N	\N	\N	\N	f	2026-02-02 10:09:25.794029
493	default	2026-02-02 10:59:53.937941	\N	chat	getNotes	0.008694	1	f	\N	\N	\N	\N	f	2026-02-02 10:59:53.946636
433	default	2026-02-02 10:16:48.839963	\N	chat	getNotes	0.092949	1	f	\N	\N	\N	\N	f	2026-02-02 10:16:48.932928
639	default	2026-02-02 18:08:24.473217	\N	/media/channels/15/thumbnails/3578d03d-70c7-4e4c-96e0-6e2b319075ec_thumb.jpg	\N	0.009351	0	f	\N	\N	\N	\N	f	2026-02-02 18:08:24.482577
537	default	2026-02-02 17:39:04.685617	\N	InternalSession	\N	0.007317	1	f	\N	\N	\N	\N	f	2026-02-02 17:39:04.692964
538	default	2026-02-02 17:39:12.126902	\N	chat	getChannels	0.008128	1	f	\N	\N	\N	\N	f	2026-02-02 17:39:12.135038
657	default	2026-02-02 18:09:01.290299	\N	chat	getNotes	0.00716	1	f	\N	\N	\N	\N	f	2026-02-02 18:09:01.297461
539	default	2026-02-02 17:39:12.164927	\N	chat	getNotes	0.014754	1	f	\N	\N	\N	\N	f	2026-02-02 17:39:12.179692
688	default	2026-02-02 18:33:22.011063	\N	InternalSession	\N	0.004967	1	f	\N	\N	\N	\N	f	2026-02-02 18:33:22.016057
541	default	2026-02-02 17:39:14.26172	\N	chat	getNotes	0.005772	1	f	\N	\N	\N	\N	f	2026-02-02 17:39:14.267496
542	default	2026-02-02 17:39:18.014108	\N	media	uploadMediaAndCreateNote	0.083689	0	f	Exception: User must be signed in to upload media	#0      MediaEndpoint.uploadMediaAndCreateNote (package:on_air_server/src/media/media_endpoint.dart:56:7)\n<asynchronous suspension>\n#1      Server._handleEndpointCall (package:serverpod/src/server/server.dart:444:22)\n<asynchronous suspension>\n#2      Server._endpoints (package:serverpod/src/server/server.dart:311:12)\n<asynchronous suspension>\n#3      Server._reportException.<anonymous closure> (package:serverpod/src/server/server.dart:205:16)\n<asynchronous suspension>\n#4      Server._headers.<anonymous closure> (package:serverpod/src/server/server.dart:286:22)\n<asynchronous suspension>\n#5      _RoutingMiddlewareBuilder.call.<anonymous closure> (package:relic/src/middleware/routing_middleware.dart:121:18)\n<asynchronous suspension>\n#6      _RelicServer._wrapHandlerWithMiddleware.<anonymous closure> (package:relic/src/relic_server.dart:151:24)\n<asynchronous suspension>\n#7      _RelicServer._handleRequest (package:relic/src/relic_server.dart:127:22)\n<asynchronous suspension>\n	\N	\N	f	2026-02-02 17:39:18.097816
689	default	2026-02-02 18:33:37.983067	\N	chat	getChannels	0.007587	1	f	\N	\N	\N	\N	f	2026-02-02 18:33:37.990659
543	default	2026-02-02 17:42:08.098486	\N	chat	getChannels	0.004763	1	f	\N	\N	\N	\N	f	2026-02-02 17:42:08.103254
690	default	2026-02-02 18:33:38.04412	\N	chat	getNotes	0.004503	1	f	\N	\N	\N	\N	f	2026-02-02 18:33:38.048626
544	default	2026-02-02 17:42:08.13324	\N	chat	getNotes	0.006011	1	f	\N	\N	\N	\N	f	2026-02-02 17:42:08.139259
692	default	2026-02-02 18:33:38.197437	\N	chat	getNotes	0.016428	1	f	\N	\N	\N	\N	f	2026-02-02 18:33:38.2139
546	default	2026-02-02 17:42:08.330731	\N	chat	getNotes	0.003664	1	f	\N	\N	\N	\N	f	2026-02-02 17:42:08.334398
547	default	2026-02-02 17:42:12.013588	\N	media	uploadMediaAndCreateNote	0.06659	0	f	Exception: User must be signed in to upload media	#0      MediaEndpoint.uploadMediaAndCreateNote (package:on_air_server/src/media/media_endpoint.dart:56:7)\n<asynchronous suspension>\n#1      Server._handleEndpointCall (package:serverpod/src/server/server.dart:444:22)\n<asynchronous suspension>\n#2      Server._endpoints (package:serverpod/src/server/server.dart:311:12)\n<asynchronous suspension>\n#3      Server._reportException.<anonymous closure> (package:serverpod/src/server/server.dart:205:16)\n<asynchronous suspension>\n#4      Server._headers.<anonymous closure> (package:serverpod/src/server/server.dart:286:22)\n<asynchronous suspension>\n#5      _RoutingMiddlewareBuilder.call.<anonymous closure> (package:relic/src/middleware/routing_middleware.dart:121:18)\n<asynchronous suspension>\n#6      _RelicServer._wrapHandlerWithMiddleware.<anonymous closure> (package:relic/src/relic_server.dart:151:24)\n<asynchronous suspension>\n#7      _RelicServer._handleRequest (package:relic/src/relic_server.dart:127:22)\n<asynchronous suspension>\n	\N	\N	f	2026-02-02 17:42:12.080189
540	default	2026-02-02 17:39:12.214013	\N	chat	chat	181.018438	0	f	\N	\N	\N	\N	f	2026-02-02 17:42:13.23251
545	default	2026-02-02 17:42:08.197709	\N	chat	chat	15.928409	0	f	\N	\N	\N	\N	f	2026-02-02 17:42:24.126128
697	default	2026-02-02 18:33:39.660689	\N	/media/channels/19/thumbnails/69cbcbc4-1322-4f70-b38d-ae5c5fa656e4_thumb.jpg	\N	0.011948	0	f	\N	\N	\N	\N	f	2026-02-02 18:33:39.672652
698	default	2026-02-02 18:33:46.732682	\N	media	uploadMediaAndCreateNote	0.215617	4	f	\N	\N	\N	\N	f	2026-02-02 18:33:46.948304
577	default	2026-02-02 17:56:01.635439	\N	chat	chat	227.544353	0	f	\N	\N	\N	\N	f	2026-02-02 17:59:49.179815
699	default	2026-02-02 18:33:47.001825	\N	/media/channels/19/thumbnails/2382924d-36aa-47c1-8ab3-1b6ca262bfae_thumb.jpg	\N	0.001316	0	f	\N	\N	\N	\N	f	2026-02-02 18:33:47.003157
700	default	2026-02-02 18:33:50.749752	\N	chat	getChannels	0.003952	1	f	\N	\N	\N	\N	f	2026-02-02 18:33:50.753709
701	default	2026-02-02 18:33:50.8208	\N	chat	getNotes	0.00318	1	f	\N	\N	\N	\N	f	2026-02-02 18:33:50.823983
703	default	2026-02-02 18:33:50.945317	\N	chat	getNotes	0.016644	1	f	\N	\N	\N	\N	f	2026-02-02 18:33:50.961969
709	default	2026-02-02 18:33:51.854669	\N	/media/channels/19/thumbnails/2382924d-36aa-47c1-8ab3-1b6ca262bfae_thumb.jpg	\N	0.00172	0	f	\N	\N	\N	\N	f	2026-02-02 18:33:51.856396
710	default	2026-02-02 18:33:54.61123	\N	/media/channels/16/thumbnails/8b31d2ac-84c0-479a-b6d1-9e6cdae21c44_thumb.jpg	\N	0.002017	0	f	\N	\N	\N	\N	f	2026-02-02 18:33:54.613253
711	default	2026-02-02 18:34:04.577686	\N	/media/channels/16/8b31d2ac-84c0-479a-b6d1-9e6cdae21c44.jpg	\N	0.002768	0	f	\N	\N	\N	\N	f	2026-02-02 18:34:04.580474
720	default	2026-02-02 18:37:38.007397	\N	chat	getNotes	0.023517	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:38.030923
728	default	2026-02-02 18:37:41.643666	\N	chat	getNotes	0.011804	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:41.655473
730	default	2026-02-02 18:37:45.445935	\N	/media/channels/19/thumbnails/2382924d-36aa-47c1-8ab3-1b6ca262bfae_thumb.jpg	\N	0.004465	0	f	\N	\N	\N	\N	f	2026-02-02 18:37:45.450411
734	default	2026-02-02 18:37:46.664816	\N	chat	getChannels	0.007926	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:46.672747
737	default	2026-02-02 18:37:48.584756	\N	chat	getChannels	0.025039	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:48.609798
738	default	2026-02-02 18:37:49.185837	\N	/media/channels/15/thumbnails/77cc9738-8a79-4773-9b06-94f8f66bcbc7_thumb.jpg	\N	0.002715	0	f	\N	\N	\N	\N	f	2026-02-02 18:37:49.188554
742	default	2026-02-02 18:37:50.54445	\N	chat	getChannels	0.005503	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:50.549955
745	default	2026-02-02 18:37:52.762453	\N	chat	getChannels	0.004472	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:52.766935
810	default	2026-02-02 18:46:55.93382	\N	chat	getNotes	0.003432	1	f	\N	\N	\N	\N	f	2026-02-02 18:46:55.937255
363	default	2026-02-02 10:01:24.141487	\N	InternalSession	\N	0.004862	1	f	\N	\N	\N	\N	f	2026-02-02 10:01:24.146372
494	default	2026-02-02 10:59:59.998276	\N	chat	deleteChannel	0.009192	2	f	\N	\N	\N	\N	f	2026-02-02 11:00:00.007472
364	default	2026-02-02 10:01:29.031564	\N	chat	getChannels	0.00947	1	f	\N	\N	\N	\N	f	2026-02-02 10:01:29.041039
634	default	2026-02-02 18:08:20.073677	\N	chat	getNotes	0.028761	1	f	\N	\N	\N	\N	f	2026-02-02 18:08:20.102445
365	default	2026-02-02 10:01:29.064575	\N	chat	getNotes	0.025143	1	f	\N	\N	\N	\N	f	2026-02-02 10:01:29.089721
527	default	2026-02-02 16:58:07.693851	\N	chat	getNotes	0.009207	1	f	\N	\N	\N	\N	f	2026-02-02 16:58:07.70306
1018	default	2026-02-03 15:08:49.146689	\N	media	uploadMediaAndCreateNote	8.450607	4	t	\N	\N	\N	\N	f	2026-02-03 15:08:57.597341
367	default	2026-02-02 10:01:29.237766	\N	chat	getNotes	0.013795	1	f	\N	\N	\N	\N	f	2026-02-02 10:01:29.251567
548	default	2026-02-02 17:42:29.916049	\N	InternalSession	\N	0.005511	1	f	\N	\N	\N	\N	f	2026-02-02 17:42:29.92159
373	default	2026-02-02 10:01:40.752866	\N	chat	createChannel	0.005468	1	f	\N	\N	\N	\N	f	2026-02-02 10:01:40.758342
643	default	2026-02-02 18:08:24.47223	\N	chat	getNotes	0.017574	1	f	\N	\N	\N	\N	f	2026-02-02 18:08:24.489808
374	default	2026-02-02 10:01:40.780939	\N	chat	getChannels	0.003455	1	f	\N	\N	\N	\N	f	2026-02-02 10:01:40.784398
549	default	2026-02-02 17:42:43.85577	\N	chat	getChannels	0.007512	1	f	\N	\N	\N	\N	f	2026-02-02 17:42:43.863288
375	default	2026-02-02 10:01:40.827789	\N	chat	getNotes	0.003766	1	f	\N	\N	\N	\N	f	2026-02-02 10:01:40.831558
811	default	2026-02-02 18:46:55.9515	\N	chat	getNotes	0.004241	1	f	\N	\N	\N	\N	f	2026-02-02 18:46:55.955743
550	default	2026-02-02 17:42:43.920729	\N	chat	getNotes	0.0055	1	f	\N	\N	\N	\N	f	2026-02-02 17:42:43.926238
376	default	2026-02-02 10:02:09.950248	\N	chat	createNote	0.026524	3	f	\N	\N	\N	\N	f	2026-02-02 10:02:09.976793
645	default	2026-02-02 18:08:31.455381	\N	/media/channels/16/thumbnails/8b31d2ac-84c0-479a-b6d1-9e6cdae21c44_thumb.jpg	\N	0.003607	0	f	\N	\N	\N	\N	f	2026-02-02 18:08:31.458994
377	default	2026-02-02 10:02:31.067572	\N	chat	getChannels	0.008628	1	f	\N	\N	\N	\N	f	2026-02-02 10:02:31.076204
552	default	2026-02-02 17:42:44.075304	\N	chat	getNotes	0.009216	1	f	\N	\N	\N	\N	f	2026-02-02 17:42:44.084527
378	default	2026-02-02 10:02:31.093377	\N	chat	getNotes	0.003992	1	f	\N	\N	\N	\N	f	2026-02-02 10:02:31.097372
554	default	2026-02-02 17:44:54.407147	\N	media	uploadMediaAndCreateNote	0.116865	1	f	FileSystemException: Creation failed, path = '/app' (OS Error: Read-only file system, errno = 30)	#0      _checkForErrorResponse (dart:io/common.dart:58:9)\n#1      _Directory.create.<anonymous closure> (dart:io/directory_impl.dart:130:9)\n#2      _rootRunUnary (dart:async/zone.dart:1538:47)\n#3      _CustomZone.runUnary (dart:async/zone.dart:1429:19)\n<asynchronous suspension>\n#4      _Directory.create.<anonymous closure>.<anonymous closure> (dart:io/directory_impl.dart:118:54)\n<asynchronous suspension>\n#5      MediaEndpoint.uploadMediaAndCreateNote (package:on_air_server/src/media/media_endpoint.dart:69:7)\n<asynchronous suspension>\n#6      Server._handleEndpointCall (package:serverpod/src/server/server.dart:444:22)\n<asynchronous suspension>\n#7      Server._endpoints (package:serverpod/src/server/server.dart:311:12)\n<asynchronous suspension>\n#8      Server._reportException.<anonymous closure> (package:serverpod/src/server/server.dart:205:16)\n<asynchronous suspension>\n#9      Server._headers.<anonymous closure> (package:serverpod/src/server/server.dart:286:22)\n<asynchronous suspension>\n#10     _RoutingMiddlewareBuilder.call.<anonymous closure> (package:relic/src/middleware/routing_middleware.dart:121:18)\n<asynchronous suspension>\n#11     _RelicServer._wrapHandlerWithMiddleware.<anonymous closure> (package:relic/src/relic_server.dart:151:24)\n<asynchronous suspension>\n#12     _RelicServer._handleRequest (package:relic/src/relic_server.dart:127:22)\n<asynchronous suspension>\n	\N	\N	f	2026-02-02 17:44:54.524017
381	default	2026-02-02 10:02:31.286145	\N	chat	getNotes	0.024954	1	f	\N	\N	\N	\N	f	2026-02-02 10:02:31.3111
366	default	2026-02-02 10:01:29.167321	\N	chat	chat	66.923417	0	f	\N	\N	\N	\N	f	2026-02-02 10:02:36.09077
658	default	2026-02-02 18:09:01.290035	\N	chat	getNotes	0.007696	1	f	\N	\N	\N	\N	f	2026-02-02 18:09:01.297732
386	default	2026-02-02 10:02:47.165578	\N	chat	createNote	0.014886	3	f	\N	\N	\N	\N	f	2026-02-02 10:02:47.180471
579	default	2026-02-02 17:56:01.628612	\N	chat	getNotes	0.016416	1	f	\N	\N	\N	\N	f	2026-02-02 17:56:01.645045
812	default	2026-02-02 18:47:03.517148	\N	media	uploadMediaAndCreateNote	0.238176	4	f	\N	\N	\N	\N	f	2026-02-02 18:47:03.755329
393	default	2026-02-02 10:03:37.920383	\N	chat	getNotes	0.019278	1	f	\N	\N	\N	\N	f	2026-02-02 10:03:37.939663
379	default	2026-02-02 10:02:31.153041	\N	chat	chat	71.662992	0	f	\N	\N	\N	\N	f	2026-02-02 10:03:42.816058
399	default	2026-02-02 10:07:36.504572	\N	chat	getNotes	0.008627	1	f	\N	\N	\N	\N	f	2026-02-02 10:07:36.5132
813	default	2026-02-02 18:47:03.807458	\N	/media/channels/23/thumbnails/9b5fbd1c-4941-4b7d-8d24-fdbb50567490_thumb.jpg	\N	0.01014	0	f	\N	\N	\N	\N	f	2026-02-02 18:47:03.817618
409	default	2026-02-02 10:09:00.009357	\N	chat	createNote	0.01067	3	f	\N	\N	\N	\N	f	2026-02-02 10:09:00.020032
691	default	2026-02-02 18:33:38.205716	\N	chat	chat	29.653741	0	f	\N	\N	\N	\N	f	2026-02-02 18:34:07.859508
814	default	2026-02-02 18:47:11.00004	\N	chat	deleteNote	0.013058	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:11.01313
414	default	2026-02-02 10:09:25.780495	\N	chat	getNotes	0.012829	1	f	\N	\N	\N	\N	f	2026-02-02 10:09:25.793326
702	default	2026-02-02 18:33:50.948897	\N	chat	chat	172.461963	0	f	\N	\N	\N	\N	f	2026-02-02 18:36:43.41087
412	default	2026-02-02 10:09:07.800473	\N	chat	chat	426.771018	0	f	\N	\N	\N	\N	f	2026-02-02 10:16:14.571502
717	default	2026-02-02 18:37:38.008997	\N	chat	getNotes	0.076424	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:38.085427
434	default	2026-02-02 10:16:48.833911	\N	chat	getNotes	0.112421	1	f	\N	\N	\N	\N	f	2026-02-02 10:16:48.946335
815	default	2026-02-02 18:47:20.724895	\N	media	uploadMediaAndCreateNote	0.173682	4	f	\N	\N	\N	\N	f	2026-02-02 18:47:20.898583
725	default	2026-02-02 18:37:41.644115	\N	chat	getNotes	0.009928	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:41.654044
741	default	2026-02-02 18:37:50.54522	\N	chat	getChannels	0.003975	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:50.5492
816	default	2026-02-02 18:47:20.927772	\N	/media/channels/23/thumbnails/533e309e-d346-445d-bf59-712afd3d8b45_thumb.jpg	\N	0.001445	0	f	\N	\N	\N	\N	f	2026-02-02 18:47:20.92926
757	default	2026-02-02 18:38:37.248904	\N	chat	getChannels	0.007207	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:37.256115
760	default	2026-02-02 18:38:37.291253	\N	chat	getNotes	0.004183	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:37.295439
817	default	2026-02-02 18:47:35.464914	\N	chat	createNote	0.015646	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:35.480566
765	default	2026-02-02 18:38:52.730309	\N	chat	getChannels	0.004322	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:52.734635
768	default	2026-02-02 18:38:56.490022	\N	chat	getChannels	0.003465	1	f	\N	\N	\N	\N	f	2026-02-02 18:38:56.49349
818	default	2026-02-02 18:47:39.363093	\N	chat	createNote	0.008566	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:39.371664
778	default	2026-02-02 18:39:16.014903	\N	chat	getNotes	0.017035	1	f	\N	\N	\N	\N	f	2026-02-02 18:39:16.031943
819	default	2026-02-02 18:47:39.719654	\N	chat	createNote	0.008359	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:39.728018
777	default	2026-02-02 18:39:16.016063	\N	chat	chat	359.798589	0	f	\N	\N	\N	\N	f	2026-02-02 18:45:15.814681
820	default	2026-02-02 18:47:39.969223	\N	chat	createNote	0.007413	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:39.976639
784	default	2026-02-02 18:45:29.508101	\N	chat	getNotes	0.012383	1	f	\N	\N	\N	\N	f	2026-02-02 18:45:29.520486
783	default	2026-02-02 18:45:28.335671	\N	chat	chat	24.341582	0	f	\N	\N	\N	\N	f	2026-02-02 18:45:52.677283
793	default	2026-02-02 18:46:03.941583	\N	chat	chat	7.398679	0	f	\N	\N	\N	\N	f	2026-02-02 18:46:11.340272
332	default	2026-02-02 06:21:08.460577	\N	chat	getNotes	0.013383	1	f	\N	\N	\N	\N	f	2026-02-02 06:21:08.473961
495	default	2026-02-02 11:00:00.033462	\N	chat	getChannels	0.002794	1	f	\N	\N	\N	\N	f	2026-02-02 11:00:00.036258
342	default	2026-02-02 06:25:30.754059	\N	chat	getNotes	0.011566	1	f	\N	\N	\N	\N	f	2026-02-02 06:25:30.765626
368	default	2026-02-02 10:01:29.240817	\N	chat	getNotes	0.015523	1	f	\N	\N	\N	\N	f	2026-02-02 10:01:29.256343
369	default	2026-02-02 10:01:29.239625	\N	chat	getNotes	0.017205	1	f	\N	\N	\N	\N	f	2026-02-02 10:01:29.256832
635	default	2026-02-02 18:08:20.079296	\N	/media/channels/15/thumbnails/77cc9738-8a79-4773-9b06-94f8f66bcbc7_thumb.jpg	\N	0.026088	0	f	\N	\N	\N	\N	f	2026-02-02 18:08:20.105393
496	default	2026-02-02 11:00:01.580752	\N	chat	deleteChannel	0.008331	2	f	\N	\N	\N	\N	f	2026-02-02 11:00:01.58909
385	default	2026-02-02 10:02:31.287781	\N	chat	getNotes	0.027116	1	f	\N	\N	\N	\N	f	2026-02-02 10:02:31.314901
382	default	2026-02-02 10:02:31.287176	\N	chat	getNotes	0.023459	1	f	\N	\N	\N	\N	f	2026-02-02 10:02:31.310639
821	default	2026-02-02 18:47:40.232012	\N	chat	createNote	0.010469	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:40.242487
394	default	2026-02-02 10:03:37.922784	\N	chat	getNotes	0.01625	1	f	\N	\N	\N	\N	f	2026-02-02 10:03:37.939037
497	default	2026-02-02 11:00:01.618897	\N	chat	getChannels	0.003239	1	f	\N	\N	\N	\N	f	2026-02-02 11:00:01.622138
400	default	2026-02-02 10:07:36.505948	\N	chat	getNotes	0.008483	1	f	\N	\N	\N	\N	f	2026-02-02 10:07:36.514464
638	default	2026-02-02 18:08:24.478255	\N	chat	chat	27.166895	0	f	\N	\N	\N	\N	f	2026-02-02 18:08:51.645173
413	default	2026-02-02 10:09:25.782517	\N	chat	getNotes	0.011777	1	f	\N	\N	\N	\N	f	2026-02-02 10:09:25.794296
498	default	2026-02-02 11:00:02.764216	\N	chat	deleteChannel	0.005389	2	f	\N	\N	\N	\N	f	2026-02-02 11:00:02.769608
431	default	2026-02-02 10:16:48.84419	\N	chat	getNotes	0.085946	1	f	\N	\N	\N	\N	f	2026-02-02 10:16:48.930145
499	default	2026-02-02 11:00:02.7853	\N	chat	getChannels	0.002673	1	f	\N	\N	\N	\N	f	2026-02-02 11:00:02.787978
663	default	2026-02-02 18:17:11.772159	\N	InternalSession	\N	0.005136	1	f	\N	\N	\N	\N	f	2026-02-02 18:17:11.777321
500	default	2026-02-02 11:00:03.872135	\N	chat	deleteChannel	0.006624	2	f	\N	\N	\N	\N	f	2026-02-02 11:00:03.878763
822	default	2026-02-02 18:47:40.507119	\N	chat	createNote	0.009996	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:40.51712
501	default	2026-02-02 11:00:03.893126	\N	chat	getChannels	0.002745	1	f	\N	\N	\N	\N	f	2026-02-02 11:00:03.895874
693	default	2026-02-02 18:33:38.200547	\N	chat	getNotes	0.020173	1	f	\N	\N	\N	\N	f	2026-02-02 18:33:38.220722
502	default	2026-02-02 11:00:04.99701	\N	chat	deleteChannel	0.007217	2	f	\N	\N	\N	\N	f	2026-02-02 11:00:05.004231
503	default	2026-02-02 11:00:05.025216	\N	chat	getChannels	0.002648	1	f	\N	\N	\N	\N	f	2026-02-02 11:00:05.027866
707	default	2026-02-02 18:33:50.947371	\N	chat	getNotes	0.025113	1	f	\N	\N	\N	\N	f	2026-02-02 18:33:50.972492
504	default	2026-02-02 11:00:06.505606	\N	chat	deleteChannel	0.007746	2	f	\N	\N	\N	\N	f	2026-02-02 11:00:06.513357
823	default	2026-02-02 18:47:40.790136	\N	chat	createNote	0.007065	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:40.797205
505	default	2026-02-02 11:00:06.531429	\N	chat	getChannels	0.003487	1	f	\N	\N	\N	\N	f	2026-02-02 11:00:06.534919
718	default	2026-02-02 18:37:38.011202	\N	chat	getNotes	0.052414	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:38.063629
506	default	2026-02-02 11:00:07.876095	\N	chat	deleteChannel	0.008706	1	f	Exception: Cannot delete the last remaining channel	#0      ChatEndpoint.deleteChannel (package:on_air_server/src/chat/chat_endpoint.dart:140:7)\n<asynchronous suspension>\n#1      Server._handleEndpointCall (package:serverpod/src/server/server.dart:444:22)\n<asynchronous suspension>\n#2      Server._endpoints (package:serverpod/src/server/server.dart:311:12)\n<asynchronous suspension>\n#3      Server._reportException.<anonymous closure> (package:serverpod/src/server/server.dart:205:16)\n<asynchronous suspension>\n#4      Server._headers.<anonymous closure> (package:serverpod/src/server/server.dart:286:22)\n<asynchronous suspension>\n#5      _RoutingMiddlewareBuilder.call.<anonymous closure> (package:relic/src/middleware/routing_middleware.dart:121:18)\n<asynchronous suspension>\n#6      _RelicServer._wrapHandlerWithMiddleware.<anonymous closure> (package:relic/src/relic_server.dart:151:24)\n<asynchronous suspension>\n#7      _RelicServer._handleRequest (package:relic/src/relic_server.dart:127:22)\n<asynchronous suspension>\n	\N	\N	f	2026-02-02 11:00:07.884809
507	default	2026-02-02 11:02:53.618499	\N	chat	getChannels	0.007642	1	f	\N	\N	\N	\N	f	2026-02-02 11:02:53.626149
726	default	2026-02-02 18:37:41.644616	\N	chat	getNotes	0.008809	1	f	\N	\N	\N	\N	f	2026-02-02 18:37:41.653439
508	default	2026-02-02 11:02:53.647258	\N	chat	getNotes	0.004259	1	f	\N	\N	\N	\N	f	2026-02-02 11:02:53.651521
824	default	2026-02-02 18:47:41.077813	\N	chat	createNote	0.00924	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:41.087057
775	default	2026-02-02 18:39:15.902056	\N	chat	getChannels	0.005793	1	f	\N	\N	\N	\N	f	2026-02-02 18:39:15.907853
510	default	2026-02-02 11:03:13.584064	\N	chat	createChannel	0.004799	1	f	\N	\N	\N	\N	f	2026-02-02 11:03:13.588866
776	default	2026-02-02 18:39:15.933477	\N	chat	getNotes	0.004058	1	f	\N	\N	\N	\N	f	2026-02-02 18:39:15.937538
511	default	2026-02-02 11:03:13.600436	\N	chat	getChannels	0.002977	1	f	\N	\N	\N	\N	f	2026-02-02 11:03:13.603415
825	default	2026-02-02 18:47:41.356665	\N	chat	createNote	0.007785	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:41.364453
512	default	2026-02-02 11:03:13.620577	\N	chat	getNotes	0.002345	1	f	\N	\N	\N	\N	f	2026-02-02 11:03:13.622925
779	default	2026-02-02 18:39:16.013595	\N	chat	getNotes	0.018896	1	f	\N	\N	\N	\N	f	2026-02-02 18:39:16.032492
513	default	2026-02-02 11:03:16.00081	\N	chat	deleteChannel	0.008703	2	f	\N	\N	\N	\N	f	2026-02-02 11:03:16.009518
514	default	2026-02-02 11:03:16.026042	\N	chat	getChannels	0.003426	1	f	\N	\N	\N	\N	f	2026-02-02 11:03:16.02947
786	default	2026-02-02 18:45:29.509061	\N	chat	getNotes	0.01112	1	f	\N	\N	\N	\N	f	2026-02-02 18:45:29.520183
515	default	2026-02-02 11:03:24.551892	\N	chat	createNote	0.014491	3	f	\N	\N	\N	\N	f	2026-02-02 11:03:24.566389
826	default	2026-02-02 18:47:41.673738	\N	chat	createNote	0.008027	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:41.681768
516	default	2026-02-02 11:05:02.516724	\N	chat	createNote	0.018679	3	f	\N	\N	\N	\N	f	2026-02-02 11:05:02.53542
827	default	2026-02-02 18:47:42.55436	\N	chat	createNote	0.008648	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:42.563011
517	default	2026-02-02 11:11:58.422979	\N	chat	createNote	0.012888	3	f	\N	\N	\N	\N	f	2026-02-02 11:11:58.435881
518	default	2026-02-02 11:12:57.803241	\N	chat	createChannel	0.011993	1	f	\N	\N	\N	\N	f	2026-02-02 11:12:57.815249
519	default	2026-02-02 11:12:57.827367	\N	chat	getChannels	0.003684	1	f	\N	\N	\N	\N	f	2026-02-02 11:12:57.831053
520	default	2026-02-02 11:12:57.861115	\N	chat	getNotes	0.004316	1	f	\N	\N	\N	\N	f	2026-02-02 11:12:57.865433
521	default	2026-02-02 11:13:00.159357	\N	chat	updateChannel	0.00734	2	f	\N	\N	\N	\N	f	2026-02-02 11:13:00.1667
522	default	2026-02-02 11:13:00.18638	\N	chat	getChannels	0.00312	1	f	\N	\N	\N	\N	f	2026-02-02 11:13:00.189504
509	default	2026-02-02 11:02:53.705446	\N	chat	chat	2941.265859	0	f	\N	\N	\N	\N	f	2026-02-02 11:51:54.971765
523	default	2026-02-02 16:58:07.476897	\N	chat	getChannels	0.006605	1	f	\N	\N	\N	\N	f	2026-02-02 16:58:07.48354
524	default	2026-02-02 16:58:07.550301	\N	chat	getNotes	0.00479	1	f	\N	\N	\N	\N	f	2026-02-02 16:58:07.555096
526	default	2026-02-02 16:58:07.692997	\N	chat	getNotes	0.007678	1	f	\N	\N	\N	\N	f	2026-02-02 16:58:07.700679
525	default	2026-02-02 16:58:07.656111	\N	chat	chat	1111.983061	0	f	\N	\N	\N	\N	f	2026-02-02 17:16:39.639287
551	default	2026-02-02 17:42:44.076441	\N	chat	getNotes	0.003637	1	f	\N	\N	\N	\N	f	2026-02-02 17:42:44.080081
580	default	2026-02-02 17:56:01.629014	\N	chat	getNotes	0.01661	1	f	\N	\N	\N	\N	f	2026-02-02 17:56:01.645626
831	default	2026-02-02 18:47:44.895825	\N	chat	createNote	0.01004	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:44.905868
1019	default	2026-02-03 15:09:18.430358	\N	chat	createNote	0.013004	3	f	\N	\N	\N	\N	f	2026-02-03 15:09:18.443373
832	default	2026-02-02 18:47:45.328353	\N	chat	createNote	0.007955	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:45.336312
1254	default	2026-02-03 19:38:16.206418	\N	chat	createNote	0.012469	3	f	\N	\N	\N	\N	f	2026-02-03 19:38:16.218898
833	default	2026-02-02 18:47:45.853827	\N	chat	createNote	0.006559	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:45.86039
1020	default	2026-02-03 15:10:17.568921	\N	/media/channels/23/thumbnails/533e309e-d346-445d-bf59-712afd3d8b45_thumb.jpg	\N	0.005137	0	f	\N	\N	\N	\N	f	2026-02-03 15:10:17.574101
834	default	2026-02-02 18:47:46.335603	\N	chat	createNote	0.007423	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:46.34303
835	default	2026-02-02 18:47:47.67363	\N	chat	createNote	0.007506	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:47.68114
1021	default	2026-02-03 15:20:21.675463	\N	chat	deleteChannel	0.03077	2	f	\N	\N	\N	\N	f	2026-02-03 15:20:21.706248
836	default	2026-02-02 18:47:48.258025	\N	chat	createNote	0.023336	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:48.281368
837	default	2026-02-02 18:47:48.648121	\N	chat	createNote	0.00657	3	f	\N	\N	\N	\N	f	2026-02-02 18:47:48.654695
1022	default	2026-02-03 15:20:21.721532	\N	chat	getChannels	0.005813	1	f	\N	\N	\N	\N	f	2026-02-03 15:20:21.727349
805	default	2026-02-02 18:46:46.465987	\N	chat	chat	288.697648	0	f	\N	\N	\N	\N	f	2026-02-02 18:51:35.164035
838	default	2026-02-03 06:36:59.634268	\N	chat	getChannels	0.004432	1	f	\N	\N	\N	\N	f	2026-02-03 06:36:59.638707
1023	default	2026-02-03 15:20:23.410939	\N	chat	deleteChannel	0.012999	1	f	Exception: Cannot delete the last remaining channel	#0      ChatEndpoint.deleteChannel (package:on_air_server/src/chat/chat_endpoint.dart:182:7)\n<asynchronous suspension>\n#1      Server._handleEndpointCall (package:serverpod/src/server/server.dart:444:22)\n<asynchronous suspension>\n#2      Server._endpoints (package:serverpod/src/server/server.dart:311:12)\n<asynchronous suspension>\n#3      Server._reportException.<anonymous closure> (package:serverpod/src/server/server.dart:205:16)\n<asynchronous suspension>\n#4      Server._headers.<anonymous closure> (package:serverpod/src/server/server.dart:286:22)\n<asynchronous suspension>\n#5      _RoutingMiddlewareBuilder.call.<anonymous closure> (package:relic/src/middleware/routing_middleware.dart:121:18)\n<asynchronous suspension>\n#6      _RelicServer._wrapHandlerWithMiddleware.<anonymous closure> (package:relic/src/relic_server.dart:151:24)\n<asynchronous suspension>\n#7      _RelicServer._handleRequest (package:relic/src/relic_server.dart:127:22)\n<asynchronous suspension>\n	\N	\N	f	2026-02-03 15:20:23.423952
839	default	2026-02-03 06:36:59.715254	\N	chat	getNotes	0.004361	1	f	\N	\N	\N	\N	f	2026-02-03 06:36:59.71962
1024	default	2026-02-03 15:20:26.372892	\N	chat	getChannels	0.005202	1	f	\N	\N	\N	\N	f	2026-02-03 15:20:26.378104
841	default	2026-02-03 06:36:59.855619	\N	chat	getNotes	0.013229	1	f	\N	\N	\N	\N	f	2026-02-03 06:36:59.868851
1025	default	2026-02-03 15:20:44.053637	\N	chat	createChannel	0.007633	1	f	\N	\N	\N	\N	f	2026-02-03 15:20:44.061291
843	default	2026-02-03 06:37:03.5548	\N	chat	getChannels	0.003947	1	f	\N	\N	\N	\N	f	2026-02-03 06:37:03.558757
844	default	2026-02-03 06:37:03.624099	\N	chat	getNotes	0.003185	1	f	\N	\N	\N	\N	f	2026-02-03 06:37:03.627287
1026	default	2026-02-03 15:20:44.077692	\N	chat	getChannels	0.004867	1	f	\N	\N	\N	\N	f	2026-02-03 15:20:44.082567
846	default	2026-02-03 06:37:03.733001	\N	chat	getNotes	0.007036	1	f	\N	\N	\N	\N	f	2026-02-03 06:37:03.740039
1027	default	2026-02-03 15:20:44.102454	\N	chat	getNotes	0.005209	1	f	\N	\N	\N	\N	f	2026-02-03 15:20:44.107672
848	default	2026-02-03 06:37:10.899977	\N	/media/channels/23/thumbnails/533e309e-d346-445d-bf59-712afd3d8b45_thumb.jpg	\N	0.001953	0	f	\N	\N	\N	\N	f	2026-02-03 06:37:10.901938
849	default	2026-02-03 06:37:36.411786	\N	media	uploadMediaAndCreateNote	0.158416	4	f	\N	\N	\N	\N	f	2026-02-03 06:37:36.570206
1028	default	2026-02-03 15:22:25.395412	\N	chat	createNote	0.022239	3	f	\N	\N	\N	\N	f	2026-02-03 15:22:25.417667
850	default	2026-02-03 06:37:36.680371	\N	/media/channels/23/thumbnails/9b0348b8-1f78-42ca-b026-56ecbfab7804_thumb.jpg	\N	0.001189	0	f	\N	\N	\N	\N	f	2026-02-03 06:37:36.681569
851	default	2026-02-03 06:37:39.565563	\N	chat	getChannels	0.003165	1	f	\N	\N	\N	\N	f	2026-02-03 06:37:39.568731
1029	default	2026-02-03 15:23:22.998781	\N	chat	createNote	0.020875	3	f	\N	\N	\N	\N	f	2026-02-03 15:23:23.019665
852	default	2026-02-03 06:37:39.599727	\N	chat	getNotes	0.004297	1	f	\N	\N	\N	\N	f	2026-02-03 06:37:39.604028
1030	default	2026-02-03 15:23:49.869397	\N	chat	getChannels	0.003282	1	f	\N	\N	\N	\N	f	2026-02-03 15:23:49.872683
855	default	2026-02-03 06:37:39.854773	\N	chat	getNotes	0.004733	1	f	\N	\N	\N	\N	f	2026-02-03 06:37:39.859508
845	default	2026-02-03 06:37:03.693451	\N	chat	chat	40.343759	0	f	\N	\N	\N	\N	f	2026-02-03 06:37:44.03722
1031	default	2026-02-03 15:23:49.910758	\N	chat	getNotes	0.004368	1	f	\N	\N	\N	\N	f	2026-02-03 15:23:49.915129
840	default	2026-02-03 06:36:59.858035	\N	chat	chat	274.682511	0	f	\N	\N	\N	\N	f	2026-02-03 06:41:34.540558
1065	default	2026-02-03 16:09:19.790058	\N	chat	getChannels	0.00719	1	f	\N	\N	\N	\N	f	2026-02-03 16:09:19.797253
853	default	2026-02-03 06:37:39.644964	\N	chat	chat	261.079951	0	f	\N	\N	\N	\N	f	2026-02-03 06:42:00.724949
1067	default	2026-02-03 16:09:19.86282	\N	chat	chat	186.651431	0	f	\N	\N	\N	\N	f	2026-02-03 16:12:26.514314
1068	default	2026-02-03 16:12:43.06752	\N	chat	getChannels	0.005624	1	f	\N	\N	\N	\N	f	2026-02-03 16:12:43.073148
1072	default	2026-02-03 16:12:43.284777	\N	chat	getNotes	0.007316	1	f	\N	\N	\N	\N	f	2026-02-03 16:12:43.292098
1074	default	2026-02-03 16:12:43.46533	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.000837	0	f	\N	\N	\N	\N	f	2026-02-03 16:12:43.466174
1075	default	2026-02-03 16:12:48.911189	\N	chat	getChannels	0.005057	1	f	\N	\N	\N	\N	f	2026-02-03 16:12:48.916251
1078	default	2026-02-03 16:12:49.062793	\N	chat	getNotes	0.01357	1	f	\N	\N	\N	\N	f	2026-02-03 16:12:49.076379
1070	default	2026-02-03 16:12:43.228599	\N	chat	chat	217.406738	0	f	\N	\N	\N	\N	f	2026-02-03 16:16:20.635473
1077	default	2026-02-03 16:12:49.022647	\N	chat	chat	211.615166	0	f	\N	\N	\N	\N	f	2026-02-03 16:16:20.637822
1088	default	2026-02-03 16:22:02.176477	\N	InternalSession	\N	0.006345	1	f	\N	\N	\N	\N	f	2026-02-03 16:22:02.182853
1089	default	2026-02-03 16:22:15.909966	\N	chat	getChannels	0.016029	1	f	\N	\N	\N	\N	f	2026-02-03 16:22:15.925997
1093	default	2026-02-03 16:22:16.125599	\N	chat	getNotes	0.026978	1	f	\N	\N	\N	\N	f	2026-02-03 16:22:16.152601
1095	default	2026-02-03 16:22:16.386531	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.014127	0	f	\N	\N	\N	\N	f	2026-02-03 16:22:16.400672
1096	default	2026-02-03 16:24:07.75938	\N	chat	getChannels	0.010448	1	f	\N	\N	\N	\N	f	2026-02-03 16:24:07.769836
1099	default	2026-02-03 16:24:07.980123	\N	chat	getNotes	0.012392	1	f	\N	\N	\N	\N	f	2026-02-03 16:24:07.992516
1102	default	2026-02-03 16:24:08.213461	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.001227	0	f	\N	\N	\N	\N	f	2026-02-03 16:24:08.214713
1098	default	2026-02-03 16:24:07.94949	\N	chat	chat	131.822468	0	f	\N	\N	\N	\N	f	2026-02-03 16:26:19.772031
1109	default	2026-02-03 16:26:34.891321	\N	chat	getNotes	0.009031	1	f	\N	\N	\N	\N	f	2026-02-03 16:26:34.900358
1137	default	2026-02-03 16:33:43.059463	\N	InternalSession	\N	0.005419	1	f	\N	\N	\N	\N	f	2026-02-03 16:33:43.064914
1138	default	2026-02-03 16:34:00.146319	\N	chat	getChannels	0.010424	1	f	\N	\N	\N	\N	f	2026-02-03 16:34:00.156745
1141	default	2026-02-03 16:34:00.357695	\N	chat	getNotes	0.014198	1	f	\N	\N	\N	\N	f	2026-02-03 16:34:00.371907
1218	default	2026-02-03 19:34:17.567374	\N	chat	getChannels	0.005478	1	f	\N	\N	\N	\N	f	2026-02-03 19:34:17.572854
847	default	2026-02-03 06:37:03.733561	\N	chat	getNotes	0.005952	1	f	\N	\N	\N	\N	f	2026-02-03 06:37:03.739555
854	default	2026-02-03 06:37:39.855786	\N	/media/channels/23/thumbnails/9b0348b8-1f78-42ca-b026-56ecbfab7804_thumb.jpg	\N	0.001108	0	f	\N	\N	\N	\N	f	2026-02-03 06:37:39.856901
856	default	2026-02-03 06:43:22.346747	\N	chat	getChannels	0.003396	1	f	\N	\N	\N	\N	f	2026-02-03 06:43:22.350146
857	default	2026-02-03 06:43:22.435126	\N	chat	getNotes	0.002778	1	f	\N	\N	\N	\N	f	2026-02-03 06:43:22.437907
859	default	2026-02-03 06:43:24.387697	\N	chat	getNotes	0.00742	1	f	\N	\N	\N	\N	f	2026-02-03 06:43:24.395124
860	default	2026-02-03 06:43:24.388862	\N	chat	getNotes	0.008867	1	f	\N	\N	\N	\N	f	2026-02-03 06:43:24.397735
861	default	2026-02-03 06:43:29.077928	\N	chat	getChannels	0.003492	1	f	\N	\N	\N	\N	f	2026-02-03 06:43:29.081424
862	default	2026-02-03 06:43:29.146948	\N	chat	getNotes	0.003081	1	f	\N	\N	\N	\N	f	2026-02-03 06:43:29.150034
865	default	2026-02-03 06:43:29.290411	\N	chat	getNotes	0.005117	1	f	\N	\N	\N	\N	f	2026-02-03 06:43:29.295533
864	default	2026-02-03 06:43:29.289866	\N	chat	getNotes	0.006109	1	f	\N	\N	\N	\N	f	2026-02-03 06:43:29.295977
866	default	2026-02-03 06:45:55.120405	\N	chat	getChannels	0.098703	1	f	\N	\N	\N	\N	f	2026-02-03 06:45:55.219117
868	default	2026-02-03 06:45:55.232275	\N	chat	getNotes	0.053067	1	f	\N	\N	\N	\N	f	2026-02-03 06:45:55.285354
869	default	2026-02-03 06:46:05.632415	\N	chat	getNotes	0.01234	1	f	\N	\N	\N	\N	f	2026-02-03 06:46:05.644761
870	default	2026-02-03 06:46:05.633377	\N	chat	getNotes	0.012683	1	f	\N	\N	\N	\N	f	2026-02-03 06:46:05.646084
871	default	2026-02-03 06:47:09.960329	\N	chat	getChannels	0.003219	1	f	\N	\N	\N	\N	f	2026-02-03 06:47:09.963551
872	default	2026-02-03 06:47:10.00628	\N	chat	getNotes	0.003161	1	f	\N	\N	\N	\N	f	2026-02-03 06:47:10.009443
874	default	2026-02-03 06:47:10.104285	\N	chat	getNotes	0.0073	1	f	\N	\N	\N	\N	f	2026-02-03 06:47:10.111591
875	default	2026-02-03 06:47:10.106039	\N	chat	getNotes	0.006914	1	f	\N	\N	\N	\N	f	2026-02-03 06:47:10.112955
876	default	2026-02-03 06:47:12.766034	\N	chat	getChannels	0.004623	1	f	\N	\N	\N	\N	f	2026-02-03 06:47:12.77066
877	default	2026-02-03 06:47:12.801696	\N	chat	getNotes	0.002521	1	f	\N	\N	\N	\N	f	2026-02-03 06:47:12.804223
880	default	2026-02-03 06:47:12.89029	\N	chat	getNotes	0.006411	1	f	\N	\N	\N	\N	f	2026-02-03 06:47:12.896705
879	default	2026-02-03 06:47:12.889352	\N	chat	getNotes	0.006389	1	f	\N	\N	\N	\N	f	2026-02-03 06:47:12.895758
863	default	2026-02-03 06:43:29.239912	\N	chat	chat	225.33964	0	f	\N	\N	\N	\N	f	2026-02-03 06:47:14.579571
867	default	2026-02-03 06:45:55.257663	\N	chat	chat	81.181481	0	f	\N	\N	\N	\N	f	2026-02-03 06:47:16.439164
881	default	2026-02-03 06:48:06.036335	\N	InternalSession	\N	0.006027	1	f	\N	\N	\N	\N	f	2026-02-03 06:48:06.042394
882	default	2026-02-03 06:48:12.000183	\N	chat	getChannels	0.009256	1	f	\N	\N	\N	\N	f	2026-02-03 06:48:12.009448
883	default	2026-02-03 06:48:12.019313	\N	chat	getNotes	0.012601	1	f	\N	\N	\N	\N	f	2026-02-03 06:48:12.031919
885	default	2026-02-03 06:48:12.097612	\N	chat	getNotes	0.022206	1	f	\N	\N	\N	\N	f	2026-02-03 06:48:12.119831
886	default	2026-02-03 06:48:12.099023	\N	chat	getNotes	0.024554	1	f	\N	\N	\N	\N	f	2026-02-03 06:48:12.123586
887	default	2026-02-03 06:48:26.405856	\N	media	uploadMediaAndCreateNote	0.100538	1	f	Exception: Channel not found: 1	#0      MediaEndpoint.uploadMediaAndCreateNote (package:on_air_server/src/media/media_endpoint.dart:57:7)\n<asynchronous suspension>\n#1      Server._handleEndpointCall (package:serverpod/src/server/server.dart:444:22)\n<asynchronous suspension>\n#2      Server._endpoints (package:serverpod/src/server/server.dart:311:12)\n<asynchronous suspension>\n#3      Server._reportException.<anonymous closure> (package:serverpod/src/server/server.dart:205:16)\n<asynchronous suspension>\n#4      Server._headers.<anonymous closure> (package:serverpod/src/server/server.dart:286:22)\n<asynchronous suspension>\n#5      _RoutingMiddlewareBuilder.call.<anonymous closure> (package:relic/src/middleware/routing_middleware.dart:121:18)\n<asynchronous suspension>\n#6      _RelicServer._wrapHandlerWithMiddleware.<anonymous closure> (package:relic/src/relic_server.dart:151:24)\n<asynchronous suspension>\n#7      _RelicServer._handleRequest (package:relic/src/relic_server.dart:127:22)\n<asynchronous suspension>\n	\N	\N	f	2026-02-03 06:48:26.5064
888	default	2026-02-03 06:48:27.813997	\N	/media/channels/23/thumbnails/9b0348b8-1f78-42ca-b026-56ecbfab7804_thumb.jpg	\N	0.012451	0	f	\N	\N	\N	\N	f	2026-02-03 06:48:27.826458
889	default	2026-02-03 06:48:36.521329	\N	media	uploadMediaAndCreateNote	0.190947	4	f	\N	\N	\N	\N	f	2026-02-03 06:48:36.712282
890	default	2026-02-03 06:48:36.778124	\N	/media/channels/23/thumbnails/a0baf66b-841b-4ef6-9723-bbd1e1bb7432_thumb.jpg	\N	0.002736	0	f	\N	\N	\N	\N	f	2026-02-03 06:48:36.780868
891	default	2026-02-03 06:50:14.80464	\N	chat	getChannels	0.007	1	f	\N	\N	\N	\N	f	2026-02-03 06:50:14.81165
892	default	2026-02-03 06:50:14.877912	\N	chat	getNotes	0.007278	1	f	\N	\N	\N	\N	f	2026-02-03 06:50:14.885196
894	default	2026-02-03 06:50:15.05757	\N	chat	getNotes	0.011016	1	f	\N	\N	\N	\N	f	2026-02-03 06:50:15.068593
895	default	2026-02-03 06:50:15.058285	\N	chat	getNotes	0.008729	1	f	\N	\N	\N	\N	f	2026-02-03 06:50:15.067028
897	default	2026-02-03 06:50:24.013448	\N	/media/channels/23/thumbnails/a0baf66b-841b-4ef6-9723-bbd1e1bb7432_thumb.jpg	\N	0.00146	0	f	\N	\N	\N	\N	f	2026-02-03 06:50:24.014913
896	default	2026-02-03 06:50:24.014524	\N	/media/channels/23/thumbnails/9b0348b8-1f78-42ca-b026-56ecbfab7804_thumb.jpg	\N	0.00075	0	f	\N	\N	\N	\N	f	2026-02-03 06:50:24.015276
893	default	2026-02-03 06:50:15.004023	\N	chat	chat	25.49206	0	f	\N	\N	\N	\N	f	2026-02-03 06:50:40.496107
898	default	2026-02-03 06:50:47.294095	\N	chat	getChannels	0.003621	1	f	\N	\N	\N	\N	f	2026-02-03 06:50:47.297721
899	default	2026-02-03 06:50:47.366651	\N	chat	getNotes	0.005008	1	f	\N	\N	\N	\N	f	2026-02-03 06:50:47.371671
902	default	2026-02-03 06:50:47.537852	\N	chat	getNotes	0.007288	1	f	\N	\N	\N	\N	f	2026-02-03 06:50:47.545153
901	default	2026-02-03 06:50:47.53701	\N	chat	getNotes	0.00905	1	f	\N	\N	\N	\N	f	2026-02-03 06:50:47.546065
904	default	2026-02-03 06:50:50.402165	\N	/media/channels/23/thumbnails/a0baf66b-841b-4ef6-9723-bbd1e1bb7432_thumb.jpg	\N	0.000947	0	f	\N	\N	\N	\N	f	2026-02-03 06:50:50.403125
903	default	2026-02-03 06:50:50.402807	\N	/media/channels/23/thumbnails/9b0348b8-1f78-42ca-b026-56ecbfab7804_thumb.jpg	\N	0.001018	0	f	\N	\N	\N	\N	f	2026-02-03 06:50:50.403857
858	default	2026-02-03 06:43:22.448345	\N	chat	chat	\N	\N	\N	\N	\N	\N	\N	f	2026-02-03 06:47:00.025897
873	default	2026-02-03 06:47:10.078576	\N	chat	chat	\N	\N	\N	\N	\N	\N	\N	f	2026-02-03 06:47:10.078608
878	default	2026-02-03 06:47:12.86267	\N	chat	chat	\N	\N	\N	\N	\N	\N	\N	f	2026-02-03 06:47:12.862719
905	default	2026-02-03 06:51:40.052066	\N	chat	getChannels	0.004437	1	f	\N	\N	\N	\N	f	2026-02-03 06:51:40.056508
906	default	2026-02-03 06:51:40.131738	\N	chat	getNotes	0.003183	1	f	\N	\N	\N	\N	f	2026-02-03 06:51:40.134928
908	default	2026-02-03 06:52:15.610478	\N	chat	getNotes	0.017574	1	f	\N	\N	\N	\N	f	2026-02-03 06:52:15.62807
909	default	2026-02-03 06:52:15.613524	\N	chat	getNotes	0.016261	1	f	\N	\N	\N	\N	f	2026-02-03 06:52:15.629791
900	default	2026-02-03 06:50:47.488486	\N	chat	chat	101.315718	0	f	\N	\N	\N	\N	f	2026-02-03 06:52:28.804215
923	default	2026-02-03 06:52:36.739522	\N	/media/channels/23/thumbnails/9b0348b8-1f78-42ca-b026-56ecbfab7804_thumb.jpg	\N	0.000661	0	f	\N	\N	\N	\N	f	2026-02-03 06:52:36.740186
884	default	2026-02-03 06:48:12.103686	\N	chat	chat	275.494228	0	f	\N	\N	\N	\N	f	2026-02-03 06:52:47.597918
907	default	2026-02-03 06:51:40.144144	\N	chat	chat	\N	\N	\N	\N	\N	\N	\N	f	2026-02-03 06:53:00.01894
910	default	2026-02-03 06:52:18.000867	\N	/media/channels/23/thumbnails/9b0348b8-1f78-42ca-b026-56ecbfab7804_thumb.jpg	\N	0.00101	0	f	\N	\N	\N	\N	f	2026-02-03 06:52:18.00188
1032	default	2026-02-03 16:01:39.01668	\N	InternalSession	\N	0.005075	1	f	\N	\N	\N	\N	f	2026-02-03 16:01:39.02178
916	default	2026-02-03 06:52:30.694579	\N	chat	getNotes	0.011517	1	f	\N	\N	\N	\N	f	2026-02-03 06:52:30.706107
1033	default	2026-02-03 16:01:56.787211	\N	chat	getChannels	0.016744	1	f	\N	\N	\N	\N	f	2026-02-03 16:01:56.803962
918	default	2026-02-03 06:52:32.366756	\N	/media/channels/23/thumbnails/9b0348b8-1f78-42ca-b026-56ecbfab7804_thumb.jpg	\N	0.000906	0	f	\N	\N	\N	\N	f	2026-02-03 06:52:32.367664
922	default	2026-02-03 06:52:36.738895	\N	/media/channels/23/thumbnails/a0baf66b-841b-4ef6-9723-bbd1e1bb7432_thumb.jpg	\N	0.000972	0	f	\N	\N	\N	\N	f	2026-02-03 06:52:36.739873
914	default	2026-02-03 06:52:25.307063	\N	chat	chat	14.73518	0	f	\N	\N	\N	\N	f	2026-02-03 06:52:40.042263
1219	default	2026-02-03 19:34:17.625679	\N	chat	chat	431.003854	0	f	\N	\N	\N	\N	f	2026-02-03 19:41:28.629553
929	default	2026-02-03 06:52:43.702654	\N	chat	getNotes	0.015669	1	f	\N	\N	\N	\N	f	2026-02-03 06:52:43.718337
1036	default	2026-02-03 16:01:57.547175	\N	chat	getNotes	0.026725	1	f	\N	\N	\N	\N	f	2026-02-03 16:01:57.573914
1038	default	2026-02-03 16:01:57.951275	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.033562	0	f	\N	\N	\N	\N	f	2026-02-03 16:01:57.98486
1039	default	2026-02-03 16:02:13.316847	\N	chat	getChannels	0.014374	1	f	\N	\N	\N	\N	f	2026-02-03 16:02:13.331242
1042	default	2026-02-03 16:02:13.47319	\N	chat	getNotes	0.013815	1	f	\N	\N	\N	\N	f	2026-02-03 16:02:13.487012
1044	default	2026-02-03 16:02:13.713059	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.004174	0	f	\N	\N	\N	\N	f	2026-02-03 16:02:13.717247
1035	default	2026-02-03 16:01:56.879766	\N	chat	chat	36.607648	0	f	\N	\N	\N	\N	f	2026-02-03 16:02:33.487463
1045	default	2026-02-03 16:02:38.797249	\N	chat	createChannel	0.010383	1	f	\N	\N	\N	\N	f	2026-02-03 16:02:38.807645
1046	default	2026-02-03 16:02:38.822103	\N	chat	getChannels	0.004569	1	f	\N	\N	\N	\N	f	2026-02-03 16:02:38.82668
1047	default	2026-02-03 16:02:38.849861	\N	chat	getNotes	0.005249	1	f	\N	\N	\N	\N	f	2026-02-03 16:02:38.855116
1041	default	2026-02-03 16:02:13.433457	\N	chat	chat	217.137003	0	f	\N	\N	\N	\N	f	2026-02-03 16:05:50.5705
1066	default	2026-02-03 16:09:19.791238	\N	chat	getChannels	0.00669	1	f	\N	\N	\N	\N	f	2026-02-03 16:09:19.797931
1069	default	2026-02-03 16:12:43.068345	\N	chat	getChannels	0.005146	1	f	\N	\N	\N	\N	f	2026-02-03 16:12:43.073493
1071	default	2026-02-03 16:12:43.285551	\N	chat	getNotes	0.007592	1	f	\N	\N	\N	\N	f	2026-02-03 16:12:43.293144
1076	default	2026-02-03 16:12:48.91167	\N	chat	getChannels	0.00508	1	f	\N	\N	\N	\N	f	2026-02-03 16:12:48.916752
1079	default	2026-02-03 16:12:49.06433	\N	chat	getNotes	0.010389	1	f	\N	\N	\N	\N	f	2026-02-03 16:12:49.07473
1090	default	2026-02-03 16:22:15.914331	\N	chat	getChannels	0.011061	1	f	\N	\N	\N	\N	f	2026-02-03 16:22:15.925397
1092	default	2026-02-03 16:22:16.127809	\N	chat	getNotes	0.026863	1	f	\N	\N	\N	\N	f	2026-02-03 16:22:16.154674
1097	default	2026-02-03 16:24:07.76056	\N	chat	getChannels	0.007847	1	f	\N	\N	\N	\N	f	2026-02-03 16:24:07.768413
1100	default	2026-02-03 16:24:07.981813	\N	chat	getNotes	0.010042	1	f	\N	\N	\N	\N	f	2026-02-03 16:24:07.991857
1115	default	2026-02-03 16:27:21.459797	\N	chat	getNotes	0.013781	1	f	\N	\N	\N	\N	f	2026-02-03 16:27:21.473582
1121	default	2026-02-03 16:27:24.9153	\N	chat	getNotes	0.01247	1	f	\N	\N	\N	\N	f	2026-02-03 16:27:24.927771
1139	default	2026-02-03 16:34:00.149708	\N	chat	getChannels	0.006363	1	f	\N	\N	\N	\N	f	2026-02-03 16:34:00.156078
1140	default	2026-02-03 16:34:00.359712	\N	chat	getNotes	0.013436	1	f	\N	\N	\N	\N	f	2026-02-03 16:34:00.373151
1146	default	2026-02-03 16:34:23.641719	\N	chat	getChannels	0.005192	1	f	\N	\N	\N	\N	f	2026-02-03 16:34:23.646913
1149	default	2026-02-03 16:34:23.862881	\N	chat	getNotes	0.008893	1	f	\N	\N	\N	\N	f	2026-02-03 16:34:23.871777
1152	default	2026-02-03 16:34:35.038785	\N	chat	getChannels	0.007074	1	f	\N	\N	\N	\N	f	2026-02-03 16:34:35.045861
1155	default	2026-02-03 16:34:35.179853	\N	chat	getNotes	0.010145	1	f	\N	\N	\N	\N	f	2026-02-03 16:34:35.189999
1174	default	2026-02-03 16:36:51.315991	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.002945	0	f	\N	\N	\N	\N	f	2026-02-03 16:36:51.318951
1180	default	2026-02-03 16:37:00.224856	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.000732	0	f	\N	\N	\N	\N	f	2026-02-03 16:37:00.225595
1182	default	2026-02-03 16:41:46.496919	\N	/media/channels/25/thumbnails/151e5f11-6d1a-44f7-952e-22d962c1b5df_thumb.jpg	\N	0.002054	0	f	\N	\N	\N	\N	f	2026-02-03 16:41:46.498975
1187	default	2026-02-03 17:44:09.788052	\N	/media/channels/25/thumbnails/0bf8c3ea-ae09-4ad0-86fc-0136fc0d1db5_thumb.jpg	\N	0.000533	0	f	\N	\N	\N	\N	f	2026-02-03 17:44:09.788594
1196	default	2026-02-03 17:48:24.992942	\N	/media/channels/14/thumbnails/7971e7dc-b2b3-47f7-a5c2-1fa8b37bc074_thumb.jpg	\N	0.000633	0	f	\N	\N	\N	\N	f	2026-02-03 17:48:24.993576
1197	default	2026-02-03 17:48:55.729533	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.000607	0	f	\N	\N	\N	\N	f	2026-02-03 17:48:55.730149
1198	default	2026-02-03 17:51:24.761197	\N	chat	createNote	0.013269	3	f	\N	\N	\N	\N	f	2026-02-03 17:51:24.774483
1200	default	2026-02-03 19:09:05.220929	\N	chat	getChannels	0.020532	1	f	\N	\N	\N	\N	f	2026-02-03 19:09:05.241474
1202	default	2026-02-03 19:09:05.892624	\N	chat	getChannels	0.005622	1	f	\N	\N	\N	\N	f	2026-02-03 19:09:05.898249
1206	default	2026-02-03 19:09:06.034454	\N	chat	getNotes	0.010092	1	f	\N	\N	\N	\N	f	2026-02-03 19:09:06.04455
1209	default	2026-02-03 19:09:06.236449	\N	/media/channels/14/thumbnails/7971e7dc-b2b3-47f7-a5c2-1fa8b37bc074_thumb.jpg	\N	0.002217	0	f	\N	\N	\N	\N	f	2026-02-03 19:09:06.238674
1211	default	2026-02-03 19:09:07.316878	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.000663	0	f	\N	\N	\N	\N	f	2026-02-03 19:09:07.317562
1212	default	2026-02-03 19:09:26.703766	\N	chat	createNote	0.019649	3	f	\N	\N	\N	\N	f	2026-02-03 19:09:26.723423
1201	default	2026-02-03 19:09:05.350134	\N	chat	chat	1490.616408	0	f	\N	\N	\N	\N	f	2026-02-03 19:33:55.966896
1204	default	2026-02-03 19:09:05.990521	\N	chat	chat	1491.130942	0	f	\N	\N	\N	\N	f	2026-02-03 19:33:57.121474
1222	default	2026-02-03 19:34:18.320275	\N	chat	getNotes	0.036315	1	f	\N	\N	\N	\N	f	2026-02-03 19:34:18.356601
1229	default	2026-02-03 19:35:23.394899	\N	media	uploadMediaAndCreateNote	0.225959	4	f	\N	\N	\N	\N	f	2026-02-03 19:35:23.620871
1230	default	2026-02-03 19:35:23.701632	\N	/media/channels/24/thumbnails/7782eecd-d098-466d-9a5d-f314d03efcb5_thumb.jpg	\N	0.002333	0	f	\N	\N	\N	\N	f	2026-02-03 19:35:23.703977
1231	default	2026-02-03 19:35:23.900512	\N	media	uploadMediaAndCreateNote	0.398908	4	f	\N	\N	\N	\N	f	2026-02-03 19:35:24.299424
1232	default	2026-02-03 19:35:24.37353	\N	/media/channels/24/thumbnails/c5a3dd38-900a-4446-9d41-3c9d17096d5e_thumb.jpg	\N	0.001073	0	f	\N	\N	\N	\N	f	2026-02-03 19:35:24.374611
1233	default	2026-02-03 19:35:40.596859	\N	chat	deleteNote	0.014031	3	f	\N	\N	\N	\N	f	2026-02-03 19:35:40.610905
1234	default	2026-02-03 19:35:42.123567	\N	chat	deleteNote	0.014426	3	f	\N	\N	\N	\N	f	2026-02-03 19:35:42.13801
1235	default	2026-02-03 19:35:53.841978	\N	chat	deleteNote	0.008571	3	f	\N	\N	\N	\N	f	2026-02-03 19:35:53.850552
1236	default	2026-02-03 19:36:03.229513	\N	chat	deleteNote	0.012671	3	f	\N	\N	\N	\N	f	2026-02-03 19:36:03.242197
1237	default	2026-02-03 19:36:06.544234	\N	/media/channels/25/thumbnails/0bf8c3ea-ae09-4ad0-86fc-0136fc0d1db5_thumb.jpg	\N	0.001888	0	f	\N	\N	\N	\N	f	2026-02-03 19:36:06.546133
1239	default	2026-02-03 19:36:18.161072	\N	media	uploadMediaAndCreateNote	7.753633	4	t	\N	\N	\N	\N	f	2026-02-03 19:36:25.914777
911	default	2026-02-03 06:52:17.9998	\N	/media/channels/23/thumbnails/a0baf66b-841b-4ef6-9723-bbd1e1bb7432_thumb.jpg	\N	0.00149	0	f	\N	\N	\N	\N	f	2026-02-03 06:52:18.001312
1255	default	2026-02-03 19:38:18.523261	\N	chat	deleteNote	0.017559	3	f	\N	\N	\N	\N	f	2026-02-03 19:38:18.540836
912	default	2026-02-03 06:52:25.225943	\N	chat	getChannels	0.004405	1	f	\N	\N	\N	\N	f	2026-02-03 06:52:25.230352
1034	default	2026-02-03 16:01:56.791071	\N	chat	getChannels	0.010716	1	f	\N	\N	\N	\N	f	2026-02-03 16:01:56.801794
913	default	2026-02-03 06:52:25.300651	\N	chat	getNotes	0.003735	1	f	\N	\N	\N	\N	f	2026-02-03 06:52:25.304389
915	default	2026-02-03 06:52:30.692732	\N	chat	getNotes	0.012141	1	f	\N	\N	\N	\N	f	2026-02-03 06:52:30.704878
1037	default	2026-02-03 16:01:57.549121	\N	chat	getNotes	0.025864	1	f	\N	\N	\N	\N	f	2026-02-03 16:01:57.574989
917	default	2026-02-03 06:52:32.365831	\N	/media/channels/23/thumbnails/a0baf66b-841b-4ef6-9723-bbd1e1bb7432_thumb.jpg	\N	0.001253	0	f	\N	\N	\N	\N	f	2026-02-03 06:52:32.367093
1256	default	2026-02-03 19:38:21.399411	\N	chat	deleteNote	0.008763	3	f	\N	\N	\N	\N	f	2026-02-03 19:38:21.408188
919	default	2026-02-03 06:52:36.289762	\N	chat	getChannels	0.002994	1	f	\N	\N	\N	\N	f	2026-02-03 06:52:36.292762
1040	default	2026-02-03 16:02:13.320428	\N	chat	getChannels	0.012266	1	f	\N	\N	\N	\N	f	2026-02-03 16:02:13.332704
920	default	2026-02-03 06:52:36.326245	\N	chat	getNotes	0.005669	1	f	\N	\N	\N	\N	f	2026-02-03 06:52:36.33192
1043	default	2026-02-03 16:02:13.476148	\N	chat	getNotes	0.009395	1	f	\N	\N	\N	\N	f	2026-02-03 16:02:13.485554
924	default	2026-02-03 06:52:36.737802	\N	chat	getNotes	0.006817	1	f	\N	\N	\N	\N	f	2026-02-03 06:52:36.744622
1257	default	2026-02-03 19:38:25.604494	\N	chat	deleteNote	0.015226	3	f	\N	\N	\N	\N	f	2026-02-03 19:38:25.619734
925	default	2026-02-03 06:52:43.566369	\N	chat	getChannels	0.003171	1	f	\N	\N	\N	\N	f	2026-02-03 06:52:43.569544
1048	default	2026-02-03 16:02:47.531209	\N	media	uploadMediaAndCreateNote	0.799249	3	f	DatabaseQueryException: { message: column "duration" of relation "media_attachments" does not exist, code: 42703, position: 132 }	#0      _PgSessionBase._prepare (package:postgres/src/v3/connection.dart:199:35)\n#1      _PgSessionBase.execute (package:postgres/src/v3/connection.dart:183:30)\n#2      DatabaseConnection._query (package:serverpod/src/database/adapters/postgres/database_connection.dart:527:34)\n#3      DatabaseConnection._mappedResultsQuery (package:serverpod/src/database/adapters/postgres/database_connection.dart:626:24)\n#4      DatabaseConnection.insert (package:serverpod/src/database/adapters/postgres/database_connection.dart:147:19)\n#5      DatabaseConnection.insertRow (package:serverpod/src/database/adapters/postgres/database_connection.dart:162:24)\n#6      Database.insertRow (package:serverpod/src/database/database.dart:239:32)\n#7      MediaAttachmentRepository.insertRow (package:on_air_server/src/generated/media/media_attachment.dart:659:23)\n#8      MediaEndpoint.uploadMediaAndCreateNote.<anonymous closure> (package:on_air_server/src/media/media_endpoint.dart:214:34)\n<asynchronous suspension>\n#9      PgConnectionImplementation.runTx.<anonymous closure> (package:postgres/src/v3/connection.dart:591:24)\n<asynchronous suspension>\n#10     Pool.withResource (package:pool/pool.dart:127:14)\n<asynchronous suspension>\n#11     PoolImplementation.withConnection (package:postgres/src/pool/pool_impl.dart:153:16)\n<asynchronous suspension>\n#12     Database.transaction (package:serverpod/src/database/database.dart:399:12)\n<asynchronous suspension>\n#13     MediaEndpoint.uploadMediaAndCreateNote (package:on_air_server/src/media/media_endpoint.dart:184:20)\n<asynchronous suspension>\n#14     Server._handleEndpointCall (package:serverpod/src/server/server.dart:444:22)\n<asynchronous suspension>\n#15     Server._endpoints (package:serverpod/src/server/server.dart:311:12)\n<asynchronous suspension>\n#16     Server._reportException.<anonymous closure> (package:serverpod/src/server/server.dart:205:16)\n<asynchronous suspension>\n#17     Server._headers.<anonymous closure> (package:serverpod/src/server/server.dart:286:22)\n<asynchronous suspension>\n#18     _RoutingMiddlewareBuilder.call.<anonymous closure> (package:relic/src/middleware/routing_middleware.dart:121:18)\n<asynchronous suspension>\n#19     _RelicServer._wrapHandlerWithMiddleware.<anonymous closure> (package:relic/src/relic_server.dart:151:24)\n<asynchronous suspension>\n#20     _RelicServer._handleRequest (package:relic/src/relic_server.dart:127:22)\n<asynchronous suspension>\n	\N	\N	f	2026-02-03 16:02:48.330463
926	default	2026-02-03 06:52:43.622023	\N	chat	getNotes	0.004221	1	f	\N	\N	\N	\N	f	2026-02-03 06:52:43.626247
928	default	2026-02-03 06:52:43.70153	\N	chat	getNotes	0.018282	1	f	\N	\N	\N	\N	f	2026-02-03 06:52:43.719825
921	default	2026-02-03 06:52:36.380297	\N	chat	chat	10.500945	0	f	\N	\N	\N	\N	f	2026-02-03 06:52:46.881254
1073	default	2026-02-03 16:12:43.286039	\N	chat	getNotes	0.006516	1	f	\N	\N	\N	\N	f	2026-02-03 16:12:43.292556
1259	default	2026-02-03 19:40:46.628192	\N	chat	getNotes	0.012424	1	f	\N	\N	\N	\N	f	2026-02-03 19:40:46.640619
1080	default	2026-02-03 16:12:49.06862	\N	chat	getNotes	0.011108	1	f	\N	\N	\N	\N	f	2026-02-03 16:12:49.079738
1261	default	2026-02-03 19:40:46.629243	\N	chat	getNotes	0.011875	1	f	\N	\N	\N	\N	f	2026-02-03 19:40:46.641119
1091	default	2026-02-03 16:22:16.134434	\N	chat	chat	114.858617	0	f	\N	\N	\N	\N	f	2026-02-03 16:24:10.993077
1263	default	2026-02-03 19:41:19.91297	\N	chat	getChannels	0.00481	1	f	\N	\N	\N	\N	f	2026-02-03 19:41:19.917784
1126	default	2026-02-03 16:28:53.879705	\N	InternalSession	\N	0.007317	1	f	\N	\N	\N	\N	f	2026-02-03 16:28:53.887138
1262	default	2026-02-03 19:41:19.913658	\N	chat	getChannels	0.004472	1	f	\N	\N	\N	\N	f	2026-02-03 19:41:19.918132
1128	default	2026-02-03 16:29:08.564651	\N	chat	getChannels	0.033464	1	f	\N	\N	\N	\N	f	2026-02-03 16:29:08.598133
1266	default	2026-02-03 19:41:20.124286	\N	chat	getNotes	0.012292	1	f	\N	\N	\N	\N	f	2026-02-03 19:41:20.136585
1130	default	2026-02-03 16:29:09.063415	\N	chat	getChannels	0.01123	1	f	\N	\N	\N	\N	f	2026-02-03 16:29:09.074655
1134	default	2026-02-03 16:29:09.320812	\N	chat	getNotes	0.026205	1	f	\N	\N	\N	\N	f	2026-02-03 16:29:09.347039
1129	default	2026-02-03 16:29:08.653626	\N	chat	chat	83.887613	0	f	\N	\N	\N	\N	f	2026-02-03 16:30:32.541265
1132	default	2026-02-03 16:29:09.176742	\N	chat	chat	83.36744	0	f	\N	\N	\N	\N	f	2026-02-03 16:30:32.544205
1142	default	2026-02-03 16:34:00.360571	\N	chat	getNotes	0.013135	1	f	\N	\N	\N	\N	f	2026-02-03 16:34:00.373707
1148	default	2026-02-03 16:34:23.863767	\N	chat	getNotes	0.00663	1	f	\N	\N	\N	\N	f	2026-02-03 16:34:23.870406
1157	default	2026-02-03 16:34:35.18063	\N	chat	getNotes	0.007907	1	f	\N	\N	\N	\N	f	2026-02-03 16:34:35.18855
1199	default	2026-02-03 19:09:05.224946	\N	chat	getChannels	0.013905	1	f	\N	\N	\N	\N	f	2026-02-03 19:09:05.238899
1203	default	2026-02-03 19:09:05.893749	\N	chat	getChannels	0.003817	1	f	\N	\N	\N	\N	f	2026-02-03 19:09:05.897571
1205	default	2026-02-03 19:09:06.035503	\N	chat	getNotes	0.008099	1	f	\N	\N	\N	\N	f	2026-02-03 19:09:06.043609
1208	default	2026-02-03 19:09:06.038246	\N	chat	getNotes	0.007954	1	f	\N	\N	\N	\N	f	2026-02-03 19:09:06.046201
1210	default	2026-02-03 19:09:06.238013	\N	/media/channels/14/thumbnails/fc7df6f1-086e-42ba-9ffd-4d8d8be15930_thumb.jpg	\N	0.001318	0	f	\N	\N	\N	\N	f	2026-02-03 19:09:06.239335
1223	default	2026-02-03 19:34:18.318402	\N	chat	getNotes	0.040593	1	f	\N	\N	\N	\N	f	2026-02-03 19:34:18.359
1238	default	2026-02-03 19:36:06.542961	\N	/media/channels/25/thumbnails/151e5f11-6d1a-44f7-952e-22d962c1b5df_thumb.jpg	\N	0.00374	0	f	\N	\N	\N	\N	f	2026-02-03 19:36:06.546704
1240	default	2026-02-03 19:36:26.255479	\N	media	uploadMediaAndCreateNote	0.391112	4	f	\N	\N	\N	\N	f	2026-02-03 19:36:26.646598
1241	default	2026-02-03 19:36:26.718361	\N	/media/channels/25/thumbnails/034048a0-39f1-4f5a-ad0e-d158a6a0693d_thumb.jpg	\N	0.001115	0	f	\N	\N	\N	\N	f	2026-02-03 19:36:26.719485
1242	default	2026-02-03 19:36:27.110651	\N	media	uploadMediaAndCreateNote	0.734506	4	f	\N	\N	\N	\N	f	2026-02-03 19:36:27.845161
1243	default	2026-02-03 19:36:27.916924	\N	/media/channels/25/thumbnails/b8de9cfd-5e64-4905-9d16-cb8633d6a251_thumb.jpg	\N	0.001149	0	f	\N	\N	\N	\N	f	2026-02-03 19:36:27.918081
1244	default	2026-02-03 19:36:40.17022	\N	chat	deleteNote	0.015107	3	f	\N	\N	\N	\N	f	2026-02-03 19:36:40.185336
1245	default	2026-02-03 19:37:08.367666	\N	chat	createNote	0.013171	3	f	\N	\N	\N	\N	f	2026-02-03 19:37:08.380848
1246	default	2026-02-03 19:37:18.227143	\N	chat	deleteNote	0.00638	3	f	\N	\N	\N	\N	f	2026-02-03 19:37:18.233529
1247	default	2026-02-03 19:37:23.611942	\N	chat	deleteNote	0.011414	3	f	\N	\N	\N	\N	f	2026-02-03 19:37:23.623366
1248	default	2026-02-03 19:37:33.089077	\N	media	uploadMediaAndCreateNote	0.150415	4	f	\N	\N	\N	\N	f	2026-02-03 19:37:33.239496
1249	default	2026-02-03 19:37:33.282934	\N	/media/channels/26/thumbnails/e9d6a36f-a9b4-4023-8b67-bb7c0ab3ca32_thumb.jpg	\N	0.000946	0	f	\N	\N	\N	\N	f	2026-02-03 19:37:33.283886
1250	default	2026-02-03 19:37:45.827248	\N	media	uploadMediaAndCreateNote	0.106795	4	f	\N	\N	\N	\N	f	2026-02-03 19:37:45.934049
1251	default	2026-02-03 19:37:45.976777	\N	/media/channels/26/thumbnails/35f482f6-1143-419e-b5f5-eed6322fa58b_thumb.jpg	\N	0.000919	0	f	\N	\N	\N	\N	f	2026-02-03 19:37:45.977703
1252	default	2026-02-03 19:37:50.611778	\N	chat	createNote	0.013364	3	f	\N	\N	\N	\N	f	2026-02-03 19:37:50.62515
1253	default	2026-02-03 19:37:53.604785	\N	chat	deleteNote	0.013109	3	f	\N	\N	\N	\N	f	2026-02-03 19:37:53.617908
1081	default	2026-02-03 16:18:00.616818	\N	InternalSession	\N	0.005326	1	f	\N	\N	\N	\N	f	2026-02-03 16:18:00.622173
931	default	2026-02-03 06:52:44.667312	\N	/media/channels/23/thumbnails/a0baf66b-841b-4ef6-9723-bbd1e1bb7432_thumb.jpg	\N	0.00075	0	f	\N	\N	\N	\N	f	2026-02-03 06:52:44.668065
930	default	2026-02-03 06:52:44.667831	\N	/media/channels/23/thumbnails/9b0348b8-1f78-42ca-b026-56ecbfab7804_thumb.jpg	\N	0.000528	0	f	\N	\N	\N	\N	f	2026-02-03 06:52:44.668361
932	default	2026-02-03 06:52:47.39939	\N	media	uploadMediaAndCreateNote	0.197668	4	f	\N	\N	\N	\N	f	2026-02-03 06:52:47.597064
933	default	2026-02-03 06:52:47.638674	\N	/media/channels/23/thumbnails/1fed8b47-d5d4-46f6-a7ed-2e9dc2b0beea_thumb.jpg	\N	0.001647	0	f	\N	\N	\N	\N	f	2026-02-03 06:52:47.640328
934	default	2026-02-03 06:52:54.147159	\N	media	uploadMediaAndCreateNote	0.147462	4	f	\N	\N	\N	\N	f	2026-02-03 06:52:54.294626
935	default	2026-02-03 06:52:54.316158	\N	/media/channels/23/thumbnails/a193c491-cf91-40c7-bd82-892bf60ce4be_thumb.jpg	\N	0.001141	0	f	\N	\N	\N	\N	f	2026-02-03 06:52:54.317306
936	default	2026-02-03 07:19:04.554907	\N	InternalSession	\N	0.005763	1	f	\N	\N	\N	\N	f	2026-02-03 07:19:04.560697
937	default	2026-02-03 07:19:12.77962	\N	chat	getChannels	0.007964	1	f	\N	\N	\N	\N	f	2026-02-03 07:19:12.787591
938	default	2026-02-03 07:19:12.890703	\N	chat	getNotes	0.009714	1	f	\N	\N	\N	\N	f	2026-02-03 07:19:12.900421
940	default	2026-02-03 07:19:19.617466	\N	chat	getNotes	0.01111	1	f	\N	\N	\N	\N	f	2026-02-03 07:19:19.628587
941	default	2026-02-03 07:19:19.619352	\N	chat	getNotes	0.017315	1	f	\N	\N	\N	\N	f	2026-02-03 07:19:19.636687
943	default	2026-02-03 07:19:21.739643	\N	/media/channels/23/thumbnails/1fed8b47-d5d4-46f6-a7ed-2e9dc2b0beea_thumb.jpg	\N	0.037069	0	f	\N	\N	\N	\N	f	2026-02-03 07:19:21.776716
944	default	2026-02-03 07:19:21.740213	\N	/media/channels/23/thumbnails/a0baf66b-841b-4ef6-9723-bbd1e1bb7432_thumb.jpg	\N	0.036812	0	f	\N	\N	\N	\N	f	2026-02-03 07:19:21.777026
945	default	2026-02-03 07:19:21.740624	\N	/media/channels/23/thumbnails/9b0348b8-1f78-42ca-b026-56ecbfab7804_thumb.jpg	\N	0.036688	0	f	\N	\N	\N	\N	f	2026-02-03 07:19:21.777314
942	default	2026-02-03 07:19:21.737416	\N	/media/channels/23/thumbnails/a193c491-cf91-40c7-bd82-892bf60ce4be_thumb.jpg	\N	0.03854	0	f	\N	\N	\N	\N	f	2026-02-03 07:19:21.775974
946	default	2026-02-03 07:19:29.454595	\N	chat	getChannels	0.004159	1	f	\N	\N	\N	\N	f	2026-02-03 07:19:29.458758
947	default	2026-02-03 07:19:29.503596	\N	chat	getNotes	0.003799	1	f	\N	\N	\N	\N	f	2026-02-03 07:19:29.507398
950	default	2026-02-03 07:19:29.588074	\N	chat	getNotes	0.008978	1	f	\N	\N	\N	\N	f	2026-02-03 07:19:29.597053
949	default	2026-02-03 07:19:29.588804	\N	chat	getNotes	0.007606	1	f	\N	\N	\N	\N	f	2026-02-03 07:19:29.596414
927	default	2026-02-03 06:52:43.703054	\N	chat	chat	\N	\N	\N	\N	\N	\N	\N	f	2026-02-03 06:53:00.01894
951	default	2026-02-03 07:20:04.891985	\N	media	uploadMediaAndCreateNote	0.232914	4	f	\N	\N	\N	\N	f	2026-02-03 07:20:05.124914
952	default	2026-02-03 07:20:05.184686	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.001523	0	f	\N	\N	\N	\N	f	2026-02-03 07:20:05.186229
939	default	2026-02-03 07:19:12.906387	\N	chat	chat	876.252402	0	f	\N	\N	\N	\N	f	2026-02-03 07:33:49.158889
953	default	2026-02-03 07:33:59.936656	\N	chat	getChannels	0.004725	1	f	\N	\N	\N	\N	f	2026-02-03 07:33:59.941386
954	default	2026-02-03 07:33:59.937607	\N	chat	getChannels	0.007382	1	f	\N	\N	\N	\N	f	2026-02-03 07:33:59.945004
957	default	2026-02-03 07:34:01.349365	\N	chat	getChannels	0.003966	1	f	\N	\N	\N	\N	f	2026-02-03 07:34:01.353334
956	default	2026-02-03 07:34:01.349925	\N	chat	getChannels	0.003736	1	f	\N	\N	\N	\N	f	2026-02-03 07:34:01.353662
959	default	2026-02-03 07:34:01.497133	\N	chat	getNotes	0.007745	1	f	\N	\N	\N	\N	f	2026-02-03 07:34:01.504883
960	default	2026-02-03 07:34:01.496287	\N	chat	getNotes	0.007523	1	f	\N	\N	\N	\N	f	2026-02-03 07:34:01.503814
961	default	2026-02-03 07:34:01.713483	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.001952	0	f	\N	\N	\N	\N	f	2026-02-03 07:34:01.715443
948	default	2026-02-03 07:19:29.554206	\N	chat	chat	876.136985	0	f	\N	\N	\N	\N	f	2026-02-03 07:34:05.691221
955	default	2026-02-03 07:34:00.044818	\N	chat	chat	98.656466	0	f	\N	\N	\N	\N	f	2026-02-03 07:35:38.701353
963	default	2026-02-03 07:35:48.795559	\N	chat	getChannels	0.005787	1	f	\N	\N	\N	\N	f	2026-02-03 07:35:48.80135
962	default	2026-02-03 07:35:48.796595	\N	chat	getChannels	0.005137	1	f	\N	\N	\N	\N	f	2026-02-03 07:35:48.801733
965	default	2026-02-03 07:36:24.014869	\N	chat	getNotes	0.01163	1	f	\N	\N	\N	\N	f	2026-02-03 07:36:24.026502
966	default	2026-02-03 07:36:24.013935	\N	chat	getNotes	0.011519	1	f	\N	\N	\N	\N	f	2026-02-03 07:36:24.025459
967	default	2026-02-03 07:36:24.281084	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.00061	0	f	\N	\N	\N	\N	f	2026-02-03 07:36:24.281707
968	default	2026-02-03 07:36:29.552578	\N	chat	getChannels	0.007607	1	f	\N	\N	\N	\N	f	2026-02-03 07:36:29.560187
969	default	2026-02-03 07:36:29.553964	\N	chat	getChannels	0.005652	1	f	\N	\N	\N	\N	f	2026-02-03 07:36:29.559621
971	default	2026-02-03 07:36:29.699599	\N	chat	getNotes	0.009537	1	f	\N	\N	\N	\N	f	2026-02-03 07:36:29.70915
972	default	2026-02-03 07:36:29.698885	\N	chat	getNotes	0.011121	1	f	\N	\N	\N	\N	f	2026-02-03 07:36:29.710009
973	default	2026-02-03 07:36:29.939116	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.000561	0	f	\N	\N	\N	\N	f	2026-02-03 07:36:29.939683
958	default	2026-02-03 07:34:01.458951	\N	chat	chat	152.311885	0	f	\N	\N	\N	\N	f	2026-02-03 07:36:33.770846
974	default	2026-02-03 07:36:37.745469	\N	chat	getChannels	0.003794	1	f	\N	\N	\N	\N	f	2026-02-03 07:36:37.749273
975	default	2026-02-03 07:36:37.744932	\N	chat	getChannels	0.004823	1	f	\N	\N	\N	\N	f	2026-02-03 07:36:37.749757
970	default	2026-02-03 07:36:29.65621	\N	chat	chat	1088.582125	0	f	\N	\N	\N	\N	f	2026-02-03 07:54:38.238444
976	default	2026-02-03 07:36:37.795175	\N	chat	chat	1080.445314	0	f	\N	\N	\N	\N	f	2026-02-03 07:54:38.240492
964	default	2026-02-03 07:35:48.885623	\N	chat	chat	1129.354261	0	f	\N	\N	\N	\N	f	2026-02-03 07:54:38.239887
977	default	2026-02-03 09:05:19.042644	\N	InternalSession	\N	0.005776	1	f	\N	\N	\N	\N	f	2026-02-03 09:05:19.048449
978	default	2026-02-03 09:05:34.594174	\N	chat	getChannels	0.014166	1	f	\N	\N	\N	\N	f	2026-02-03 09:05:34.608342
979	default	2026-02-03 09:05:34.598329	\N	chat	getChannels	0.00928	1	f	\N	\N	\N	\N	f	2026-02-03 09:05:34.607619
982	default	2026-02-03 09:05:34.808547	\N	chat	getNotes	0.02936	1	f	\N	\N	\N	\N	f	2026-02-03 09:05:34.83792
981	default	2026-02-03 09:05:34.810406	\N	chat	getNotes	0.030628	1	f	\N	\N	\N	\N	f	2026-02-03 09:05:34.841061
983	default	2026-02-03 09:05:35.061502	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.018687	0	f	\N	\N	\N	\N	f	2026-02-03 09:05:35.080212
985	default	2026-02-03 09:05:37.22546	\N	chat	getChannels	0.007447	1	f	\N	\N	\N	\N	f	2026-02-03 09:05:37.232912
984	default	2026-02-03 09:05:37.227175	\N	chat	getChannels	0.006621	1	f	\N	\N	\N	\N	f	2026-02-03 09:05:37.233801
988	default	2026-02-03 09:05:37.373151	\N	chat	getNotes	0.020099	1	f	\N	\N	\N	\N	f	2026-02-03 09:05:37.393264
987	default	2026-02-03 09:05:37.371729	\N	chat	getNotes	0.025737	1	f	\N	\N	\N	\N	f	2026-02-03 09:05:37.397474
989	default	2026-02-03 09:05:37.631883	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.001756	0	f	\N	\N	\N	\N	f	2026-02-03 09:05:37.633645
980	default	2026-02-03 09:05:34.818389	\N	chat	chat	1795.49277	0	f	\N	\N	\N	\N	f	2026-02-03 09:35:30.311282
986	default	2026-02-03 09:05:37.336559	\N	chat	chat	1792.977348	0	f	\N	\N	\N	\N	f	2026-02-03 09:35:30.313914
1049	default	2026-02-03 16:03:14.917195	\N	media	uploadMediaAndCreateNote	0.766558	3	f	DatabaseQueryException: { message: column "duration" of relation "media_attachments" does not exist, code: 42703, position: 132 }	#0      _PgSessionBase._prepare (package:postgres/src/v3/connection.dart:199:35)\n#1      _PgSessionBase.execute (package:postgres/src/v3/connection.dart:183:30)\n#2      DatabaseConnection._query (package:serverpod/src/database/adapters/postgres/database_connection.dart:527:34)\n#3      DatabaseConnection._mappedResultsQuery (package:serverpod/src/database/adapters/postgres/database_connection.dart:626:24)\n#4      DatabaseConnection.insert (package:serverpod/src/database/adapters/postgres/database_connection.dart:147:19)\n#5      DatabaseConnection.insertRow (package:serverpod/src/database/adapters/postgres/database_connection.dart:162:24)\n#6      Database.insertRow (package:serverpod/src/database/database.dart:239:32)\n#7      MediaAttachmentRepository.insertRow (package:on_air_server/src/generated/media/media_attachment.dart:659:23)\n#8      MediaEndpoint.uploadMediaAndCreateNote.<anonymous closure> (package:on_air_server/src/media/media_endpoint.dart:214:34)\n<asynchronous suspension>\n#9      PgConnectionImplementation.runTx.<anonymous closure> (package:postgres/src/v3/connection.dart:591:24)\n<asynchronous suspension>\n#10     Pool.withResource (package:pool/pool.dart:127:14)\n<asynchronous suspension>\n#11     PoolImplementation.withConnection (package:postgres/src/pool/pool_impl.dart:153:16)\n<asynchronous suspension>\n#12     Database.transaction (package:serverpod/src/database/database.dart:399:12)\n<asynchronous suspension>\n#13     MediaEndpoint.uploadMediaAndCreateNote (package:on_air_server/src/media/media_endpoint.dart:184:20)\n<asynchronous suspension>\n#14     Server._handleEndpointCall (package:serverpod/src/server/server.dart:444:22)\n<asynchronous suspension>\n#15     Server._endpoints (package:serverpod/src/server/server.dart:311:12)\n<asynchronous suspension>\n#16     Server._reportException.<anonymous closure> (package:serverpod/src/server/server.dart:205:16)\n<asynchronous suspension>\n#17     Server._headers.<anonymous closure> (package:serverpod/src/server/server.dart:286:22)\n<asynchronous suspension>\n#18     _RoutingMiddlewareBuilder.call.<anonymous closure> (package:relic/src/middleware/routing_middleware.dart:121:18)\n<asynchronous suspension>\n#19     _RelicServer._wrapHandlerWithMiddleware.<anonymous closure> (package:relic/src/relic_server.dart:151:24)\n<asynchronous suspension>\n#20     _RelicServer._handleRequest (package:relic/src/relic_server.dart:127:22)\n<asynchronous suspension>\n	\N	\N	f	2026-02-03 16:03:15.683756
990	default	2026-02-03 09:05:49.289212	\N	/media/channels/23/thumbnails/1fed8b47-d5d4-46f6-a7ed-2e9dc2b0beea_thumb.jpg	\N	0.007291	0	f	\N	\N	\N	\N	f	2026-02-03 09:05:49.296518
994	default	2026-02-03 09:05:58.14244	\N	media	uploadMediaAndCreateNote	0.166793	1	f	Exception: Failed to decode image	#0      ImageProcessor._processInIsolate (package:on_air_server/src/media/image_processor.dart:105:7)\n<asynchronous suspension>\n#1      ImageProcessor.processImage (package:on_air_server/src/media/image_processor.dart:88:12)\n<asynchronous suspension>\n#2      MediaEndpoint.uploadMediaAndCreateNote (package:on_air_server/src/media/media_endpoint.dart:128:24)\n<asynchronous suspension>\n#3      Server._handleEndpointCall (package:serverpod/src/server/server.dart:444:22)\n<asynchronous suspension>\n#4      Server._endpoints (package:serverpod/src/server/server.dart:311:12)\n<asynchronous suspension>\n#5      Server._reportException.<anonymous closure> (package:serverpod/src/server/server.dart:205:16)\n<asynchronous suspension>\n#6      Server._headers.<anonymous closure> (package:serverpod/src/server/server.dart:286:22)\n<asynchronous suspension>\n#7      _RoutingMiddlewareBuilder.call.<anonymous closure> (package:relic/src/middleware/routing_middleware.dart:121:18)\n<asynchronous suspension>\n#8      _RelicServer._wrapHandlerWithMiddleware.<anonymous closure> (package:relic/src/relic_server.dart:151:24)\n<asynchronous suspension>\n#9      _RelicServer._handleRequest (package:relic/src/relic_server.dart:127:22)\n<asynchronous suspension>\n	\N	\N	f	2026-02-03 09:05:58.309244
1050	default	2026-02-03 16:05:43.71329	\N	chat	getChannels	0.005366	1	f	\N	\N	\N	\N	f	2026-02-03 16:05:43.71866
995	default	2026-02-03 09:06:13.578608	\N	media	uploadMediaAndCreateNote	0.143244	1	f	Exception: Failed to decode image	#0      ImageProcessor._processInIsolate (package:on_air_server/src/media/image_processor.dart:105:7)\n<asynchronous suspension>\n#1      ImageProcessor.processImage (package:on_air_server/src/media/image_processor.dart:88:12)\n<asynchronous suspension>\n#2      MediaEndpoint.uploadMediaAndCreateNote (package:on_air_server/src/media/media_endpoint.dart:128:24)\n<asynchronous suspension>\n#3      Server._handleEndpointCall (package:serverpod/src/server/server.dart:444:22)\n<asynchronous suspension>\n#4      Server._endpoints (package:serverpod/src/server/server.dart:311:12)\n<asynchronous suspension>\n#5      Server._reportException.<anonymous closure> (package:serverpod/src/server/server.dart:205:16)\n<asynchronous suspension>\n#6      Server._headers.<anonymous closure> (package:serverpod/src/server/server.dart:286:22)\n<asynchronous suspension>\n#7      _RoutingMiddlewareBuilder.call.<anonymous closure> (package:relic/src/middleware/routing_middleware.dart:121:18)\n<asynchronous suspension>\n#8      _RelicServer._wrapHandlerWithMiddleware.<anonymous closure> (package:relic/src/relic_server.dart:151:24)\n<asynchronous suspension>\n#9      _RelicServer._handleRequest (package:relic/src/relic_server.dart:127:22)\n<asynchronous suspension>\n	\N	\N	f	2026-02-03 09:06:13.721858
1260	default	2026-02-03 19:40:46.629023	\N	chat	getNotes	0.011906	1	f	\N	\N	\N	\N	f	2026-02-03 19:40:46.64093
1053	default	2026-02-03 16:05:46.716697	\N	chat	getChannels	0.008675	1	f	\N	\N	\N	\N	f	2026-02-03 16:05:46.725378
1216	default	2026-02-03 19:34:15.422859	\N	chat	chat	414.490263	0	f	\N	\N	\N	\N	f	2026-02-03 19:41:09.913135
1057	default	2026-02-03 16:05:46.868559	\N	chat	getNotes	0.017869	1	f	\N	\N	\N	\N	f	2026-02-03 16:05:46.886439
1059	default	2026-02-03 16:05:55.675327	\N	media	uploadMediaAndCreateNote	0.763061	4	f	\N	\N	\N	\N	f	2026-02-03 16:05:56.438401
1060	default	2026-02-03 16:05:56.474524	\N	/media/channels/25/thumbnails/151e5f11-6d1a-44f7-952e-22d962c1b5df_thumb.jpg	\N	0.001313	0	f	\N	\N	\N	\N	f	2026-02-03 16:05:56.475855
1061	default	2026-02-03 16:06:14.114061	\N	media	uploadMediaAndCreateNote	8.276595	4	t	\N	\N	\N	\N	f	2026-02-03 16:06:22.390665
1062	default	2026-02-03 16:06:27.528704	\N	media	uploadMediaAndCreateNote	0.124829	4	f	\N	\N	\N	\N	f	2026-02-03 16:06:27.653539
1063	default	2026-02-03 16:06:27.694862	\N	/media/channels/25/thumbnails/0bf8c3ea-ae09-4ad0-86fc-0136fc0d1db5_thumb.jpg	\N	0.001019	0	f	\N	\N	\N	\N	f	2026-02-03 16:06:27.695886
1064	default	2026-02-03 16:06:28.77998	\N	media	uploadMediaAndCreateNote	0.122935	4	f	\N	\N	\N	\N	f	2026-02-03 16:06:28.902921
1052	default	2026-02-03 16:05:43.803236	\N	chat	chat	402.712907	0	f	\N	\N	\N	\N	f	2026-02-03 16:12:26.516157
1055	default	2026-02-03 16:05:46.825436	\N	chat	chat	426.401289	0	f	\N	\N	\N	\N	f	2026-02-03 16:12:53.226759
1083	default	2026-02-03 16:20:47.157889	\N	chat	getChannels	0.02491	1	f	\N	\N	\N	\N	f	2026-02-03 16:20:47.182869
1086	default	2026-02-03 16:20:47.355017	\N	chat	getNotes	0.025976	1	f	\N	\N	\N	\N	f	2026-02-03 16:20:47.381005
1094	default	2026-02-03 16:22:16.129118	\N	chat	getNotes	0.024597	1	f	\N	\N	\N	\N	f	2026-02-03 16:22:16.153718
1101	default	2026-02-03 16:24:07.982786	\N	chat	getNotes	0.008278	1	f	\N	\N	\N	\N	f	2026-02-03 16:24:07.991068
1127	default	2026-02-03 16:29:08.574187	\N	chat	getChannels	0.019951	1	f	\N	\N	\N	\N	f	2026-02-03 16:29:08.594152
1131	default	2026-02-03 16:29:09.064231	\N	chat	getChannels	0.01114	1	f	\N	\N	\N	\N	f	2026-02-03 16:29:09.075373
1133	default	2026-02-03 16:29:09.322954	\N	chat	getNotes	0.025785	1	f	\N	\N	\N	\N	f	2026-02-03 16:29:09.348743
1143	default	2026-02-03 16:34:00.377029	\N	chat	chat	9.375692	0	f	\N	\N	\N	\N	f	2026-02-03 16:34:09.752745
1207	default	2026-02-03 19:09:06.037294	\N	chat	getNotes	0.008454	1	f	\N	\N	\N	\N	f	2026-02-03 19:09:06.045749
1213	default	2026-02-03 19:34:01.725629	\N	InternalSession	\N	0.007805	1	f	\N	\N	\N	\N	f	2026-02-03 19:34:01.733465
1214	default	2026-02-03 19:34:15.335376	\N	chat	getChannels	0.011295	1	f	\N	\N	\N	\N	f	2026-02-03 19:34:15.34668
1217	default	2026-02-03 19:34:17.566701	\N	chat	getChannels	0.00558	1	f	\N	\N	\N	\N	f	2026-02-03 19:34:17.572294
1221	default	2026-02-03 19:34:18.312291	\N	chat	getNotes	0.03494	1	f	\N	\N	\N	\N	f	2026-02-03 19:34:18.347256
1220	default	2026-02-03 19:34:18.315724	\N	chat	getNotes	0.034084	1	f	\N	\N	\N	\N	f	2026-02-03 19:34:18.349821
1224	default	2026-02-03 19:34:19.00603	\N	/media/channels/14/thumbnails/fc7df6f1-086e-42ba-9ffd-4d8d8be15930_thumb.jpg	\N	0.042448	0	f	\N	\N	\N	\N	f	2026-02-03 19:34:19.048659
1225	default	2026-02-03 19:34:19.001502	\N	/media/channels/14/thumbnails/7971e7dc-b2b3-47f7-a5c2-1fa8b37bc074_thumb.jpg	\N	0.04879	0	f	\N	\N	\N	\N	f	2026-02-03 19:34:19.050304
1226	default	2026-02-03 19:34:36.144584	\N	chat	deleteNote	0.027212	3	f	\N	\N	\N	\N	f	2026-02-03 19:34:36.171807
1227	default	2026-02-03 19:35:08.83382	\N	chat	createNote	0.015632	3	f	\N	\N	\N	\N	f	2026-02-03 19:35:08.849458
1228	default	2026-02-03 19:35:12.425333	\N	chat	createNote	0.015849	3	f	\N	\N	\N	\N	f	2026-02-03 19:35:12.441193
991	default	2026-02-03 09:05:49.293226	\N	/media/channels/23/thumbnails/9b0348b8-1f78-42ca-b026-56ecbfab7804_thumb.jpg	\N	0.004659	0	f	\N	\N	\N	\N	f	2026-02-03 09:05:49.297898
1051	default	2026-02-03 16:05:43.714044	\N	chat	getChannels	0.005556	1	f	\N	\N	\N	\N	f	2026-02-03 16:05:43.719602
1054	default	2026-02-03 16:05:46.718179	\N	chat	getChannels	0.006098	1	f	\N	\N	\N	\N	f	2026-02-03 16:05:46.724289
1056	default	2026-02-03 16:05:46.870291	\N	chat	getNotes	0.012693	1	f	\N	\N	\N	\N	f	2026-02-03 16:05:46.882993
1082	default	2026-02-03 16:20:47.152469	\N	chat	getChannels	0.032053	1	f	\N	\N	\N	\N	f	2026-02-03 16:20:47.184525
1085	default	2026-02-03 16:20:47.35264	\N	chat	getNotes	0.031654	1	f	\N	\N	\N	\N	f	2026-02-03 16:20:47.384306
1084	default	2026-02-03 16:20:47.280122	\N	chat	chat	68.374897	0	f	\N	\N	\N	\N	f	2026-02-03 16:21:55.6551
1103	default	2026-02-03 16:26:25.486719	\N	InternalSession	\N	0.005674	1	f	\N	\N	\N	\N	f	2026-02-03 16:26:25.492434
1104	default	2026-02-03 16:26:34.706697	\N	chat	getChannels	0.026055	1	f	\N	\N	\N	\N	f	2026-02-03 16:26:34.732755
1107	default	2026-02-03 16:26:34.877564	\N	chat	getNotes	0.03062	1	f	\N	\N	\N	\N	f	2026-02-03 16:26:34.908196
1110	default	2026-02-03 16:26:35.117343	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.01906	0	f	\N	\N	\N	\N	f	2026-02-03 16:26:35.136418
1106	default	2026-02-03 16:26:34.887503	\N	chat	chat	12.904226	0	f	\N	\N	\N	\N	f	2026-02-03 16:26:47.791778
1112	default	2026-02-03 16:27:21.211383	\N	chat	getChannels	0.007567	1	f	\N	\N	\N	\N	f	2026-02-03 16:27:21.218959
1114	default	2026-02-03 16:27:21.457109	\N	chat	getNotes	0.015919	1	f	\N	\N	\N	\N	f	2026-02-03 16:27:21.473036
1117	default	2026-02-03 16:27:21.76535	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.001178	0	f	\N	\N	\N	\N	f	2026-02-03 16:27:21.766553
1118	default	2026-02-03 16:27:24.775089	\N	chat	getChannels	0.008303	1	f	\N	\N	\N	\N	f	2026-02-03 16:27:24.783398
1123	default	2026-02-03 16:27:24.912984	\N	chat	getNotes	0.013858	1	f	\N	\N	\N	\N	f	2026-02-03 16:27:24.926848
1124	default	2026-02-03 16:27:26.399141	\N	/media/channels/25/thumbnails/151e5f11-6d1a-44f7-952e-22d962c1b5df_thumb.jpg	\N	0.002349	0	f	\N	\N	\N	\N	f	2026-02-03 16:27:26.401497
1113	default	2026-02-03 16:27:21.396949	\N	chat	chat	87.190397	0	f	\N	\N	\N	\N	f	2026-02-03 16:28:48.587388
1120	default	2026-02-03 16:27:24.871572	\N	chat	chat	83.718287	0	f	\N	\N	\N	\N	f	2026-02-03 16:28:48.589869
1135	default	2026-02-03 16:29:09.324346	\N	chat	getNotes	0.012767	1	f	\N	\N	\N	\N	f	2026-02-03 16:29:09.337126
1144	default	2026-02-03 16:34:00.626091	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.012776	0	f	\N	\N	\N	\N	f	2026-02-03 16:34:00.638883
1145	default	2026-02-03 16:34:23.640525	\N	chat	getChannels	0.005804	1	f	\N	\N	\N	\N	f	2026-02-03 16:34:23.646332
1150	default	2026-02-03 16:34:23.862017	\N	chat	getNotes	0.010746	1	f	\N	\N	\N	\N	f	2026-02-03 16:34:23.872774
1151	default	2026-02-03 16:34:24.116124	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.001119	0	f	\N	\N	\N	\N	f	2026-02-03 16:34:24.11726
1153	default	2026-02-03 16:34:35.037361	\N	chat	getChannels	0.007971	1	f	\N	\N	\N	\N	f	2026-02-03 16:34:35.045337
1156	default	2026-02-03 16:34:35.178571	\N	chat	getNotes	0.011016	1	f	\N	\N	\N	\N	f	2026-02-03 16:34:35.18959
1158	default	2026-02-03 16:35:36.498776	\N	media	uploadMediaAndCreateNote	9.356624	4	t	\N	\N	\N	\N	f	2026-02-03 16:35:45.85541
1159	default	2026-02-03 16:35:45.951359	\N	/media/channels/14/thumbnails/fc7df6f1-086e-42ba-9ffd-4d8d8be15930_thumb.jpg	\N	0.001548	0	f	\N	\N	\N	\N	f	2026-02-03 16:35:45.952915
1160	default	2026-02-03 16:36:51.022556	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.097511	0	f	\N	\N	\N	\N	f	2026-02-03 16:36:51.120092
1161	default	2026-02-03 16:36:51.132972	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.007533	0	f	\N	\N	\N	\N	f	2026-02-03 16:36:51.140546
1162	default	2026-02-03 16:36:51.156884	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.000387	0	f	\N	\N	\N	\N	f	2026-02-03 16:36:51.157281
1163	default	2026-02-03 16:36:51.166024	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.000313	0	f	\N	\N	\N	\N	f	2026-02-03 16:36:51.166341
1164	default	2026-02-03 16:36:51.173965	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.000332	0	f	\N	\N	\N	\N	f	2026-02-03 16:36:51.174302
1165	default	2026-02-03 16:36:51.18302	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.000445	0	f	\N	\N	\N	\N	f	2026-02-03 16:36:51.183472
1166	default	2026-02-03 16:36:51.199016	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.000345	0	f	\N	\N	\N	\N	f	2026-02-03 16:36:51.199366
1167	default	2026-02-03 16:36:51.208456	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.000448	0	f	\N	\N	\N	\N	f	2026-02-03 16:36:51.208916
1168	default	2026-02-03 16:36:51.224934	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.000398	0	f	\N	\N	\N	\N	f	2026-02-03 16:36:51.225337
1169	default	2026-02-03 16:36:51.23328	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.000301	0	f	\N	\N	\N	\N	f	2026-02-03 16:36:51.233585
1170	default	2026-02-03 16:36:51.242618	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.000831	0	f	\N	\N	\N	\N	f	2026-02-03 16:36:51.243457
1171	default	2026-02-03 16:36:51.257571	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.000444	0	f	\N	\N	\N	\N	f	2026-02-03 16:36:51.258021
1172	default	2026-02-03 16:36:51.274002	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.00051	0	f	\N	\N	\N	\N	f	2026-02-03 16:36:51.274518
1173	default	2026-02-03 16:36:51.293627	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.000884	0	f	\N	\N	\N	\N	f	2026-02-03 16:36:51.294524
1175	default	2026-02-03 16:36:51.332352	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.000323	0	f	\N	\N	\N	\N	f	2026-02-03 16:36:51.332679
1176	default	2026-02-03 16:36:51.34122	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.000578	0	f	\N	\N	\N	\N	f	2026-02-03 16:36:51.341809
1177	default	2026-02-03 16:37:00.199498	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.001803	0	f	\N	\N	\N	\N	f	2026-02-03 16:37:00.20131
1178	default	2026-02-03 16:37:00.21091	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.00052	0	f	\N	\N	\N	\N	f	2026-02-03 16:37:00.211437
1179	default	2026-02-03 16:37:00.222156	\N	/media/channels/14/fc7df6f1-086e-42ba-9ffd-4d8d8be15930.mp4	\N	0.000747	0	f	\N	\N	\N	\N	f	2026-02-03 16:37:00.222911
1181	default	2026-02-03 16:41:46.497488	\N	/media/channels/25/thumbnails/0bf8c3ea-ae09-4ad0-86fc-0136fc0d1db5_thumb.jpg	\N	0.001106	0	f	\N	\N	\N	\N	f	2026-02-03 16:41:46.4986
1183	default	2026-02-03 16:56:08.140296	\N	media	uploadMediaAndCreateNote	0.099264	4	f	\N	\N	\N	\N	f	2026-02-03 16:56:08.239567
1184	default	2026-02-03 16:56:20.412542	\N	media	uploadMediaAndCreateNote	0.458802	4	f	\N	\N	\N	\N	f	2026-02-03 16:56:20.871353
1185	default	2026-02-03 16:56:20.937001	\N	/media/channels/14/thumbnails/7971e7dc-b2b3-47f7-a5c2-1fa8b37bc074_thumb.jpg	\N	0.001564	0	f	\N	\N	\N	\N	f	2026-02-03 16:56:20.938574
1186	default	2026-02-03 17:44:09.782499	\N	/media/channels/25/thumbnails/151e5f11-6d1a-44f7-952e-22d962c1b5df_thumb.jpg	\N	0.002875	0	f	\N	\N	\N	\N	f	2026-02-03 17:44:09.785399
1188	default	2026-02-03 17:45:07.90441	\N	chat	createNote	0.014056	3	f	\N	\N	\N	\N	f	2026-02-03 17:45:07.918478
1189	default	2026-02-03 17:45:30.898234	\N	chat	createNote	0.014949	3	f	\N	\N	\N	\N	f	2026-02-03 17:45:30.913201
1147	default	2026-02-03 16:34:23.81307	\N	chat	chat	8237.914318	0	f	\N	\N	\N	\N	f	2026-02-03 18:51:41.727603
1258	default	2026-02-03 19:40:46.629583	\N	chat	getNotes	0.010326	1	f	\N	\N	\N	\N	f	2026-02-03 19:40:46.63992
992	default	2026-02-03 09:05:49.290533	\N	/media/channels/23/thumbnails/a193c491-cf91-40c7-bd82-892bf60ce4be_thumb.jpg	\N	0.008597	0	f	\N	\N	\N	\N	f	2026-02-03 09:05:49.299146
993	default	2026-02-03 09:05:49.291634	\N	/media/channels/23/thumbnails/a0baf66b-841b-4ef6-9723-bbd1e1bb7432_thumb.jpg	\N	0.008567	0	f	\N	\N	\N	\N	f	2026-02-03 09:05:49.300207
996	default	2026-02-03 09:06:33.63467	\N	media	uploadMediaAndCreateNote	0.114287	1	f	Exception: Failed to decode image	#0      ImageProcessor._processInIsolate (package:on_air_server/src/media/image_processor.dart:105:7)\n<asynchronous suspension>\n#1      ImageProcessor.processImage (package:on_air_server/src/media/image_processor.dart:88:12)\n<asynchronous suspension>\n#2      MediaEndpoint.uploadMediaAndCreateNote (package:on_air_server/src/media/media_endpoint.dart:128:24)\n<asynchronous suspension>\n#3      Server._handleEndpointCall (package:serverpod/src/server/server.dart:444:22)\n<asynchronous suspension>\n#4      Server._endpoints (package:serverpod/src/server/server.dart:311:12)\n<asynchronous suspension>\n#5      Server._reportException.<anonymous closure> (package:serverpod/src/server/server.dart:205:16)\n<asynchronous suspension>\n#6      Server._headers.<anonymous closure> (package:serverpod/src/server/server.dart:286:22)\n<asynchronous suspension>\n#7      _RoutingMiddlewareBuilder.call.<anonymous closure> (package:relic/src/middleware/routing_middleware.dart:121:18)\n<asynchronous suspension>\n#8      _RelicServer._wrapHandlerWithMiddleware.<anonymous closure> (package:relic/src/relic_server.dart:151:24)\n<asynchronous suspension>\n#9      _RelicServer._handleRequest (package:relic/src/relic_server.dart:127:22)\n<asynchronous suspension>\n	\N	\N	f	2026-02-03 09:06:33.748961
997	default	2026-02-03 09:08:37.635297	\N	media	uploadMediaAndCreateNote	0.112531	1	f	Exception: Failed to decode image	#0      ImageProcessor._processInIsolate (package:on_air_server/src/media/image_processor.dart:105:7)\n<asynchronous suspension>\n#1      ImageProcessor.processImage (package:on_air_server/src/media/image_processor.dart:88:12)\n<asynchronous suspension>\n#2      MediaEndpoint.uploadMediaAndCreateNote (package:on_air_server/src/media/media_endpoint.dart:128:24)\n<asynchronous suspension>\n#3      Server._handleEndpointCall (package:serverpod/src/server/server.dart:444:22)\n<asynchronous suspension>\n#4      Server._endpoints (package:serverpod/src/server/server.dart:311:12)\n<asynchronous suspension>\n#5      Server._reportException.<anonymous closure> (package:serverpod/src/server/server.dart:205:16)\n<asynchronous suspension>\n#6      Server._headers.<anonymous closure> (package:serverpod/src/server/server.dart:286:22)\n<asynchronous suspension>\n#7      _RoutingMiddlewareBuilder.call.<anonymous closure> (package:relic/src/middleware/routing_middleware.dart:121:18)\n<asynchronous suspension>\n#8      _RelicServer._wrapHandlerWithMiddleware.<anonymous closure> (package:relic/src/relic_server.dart:151:24)\n<asynchronous suspension>\n#9      _RelicServer._handleRequest (package:relic/src/relic_server.dart:127:22)\n<asynchronous suspension>\n	\N	\N	f	2026-02-03 09:08:37.747832
998	default	2026-02-03 14:59:19.803669	\N	InternalSession	\N	0.005551	1	f	\N	\N	\N	\N	f	2026-02-03 14:59:19.809247
999	default	2026-02-03 15:08:01.744567	\N	chat	getChannels	0.015081	1	f	\N	\N	\N	\N	f	2026-02-03 15:08:01.759654
1000	default	2026-02-03 15:08:01.748258	\N	chat	getChannels	0.012072	1	f	\N	\N	\N	\N	f	2026-02-03 15:08:01.760331
1003	default	2026-02-03 15:08:01.946972	\N	chat	getNotes	0.027858	1	f	\N	\N	\N	\N	f	2026-02-03 15:08:01.974847
1002	default	2026-02-03 15:08:01.94892	\N	chat	getNotes	0.030599	1	f	\N	\N	\N	\N	f	2026-02-03 15:08:01.979526
1004	default	2026-02-03 15:08:02.27352	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.012007	0	f	\N	\N	\N	\N	f	2026-02-03 15:08:02.285542
1005	default	2026-02-03 15:08:05.080316	\N	chat	getChannels	0.004806	1	f	\N	\N	\N	\N	f	2026-02-03 15:08:05.085129
1006	default	2026-02-03 15:08:05.078858	\N	chat	getChannels	0.007319	1	f	\N	\N	\N	\N	f	2026-02-03 15:08:05.08618
1001	default	2026-02-03 15:08:01.954716	\N	chat	chat	2135.751121	0	f	\N	\N	\N	\N	f	2026-02-03 15:43:37.705899
1007	default	2026-02-03 15:08:05.180311	\N	chat	chat	2133.499355	0	f	\N	\N	\N	\N	f	2026-02-03 15:43:38.679676
1009	default	2026-02-03 15:08:05.213469	\N	chat	getNotes	0.013181	1	f	\N	\N	\N	\N	f	2026-02-03 15:08:05.22666
1008	default	2026-02-03 15:08:05.215251	\N	chat	getNotes	0.013031	1	f	\N	\N	\N	\N	f	2026-02-03 15:08:05.228287
1010	default	2026-02-03 15:08:05.429349	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.003804	0	f	\N	\N	\N	\N	f	2026-02-03 15:08:05.433166
1058	default	2026-02-03 16:05:46.872696	\N	chat	getNotes	0.016142	1	f	\N	\N	\N	\N	f	2026-02-03 16:05:46.888848
1087	default	2026-02-03 16:20:47.355969	\N	chat	getNotes	0.013094	1	f	\N	\N	\N	\N	f	2026-02-03 16:20:47.369084
1011	default	2026-02-03 15:08:06.590971	\N	/media/channels/23/thumbnails/a0baf66b-841b-4ef6-9723-bbd1e1bb7432_thumb.jpg	\N	0.004876	0	f	\N	\N	\N	\N	f	2026-02-03 15:08:06.595867
1012	default	2026-02-03 15:08:06.592724	\N	/media/channels/23/thumbnails/a193c491-cf91-40c7-bd82-892bf60ce4be_thumb.jpg	\N	0.005029	0	f	\N	\N	\N	\N	f	2026-02-03 15:08:06.597764
1013	default	2026-02-03 15:08:06.595129	\N	/media/channels/23/thumbnails/9b0348b8-1f78-42ca-b026-56ecbfab7804_thumb.jpg	\N	0.00501	0	f	\N	\N	\N	\N	f	2026-02-03 15:08:06.600152
1014	default	2026-02-03 15:08:06.593924	\N	/media/channels/23/thumbnails/1fed8b47-d5d4-46f6-a7ed-2e9dc2b0beea_thumb.jpg	\N	0.007418	0	f	\N	\N	\N	\N	f	2026-02-03 15:08:06.601357
1105	default	2026-02-03 16:26:34.713017	\N	chat	getChannels	0.018707	1	f	\N	\N	\N	\N	f	2026-02-03 16:26:34.731748
1015	default	2026-02-03 15:08:10.443329	\N	media	uploadMediaAndCreateNote	0.174038	4	f	\N	\N	\N	\N	f	2026-02-03 15:08:10.617384
1016	default	2026-02-03 15:08:12.786734	\N	/media/channels/14/abc20280-16b6-42d3-9327-5568a1acef2a.pdf	\N	0.004409	0	f	\N	\N	\N	\N	f	2026-02-03 15:08:12.791186
1108	default	2026-02-03 16:26:34.87939	\N	chat	getNotes	0.025769	1	f	\N	\N	\N	\N	f	2026-02-03 16:26:34.90517
1017	default	2026-02-03 15:08:12.830774	\N	/favicon.ico	\N	0.000696	0	f	\N	\N	\N	\N	f	2026-02-03 15:08:12.831487
1111	default	2026-02-03 16:27:21.213403	\N	chat	getChannels	0.007099	1	f	\N	\N	\N	\N	f	2026-02-03 16:27:21.220515
1116	default	2026-02-03 16:27:21.458483	\N	chat	getNotes	0.016365	1	f	\N	\N	\N	\N	f	2026-02-03 16:27:21.474853
1119	default	2026-02-03 16:27:24.77627	\N	chat	getChannels	0.006209	1	f	\N	\N	\N	\N	f	2026-02-03 16:27:24.782488
1122	default	2026-02-03 16:27:24.914271	\N	chat	getNotes	0.013252	1	f	\N	\N	\N	\N	f	2026-02-03 16:27:24.927526
1125	default	2026-02-03 16:27:26.398584	\N	/media/channels/25/thumbnails/0bf8c3ea-ae09-4ad0-86fc-0136fc0d1db5_thumb.jpg	\N	0.003282	0	f	\N	\N	\N	\N	f	2026-02-03 16:27:26.401867
1136	default	2026-02-03 16:30:32.273257	\N	InternalSession	\N	0.006094	1	f	\N	\N	\N	\N	f	2026-02-03 16:30:32.279399
1190	default	2026-02-03 17:45:43.645039	\N	chat	createChannel	0.007511	1	f	\N	\N	\N	\N	f	2026-02-03 17:45:43.652568
1191	default	2026-02-03 17:45:43.665501	\N	chat	getChannels	0.004985	1	f	\N	\N	\N	\N	f	2026-02-03 17:45:43.670492
1192	default	2026-02-03 17:45:43.691664	\N	chat	getNotes	0.003327	1	f	\N	\N	\N	\N	f	2026-02-03 17:45:43.694994
1193	default	2026-02-03 17:47:27.894725	\N	chat	createNote	0.009623	3	f	\N	\N	\N	\N	f	2026-02-03 17:47:27.904353
1194	default	2026-02-03 17:48:23.027055	\N	chat	createNote	0.012782	3	f	\N	\N	\N	\N	f	2026-02-03 17:48:23.03985
1195	default	2026-02-03 17:48:24.992415	\N	/media/channels/14/thumbnails/fc7df6f1-086e-42ba-9ffd-4d8d8be15930_thumb.jpg	\N	0.000806	0	f	\N	\N	\N	\N	f	2026-02-03 17:48:24.993227
1154	default	2026-02-03 16:34:35.135296	\N	chat	chat	8226.629882	0	f	\N	\N	\N	\N	f	2026-02-03 18:51:41.765191
1215	default	2026-02-03 19:34:15.338968	\N	chat	getChannels	0.008442	1	f	\N	\N	\N	\N	f	2026-02-03 19:34:15.347412
1267	default	2026-02-03 19:41:20.126438	\N	chat	getNotes	0.016685	1	f	\N	\N	\N	\N	f	2026-02-03 19:41:20.143219
1277	default	2026-02-03 19:41:24.22223	\N	chat	getNotes	0.007398	1	f	\N	\N	\N	\N	f	2026-02-03 19:41:24.229635
1291	default	2026-02-03 19:59:16.580189	\N	chat	getNotes	0.010126	1	f	\N	\N	\N	\N	f	2026-02-03 19:59:16.590318
1304	default	2026-02-03 19:59:45.735633	\N	chat	getNotes	0.012826	1	f	\N	\N	\N	\N	f	2026-02-03 19:59:45.748462
1265	default	2026-02-03 19:41:20.125153	\N	chat	getNotes	0.011967	1	f	\N	\N	\N	\N	f	2026-02-03 19:41:20.137122
1270	default	2026-02-03 19:41:20.729646	\N	/media/channels/14/thumbnails/fc7df6f1-086e-42ba-9ffd-4d8d8be15930_thumb.jpg	\N	0.000823	0	f	\N	\N	\N	\N	f	2026-02-03 19:41:20.730471
1272	default	2026-02-03 19:41:24.034798	\N	chat	getChannels	0.003182	1	f	\N	\N	\N	\N	f	2026-02-03 19:41:24.037983
1274	default	2026-02-03 19:41:24.220185	\N	chat	getNotes	0.008454	1	f	\N	\N	\N	\N	f	2026-02-03 19:41:24.228646
1279	default	2026-02-03 19:41:39.176802	\N	/media/channels/26/thumbnails/35f482f6-1143-419e-b5f5-eed6322fa58b_thumb.jpg	\N	0.001131	0	f	\N	\N	\N	\N	f	2026-02-03 19:41:39.177939
1281	default	2026-02-03 19:41:39.768614	\N	/media/channels/25/thumbnails/034048a0-39f1-4f5a-ad0e-d158a6a0693d_thumb.jpg	\N	0.00132	0	f	\N	\N	\N	\N	f	2026-02-03 19:41:39.769946
1283	default	2026-02-03 19:59:15.75579	\N	chat	getChannels	0.011886	1	f	\N	\N	\N	\N	f	2026-02-03 19:59:15.767686
1285	default	2026-02-03 19:59:16.394489	\N	chat	getChannels	0.043081	1	f	\N	\N	\N	\N	f	2026-02-03 19:59:16.43758
1288	default	2026-02-03 19:59:16.579691	\N	chat	getNotes	0.004081	1	f	\N	\N	\N	\N	f	2026-02-03 19:59:16.583775
1293	default	2026-02-03 19:59:16.784798	\N	/media/channels/14/thumbnails/fc7df6f1-086e-42ba-9ffd-4d8d8be15930_thumb.jpg	\N	0.002418	0	f	\N	\N	\N	\N	f	2026-02-03 19:59:16.787227
1295	default	2026-02-03 19:59:16.941379	\N	media	thumbnails	0.000304	0	f	\N	\N	\N	\N	f	2026-02-03 19:59:16.941694
1299	default	2026-02-03 19:59:45.604955	\N	chat	getChannels	0.003903	1	f	\N	\N	\N	\N	f	2026-02-03 19:59:45.608861
1303	default	2026-02-03 19:59:45.729996	\N	chat	getNotes	0.01672	1	f	\N	\N	\N	\N	f	2026-02-03 19:59:45.74672
1305	default	2026-02-03 19:59:45.910451	\N	media	thumbnails	0.000148	0	f	\N	\N	\N	\N	f	2026-02-03 19:59:45.910605
1268	default	2026-02-03 19:41:20.127327	\N	chat	getNotes	0.017015	1	f	\N	\N	\N	\N	f	2026-02-03 19:41:20.144346
1276	default	2026-02-03 19:41:24.223526	\N	chat	getNotes	0.007995	1	f	\N	\N	\N	\N	f	2026-02-03 19:41:24.231526
1290	default	2026-02-03 19:59:16.580459	\N	chat	getNotes	0.010763	1	f	\N	\N	\N	\N	f	2026-02-03 19:59:16.591226
1302	default	2026-02-03 19:59:45.73675	\N	chat	getNotes	0.009191	1	f	\N	\N	\N	\N	f	2026-02-03 19:59:45.745952
1269	default	2026-02-03 19:41:20.728698	\N	/media/channels/14/thumbnails/7971e7dc-b2b3-47f7-a5c2-1fa8b37bc074_thumb.jpg	\N	0.001402	0	f	\N	\N	\N	\N	f	2026-02-03 19:41:20.730107
1271	default	2026-02-03 19:41:24.033425	\N	chat	getChannels	0.003974	1	f	\N	\N	\N	\N	f	2026-02-03 19:41:24.037406
1275	default	2026-02-03 19:41:24.21894	\N	chat	getNotes	0.011668	1	f	\N	\N	\N	\N	f	2026-02-03 19:41:24.230612
1278	default	2026-02-03 19:41:39.175757	\N	/media/channels/26/thumbnails/e9d6a36f-a9b4-4023-8b67-bb7c0ab3ca32_thumb.jpg	\N	0.001505	0	f	\N	\N	\N	\N	f	2026-02-03 19:41:39.177269
1280	default	2026-02-03 19:41:39.76783	\N	/media/channels/25/thumbnails/b8de9cfd-5e64-4905-9d16-cb8633d6a251_thumb.jpg	\N	0.001381	0	f	\N	\N	\N	\N	f	2026-02-03 19:41:39.769219
1264	default	2026-02-03 19:41:20.129139	\N	chat	chat	1064.227833	0	f	\N	\N	\N	\N	f	2026-02-03 19:59:04.357096
1282	default	2026-02-03 19:59:15.744838	\N	chat	getChannels	0.019267	1	f	\N	\N	\N	\N	f	2026-02-03 19:59:15.764117
1286	default	2026-02-03 19:59:16.393143	\N	chat	getChannels	0.030019	1	f	\N	\N	\N	\N	f	2026-02-03 19:59:16.423567
1289	default	2026-02-03 19:59:16.578858	\N	chat	getNotes	0.007012	1	f	\N	\N	\N	\N	f	2026-02-03 19:59:16.585873
1292	default	2026-02-03 19:59:16.783075	\N	/media/channels/14/thumbnails/7971e7dc-b2b3-47f7-a5c2-1fa8b37bc074_thumb.jpg	\N	0.002802	0	f	\N	\N	\N	\N	f	2026-02-03 19:59:16.785888
1294	default	2026-02-03 19:59:16.938259	\N	media	thumbnails	0.001066	0	f	\N	\N	\N	\N	f	2026-02-03 19:59:16.939335
1296	default	2026-02-03 19:59:18.986205	\N	media	thumbnails	0.000295	0	f	\N	\N	\N	\N	f	2026-02-03 19:59:18.986514
1273	default	2026-02-03 19:41:24.138676	\N	chat	chat	1076.426011	0	f	\N	\N	\N	\N	f	2026-02-03 19:59:20.564729
1297	default	2026-02-03 19:59:27.427159	\N	/media/channels/14/7971e7dc-b2b3-47f7-a5c2-1fa8b37bc074.jpg	\N	0.010719	0	f	\N	\N	\N	\N	f	2026-02-03 19:59:27.437887
1298	default	2026-02-03 19:59:45.603915	\N	chat	getChannels	0.004483	1	f	\N	\N	\N	\N	f	2026-02-03 19:59:45.608403
1301	default	2026-02-03 19:59:45.72878	\N	chat	getNotes	0.018926	1	f	\N	\N	\N	\N	f	2026-02-03 19:59:45.747714
1306	default	2026-02-03 19:59:45.909304	\N	media	thumbnails	0.000227	0	f	\N	\N	\N	\N	f	2026-02-03 19:59:45.90954
1287	default	2026-02-03 19:59:16.525074	\N	chat	chat	33.87479	0	f	\N	\N	\N	\N	f	2026-02-03 19:59:50.399923
1307	default	2026-02-03 19:59:51.463084	\N	media	thumbnails	0.000245	0	f	\N	\N	\N	\N	f	2026-02-03 19:59:51.463338
1284	default	2026-02-03 19:59:15.912942	\N	chat	chat	365.135941	0	f	\N	\N	\N	\N	f	2026-02-03 20:05:21.048916
1300	default	2026-02-03 19:59:45.680596	\N	chat	chat	388.900914	0	f	\N	\N	\N	\N	f	2026-02-03 20:06:14.581584
1308	default	2026-02-03 20:00:10.313794	\N	chat	createChannel	0.009684	1	f	\N	\N	\N	\N	f	2026-02-03 20:00:10.323492
1310	default	2026-02-03 20:00:10.400973	\N	chat	getChannels	0.007573	1	f	\N	\N	\N	\N	f	2026-02-03 20:00:10.408554
1311	default	2026-02-03 20:00:16.1289	\N	media	uploadMediaAndCreateNote	0.250422	4	f	\N	\N	\N	\N	f	2026-02-03 20:00:16.379324
1312	default	2026-02-03 20:00:16.420019	\N	/media/channels/27/thumbnails/976a0077-3551-4d38-9a1e-15eb23c3b998_thumb.jpg	\N	0.000862	0	f	\N	\N	\N	\N	f	2026-02-03 20:00:16.420885
1313	default	2026-02-03 20:00:16.436956	\N	media	uploadMediaAndCreateNote	0.070659	4	f	\N	\N	\N	\N	f	2026-02-03 20:00:16.507635
1314	default	2026-02-03 20:00:16.557729	\N	/media/channels/27/thumbnails/6730dac2-628b-4275-a3f9-1b9a00a9f303_thumb.jpg	\N	0.001094	0	f	\N	\N	\N	\N	f	2026-02-03 20:00:16.558829
1316	default	2026-02-03 20:00:17.859074	\N	media	thumbnails	0.000337	0	f	\N	\N	\N	\N	f	2026-02-03 20:00:17.859421
1317	default	2026-02-03 20:01:14.365644	\N	chat	createNote	0.014893	3	f	\N	\N	\N	\N	f	2026-02-03 20:01:14.380545
1318	default	2026-02-03 20:05:31.027841	\N	chat	getChannels	0.006657	1	f	\N	\N	\N	\N	f	2026-02-03 20:05:31.034503
1321	default	2026-02-03 20:05:31.273213	\N	chat	getNotes	0.018689	1	f	\N	\N	\N	\N	f	2026-02-03 20:05:31.291904
1326	default	2026-02-03 20:05:31.474408	\N	/media/channels/14/thumbnails/7971e7dc-b2b3-47f7-a5c2-1fa8b37bc074_thumb.jpg	\N	0.001307	0	f	\N	\N	\N	\N	f	2026-02-03 20:05:31.475719
1320	default	2026-02-03 20:05:31.214783	\N	chat	chat	7.128688	0	f	\N	\N	\N	\N	f	2026-02-03 20:05:38.343482
1328	default	2026-02-03 20:05:51.752959	\N	chat	getChannels	0.005953	1	f	\N	\N	\N	\N	f	2026-02-03 20:05:51.758917
1332	default	2026-02-03 20:05:53.789469	\N	chat	getNotes	0.006835	1	f	\N	\N	\N	\N	f	2026-02-03 20:05:53.796315
1336	default	2026-02-03 20:05:53.97021	\N	/media/channels/14/thumbnails/7971e7dc-b2b3-47f7-a5c2-1fa8b37bc074_thumb.jpg	\N	0.001913	0	f	\N	\N	\N	\N	f	2026-02-03 20:05:53.972128
1338	default	2026-02-03 20:06:10.281251	\N	chat	getChannels	0.005032	1	f	\N	\N	\N	\N	f	2026-02-03 20:06:10.286289
1342	default	2026-02-03 20:06:10.40991	\N	chat	getNotes	0.017431	1	f	\N	\N	\N	\N	f	2026-02-03 20:06:10.427342
1346	default	2026-02-03 20:10:31.491818	\N	/media/channels/27/thumbnails/6730dac2-628b-4275-a3f9-1b9a00a9f303_thumb.jpg	\N	0.002734	0	f	\N	\N	\N	\N	f	2026-02-03 20:10:31.49457
1348	default	2026-02-03 20:10:33.358423	\N	/media/channels/26/thumbnails/e9d6a36f-a9b4-4023-8b67-bb7c0ab3ca32_thumb.jpg	\N	0.001582	0	f	\N	\N	\N	\N	f	2026-02-03 20:10:33.360014
1351	default	2026-02-03 20:10:36.71294	\N	/media/channels/25/thumbnails/034048a0-39f1-4f5a-ad0e-d158a6a0693d_thumb.jpg	\N	0.00178	0	f	\N	\N	\N	\N	f	2026-02-03 20:10:36.714727
1354	default	2026-02-03 20:12:22.714707	\N	/media/channels/25/0bf8c3ea-ae09-4ad0-86fc-0136fc0d1db5.png	\N	0.002266	0	f	\N	\N	\N	\N	f	2026-02-03 20:12:22.716983
1330	default	2026-02-03 20:05:51.901162	\N	chat	chat	576.727944	0	f	\N	\N	\N	\N	f	2026-02-03 20:15:28.629109
1309	default	2026-02-03 20:00:10.402625	\N	chat	getNotes	0.006553	1	f	\N	\N	\N	\N	f	2026-02-03 20:00:10.409181
1315	default	2026-02-03 20:00:17.860611	\N	media	thumbnails	0.00025	0	f	\N	\N	\N	\N	f	2026-02-03 20:00:17.860873
1319	default	2026-02-03 20:05:31.028912	\N	chat	getChannels	0.00791	1	f	\N	\N	\N	\N	f	2026-02-03 20:05:31.036827
1322	default	2026-02-03 20:05:31.274168	\N	chat	getNotes	0.016877	1	f	\N	\N	\N	\N	f	2026-02-03 20:05:31.29105
1323	default	2026-02-03 20:05:31.275432	\N	chat	getNotes	0.018574	1	f	\N	\N	\N	\N	f	2026-02-03 20:05:31.294026
1324	default	2026-02-03 20:05:31.275653	\N	chat	getNotes	0.018017	1	f	\N	\N	\N	\N	f	2026-02-03 20:05:31.293672
1325	default	2026-02-03 20:05:31.274976	\N	chat	getNotes	0.019596	1	f	\N	\N	\N	\N	f	2026-02-03 20:05:31.294576
1327	default	2026-02-03 20:05:31.475461	\N	/media/channels/14/thumbnails/fc7df6f1-086e-42ba-9ffd-4d8d8be15930_thumb.jpg	\N	0.00064	0	f	\N	\N	\N	\N	f	2026-02-03 20:05:31.476108
1329	default	2026-02-03 20:05:51.753767	\N	chat	getChannels	0.005869	1	f	\N	\N	\N	\N	f	2026-02-03 20:05:51.759644
1331	default	2026-02-03 20:05:53.789905	\N	chat	getNotes	0.006866	1	f	\N	\N	\N	\N	f	2026-02-03 20:05:53.796774
1333	default	2026-02-03 20:05:53.791533	\N	chat	getNotes	0.008501	1	f	\N	\N	\N	\N	f	2026-02-03 20:05:53.800035
1335	default	2026-02-03 20:05:53.79084	\N	chat	getNotes	0.008945	1	f	\N	\N	\N	\N	f	2026-02-03 20:05:53.799788
1334	default	2026-02-03 20:05:53.792592	\N	chat	getNotes	0.006703	1	f	\N	\N	\N	\N	f	2026-02-03 20:05:53.799297
1337	default	2026-02-03 20:05:53.971792	\N	/media/channels/14/thumbnails/fc7df6f1-086e-42ba-9ffd-4d8d8be15930_thumb.jpg	\N	0.006175	0	f	\N	\N	\N	\N	f	2026-02-03 20:05:53.977978
1339	default	2026-02-03 20:06:10.282116	\N	chat	getChannels	0.004906	1	f	\N	\N	\N	\N	f	2026-02-03 20:06:10.287024
1344	default	2026-02-03 20:06:10.411416	\N	chat	getNotes	0.015454	1	f	\N	\N	\N	\N	f	2026-02-03 20:06:10.426875
1343	default	2026-02-03 20:06:10.414527	\N	chat	getNotes	0.015532	1	f	\N	\N	\N	\N	f	2026-02-03 20:06:10.43006
1345	default	2026-02-03 20:06:10.415371	\N	chat	getNotes	0.021167	1	f	\N	\N	\N	\N	f	2026-02-03 20:06:10.436545
1341	default	2026-02-03 20:06:10.413345	\N	chat	getNotes	0.016357	1	f	\N	\N	\N	\N	f	2026-02-03 20:06:10.429704
1347	default	2026-02-03 20:10:31.493374	\N	/media/channels/27/thumbnails/976a0077-3551-4d38-9a1e-15eb23c3b998_thumb.jpg	\N	0.002374	0	f	\N	\N	\N	\N	f	2026-02-03 20:10:31.495753
1349	default	2026-02-03 20:10:33.359351	\N	/media/channels/26/thumbnails/35f482f6-1143-419e-b5f5-eed6322fa58b_thumb.jpg	\N	0.00128	0	f	\N	\N	\N	\N	f	2026-02-03 20:10:33.360634
1350	default	2026-02-03 20:10:36.714119	\N	/media/channels/25/thumbnails/b8de9cfd-5e64-4905-9d16-cb8633d6a251_thumb.jpg	\N	0.001161	0	f	\N	\N	\N	\N	f	2026-02-03 20:10:36.715284
1352	default	2026-02-03 20:10:36.71604	\N	/media/channels/25/thumbnails/0bf8c3ea-ae09-4ad0-86fc-0136fc0d1db5_thumb.jpg	\N	0.000529	0	f	\N	\N	\N	\N	f	2026-02-03 20:10:36.716573
1353	default	2026-02-03 20:10:36.72638	\N	/media/channels/25/thumbnails/151e5f11-6d1a-44f7-952e-22d962c1b5df_thumb.jpg	\N	0.001078	0	f	\N	\N	\N	\N	f	2026-02-03 20:10:36.727466
1340	default	2026-02-03 20:06:10.415871	\N	chat	chat	558.211653	0	f	\N	\N	\N	\N	f	2026-02-03 20:15:28.627584
1355	default	2026-02-04 06:06:13.236592	\N	InternalSession	\N	0.006976	1	f	\N	\N	\N	\N	f	2026-02-04 06:06:13.243598
1356	default	2026-02-04 06:06:26.020086	\N	chat	getChannels	0.009165	1	f	\N	\N	\N	\N	f	2026-02-04 06:06:26.029257
1357	default	2026-02-04 06:06:26.023467	\N	chat	getChannels	0.006517	1	f	\N	\N	\N	\N	f	2026-02-04 06:06:26.029986
1359	default	2026-02-04 06:06:26.24827	\N	chat	getNotes	0.022033	1	f	\N	\N	\N	\N	f	2026-02-04 06:06:26.270317
1360	default	2026-02-04 06:06:26.249626	\N	chat	getNotes	0.016436	1	f	\N	\N	\N	\N	f	2026-02-04 06:06:26.266076
1363	default	2026-02-04 06:06:26.250587	\N	chat	getNotes	0.023306	1	f	\N	\N	\N	\N	f	2026-02-04 06:06:26.273898
1361	default	2026-02-04 06:06:26.251747	\N	chat	getNotes	0.023512	1	f	\N	\N	\N	\N	f	2026-02-04 06:06:26.27527
1362	default	2026-02-04 06:06:26.251349	\N	chat	getNotes	0.024654	1	f	\N	\N	\N	\N	f	2026-02-04 06:06:26.276005
1364	default	2026-02-04 06:06:26.444619	\N	/media/channels/14/thumbnails/fc7df6f1-086e-42ba-9ffd-4d8d8be15930_thumb.jpg	\N	0.017255	0	f	\N	\N	\N	\N	f	2026-02-04 06:06:26.46189
1366	default	2026-02-04 06:10:35.792302	\N	/media/channels/14/thumbnails/7971e7dc-b2b3-47f7-a5c2-1fa8b37bc074_thumb.jpg	\N	0.000689	0	f	\N	\N	\N	\N	f	2026-02-04 06:10:35.792998
1368	default	2026-02-04 06:10:37.346427	\N	/media/channels/14/thumbnails/fc7df6f1-086e-42ba-9ffd-4d8d8be15930_thumb.jpg	\N	0.000428	0	f	\N	\N	\N	\N	f	2026-02-04 06:10:37.346864
1369	default	2026-02-04 06:10:39.232418	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.000837	0	f	\N	\N	\N	\N	f	2026-02-04 06:10:39.233267
1358	default	2026-02-04 06:06:26.255662	\N	chat	chat	1944.409164	0	f	\N	\N	\N	\N	f	2026-02-04 06:38:50.664936
1370	default	2026-02-04 10:41:18.226666	\N	/	\N	0.005389	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:18.232069
1371	default	2026-02-04 10:41:18.262122	\N	/images/serverpod-logo.svg	\N	0.005101	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:18.267231
1373	default	2026-02-04 10:41:18.329484	\N	/images/background.svg	\N	0.001337	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:18.330833
1374	default	2026-02-04 10:41:18.361479	\N	/favicon.ico	\N	0.000475	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:18.361966
1375	default	2026-02-04 10:41:20.216331	\N	/app	\N	0.004045	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:20.220396
1376	default	2026-02-04 10:41:20.308223	\N	/app/flutter_bootstrap.js	\N	0.003324	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:20.311566
1377	default	2026-02-04 10:41:20.330208	\N	/app/flutter_service_worker.js	\N	0.002218	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:20.332438
1380	default	2026-02-04 10:41:20.349664	\N	/app/main.dart.mjs	\N	0.006992	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:20.356661
1378	default	2026-02-04 10:41:20.351405	\N	/app/manifest.json	\N	0.003233	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:20.354653
1383	default	2026-02-04 10:41:20.369119	\N	/app/index.html	\N	0.001553	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:20.370678
1381	default	2026-02-04 10:41:20.348591	\N	/app/main.dart.wasm	\N	0.023186	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:20.371782
1384	default	2026-02-04 10:41:20.347709	\N	/app/main.dart.js	\N	0.025276	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:20.372986
1385	default	2026-02-04 10:41:20.381371	\N	/app/flutter_bootstrap.js	\N	0.000391	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:20.381767
1386	default	2026-02-04 10:41:20.387444	\N	/app/assets/FontManifest.json	\N	0.001414	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:20.388859
1388	default	2026-02-04 10:41:20.503011	\N	/app/flutter_service_worker.js	\N	0.000796	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:20.503817
1389	default	2026-02-04 10:41:21.332786	\N	/app/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf	\N	0.001796	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:21.334599
1391	default	2026-02-04 10:41:22.088643	\N	/app/assets/assets/config.json	\N	0.001247	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:22.089908
1392	default	2026-02-04 10:41:22.290107	\N	/app	\N	0.00114	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:22.291268
1393	default	2026-02-04 10:41:22.316454	\N	/app/flutter_bootstrap.js	\N	0.001208	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:22.317678
1394	default	2026-02-04 10:41:22.338802	\N	/app/manifest.json	\N	0.000959	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:22.339772
1395	default	2026-02-04 10:41:22.361096	\N	/app/assets/assets/config.json	\N	0.000516	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:22.361632
1396	default	2026-02-04 10:41:45.456128	\N	/app	\N	0.001109	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:45.457253
1397	default	2026-02-04 10:41:45.53109	\N	/app/flutter_bootstrap.js	\N	0.000795	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:45.531895
1398	default	2026-02-04 10:41:45.572033	\N	/app/manifest.json	\N	0.000855	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:45.572899
1365	default	2026-02-04 06:06:26.441075	\N	/media/channels/14/thumbnails/7971e7dc-b2b3-47f7-a5c2-1fa8b37bc074_thumb.jpg	\N	0.021346	0	f	\N	\N	\N	\N	f	2026-02-04 06:06:26.462425
1367	default	2026-02-04 06:10:35.79625	\N	/media/channels/14/thumbnails/e5acddb6-25f4-4b13-b633-84488c80e1ef_thumb.jpg	\N	0.001791	0	f	\N	\N	\N	\N	f	2026-02-04 06:10:35.798046
1372	default	2026-02-04 10:41:18.26392	\N	/css/style.css	\N	0.005352	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:18.269275
1379	default	2026-02-04 10:41:20.350392	\N	/app/favicon.png	\N	0.005619	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:20.356023
1382	default	2026-02-04 10:41:20.369696	\N	/app/icons/Icon-192.png	\N	0.001518	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:20.371218
1387	default	2026-02-04 10:41:20.387059	\N	/app/assets/AssetManifest.bin.json	\N	0.001597	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:20.38866
1390	default	2026-02-04 10:41:21.331537	\N	/app/assets/fonts/MaterialIcons-Regular.otf	\N	0.003822	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:21.335364
1399	default	2026-02-04 10:41:45.617807	\N	/app/assets/assets/config.json	\N	0.000209	0	f	\N	\N	\N	\N	f	2026-02-04 10:41:45.618023
1400	default	2026-02-04 15:28:40.604201	\N	InternalSession	\N	0.005219	1	f	\N	\N	\N	\N	f	2026-02-04 15:28:40.609444
\.


--
-- Name: channels_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.channels_id_seq', 27, true);


--
-- Name: media_attachments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.media_attachments_id_seq', 35, true);


--
-- Name: notes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notes_id_seq', 156, true);


--
-- Name: serverpod_cloud_storage_direct_upload_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.serverpod_cloud_storage_direct_upload_id_seq', 1, false);


--
-- Name: serverpod_cloud_storage_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.serverpod_cloud_storage_id_seq', 1, false);


--
-- Name: serverpod_future_call_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.serverpod_future_call_id_seq', 1, false);


--
-- Name: serverpod_health_connection_info_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.serverpod_health_connection_info_id_seq', 221, true);


--
-- Name: serverpod_health_metric_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.serverpod_health_metric_id_seq', 666, true);


--
-- Name: serverpod_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.serverpod_log_id_seq', 20, true);


--
-- Name: serverpod_message_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.serverpod_message_log_id_seq', 1, false);


--
-- Name: serverpod_method_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.serverpod_method_id_seq', 1, false);


--
-- Name: serverpod_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.serverpod_migrations_id_seq', 20, true);


--
-- Name: serverpod_query_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.serverpod_query_log_id_seq', 2, true);


--
-- Name: serverpod_readwrite_test_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.serverpod_readwrite_test_id_seq', 1, false);


--
-- Name: serverpod_runtime_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.serverpod_runtime_settings_id_seq', 1, true);


--
-- Name: serverpod_session_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.serverpod_session_log_id_seq', 1400, true);


--
-- Name: channels channels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.channels
    ADD CONSTRAINT channels_pkey PRIMARY KEY (id);


--
-- Name: media_attachments media_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.media_attachments
    ADD CONSTRAINT media_attachments_pkey PRIMARY KEY (id);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- Name: serverpod_auth_core_jwt_refresh_token serverpod_auth_core_jwt_refresh_token_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_core_jwt_refresh_token
    ADD CONSTRAINT serverpod_auth_core_jwt_refresh_token_pkey PRIMARY KEY (id);


--
-- Name: serverpod_auth_core_profile_image serverpod_auth_core_profile_image_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_core_profile_image
    ADD CONSTRAINT serverpod_auth_core_profile_image_pkey PRIMARY KEY (id);


--
-- Name: serverpod_auth_core_profile serverpod_auth_core_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_core_profile
    ADD CONSTRAINT serverpod_auth_core_profile_pkey PRIMARY KEY (id);


--
-- Name: serverpod_auth_core_session serverpod_auth_core_session_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_core_session
    ADD CONSTRAINT serverpod_auth_core_session_pkey PRIMARY KEY (id);


--
-- Name: serverpod_auth_core_user serverpod_auth_core_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_core_user
    ADD CONSTRAINT serverpod_auth_core_user_pkey PRIMARY KEY (id);


--
-- Name: serverpod_auth_idp_apple_account serverpod_auth_idp_apple_account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_apple_account
    ADD CONSTRAINT serverpod_auth_idp_apple_account_pkey PRIMARY KEY (id);


--
-- Name: serverpod_auth_idp_email_account_password_reset_request serverpod_auth_idp_email_account_password_reset_request_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_email_account_password_reset_request
    ADD CONSTRAINT serverpod_auth_idp_email_account_password_reset_request_pkey PRIMARY KEY (id);


--
-- Name: serverpod_auth_idp_email_account serverpod_auth_idp_email_account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_email_account
    ADD CONSTRAINT serverpod_auth_idp_email_account_pkey PRIMARY KEY (id);


--
-- Name: serverpod_auth_idp_email_account_request serverpod_auth_idp_email_account_request_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_email_account_request
    ADD CONSTRAINT serverpod_auth_idp_email_account_request_pkey PRIMARY KEY (id);


--
-- Name: serverpod_auth_idp_firebase_account serverpod_auth_idp_firebase_account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_firebase_account
    ADD CONSTRAINT serverpod_auth_idp_firebase_account_pkey PRIMARY KEY (id);


--
-- Name: serverpod_auth_idp_google_account serverpod_auth_idp_google_account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_google_account
    ADD CONSTRAINT serverpod_auth_idp_google_account_pkey PRIMARY KEY (id);


--
-- Name: serverpod_auth_idp_passkey_account serverpod_auth_idp_passkey_account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_passkey_account
    ADD CONSTRAINT serverpod_auth_idp_passkey_account_pkey PRIMARY KEY (id);


--
-- Name: serverpod_auth_idp_passkey_challenge serverpod_auth_idp_passkey_challenge_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_passkey_challenge
    ADD CONSTRAINT serverpod_auth_idp_passkey_challenge_pkey PRIMARY KEY (id);


--
-- Name: serverpod_auth_idp_rate_limited_request_attempt serverpod_auth_idp_rate_limited_request_attempt_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_rate_limited_request_attempt
    ADD CONSTRAINT serverpod_auth_idp_rate_limited_request_attempt_pkey PRIMARY KEY (id);


--
-- Name: serverpod_auth_idp_secret_challenge serverpod_auth_idp_secret_challenge_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_secret_challenge
    ADD CONSTRAINT serverpod_auth_idp_secret_challenge_pkey PRIMARY KEY (id);


--
-- Name: serverpod_cloud_storage_direct_upload serverpod_cloud_storage_direct_upload_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_cloud_storage_direct_upload
    ADD CONSTRAINT serverpod_cloud_storage_direct_upload_pkey PRIMARY KEY (id);


--
-- Name: serverpod_cloud_storage serverpod_cloud_storage_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_cloud_storage
    ADD CONSTRAINT serverpod_cloud_storage_pkey PRIMARY KEY (id);


--
-- Name: serverpod_future_call serverpod_future_call_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_future_call
    ADD CONSTRAINT serverpod_future_call_pkey PRIMARY KEY (id);


--
-- Name: serverpod_health_connection_info serverpod_health_connection_info_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_health_connection_info
    ADD CONSTRAINT serverpod_health_connection_info_pkey PRIMARY KEY (id);


--
-- Name: serverpod_health_metric serverpod_health_metric_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_health_metric
    ADD CONSTRAINT serverpod_health_metric_pkey PRIMARY KEY (id);


--
-- Name: serverpod_log serverpod_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_log
    ADD CONSTRAINT serverpod_log_pkey PRIMARY KEY (id);


--
-- Name: serverpod_message_log serverpod_message_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_message_log
    ADD CONSTRAINT serverpod_message_log_pkey PRIMARY KEY (id);


--
-- Name: serverpod_method serverpod_method_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_method
    ADD CONSTRAINT serverpod_method_pkey PRIMARY KEY (id);


--
-- Name: serverpod_migrations serverpod_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_migrations
    ADD CONSTRAINT serverpod_migrations_pkey PRIMARY KEY (id);


--
-- Name: serverpod_query_log serverpod_query_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_query_log
    ADD CONSTRAINT serverpod_query_log_pkey PRIMARY KEY (id);


--
-- Name: serverpod_readwrite_test serverpod_readwrite_test_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_readwrite_test
    ADD CONSTRAINT serverpod_readwrite_test_pkey PRIMARY KEY (id);


--
-- Name: serverpod_runtime_settings serverpod_runtime_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_runtime_settings
    ADD CONSTRAINT serverpod_runtime_settings_pkey PRIMARY KEY (id);


--
-- Name: serverpod_session_log serverpod_session_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_session_log
    ADD CONSTRAINT serverpod_session_log_pkey PRIMARY KEY (id);


--
-- Name: channel_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX channel_created_idx ON public.notes USING btree ("channelId", "createdAt");


--
-- Name: channel_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX channel_idx ON public.media_attachments USING btree ("channelId", "uploadedAt");


--
-- Name: note_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX note_idx ON public.media_attachments USING btree ("noteId");


--
-- Name: serverpod_auth_apple_account_identifier; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX serverpod_auth_apple_account_identifier ON public.serverpod_auth_idp_apple_account USING btree ("userIdentifier");


--
-- Name: serverpod_auth_core_jwt_refresh_token_last_updated_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX serverpod_auth_core_jwt_refresh_token_last_updated_at ON public.serverpod_auth_core_jwt_refresh_token USING btree ("lastUpdatedAt");


--
-- Name: serverpod_auth_firebase_account_user_identifier; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX serverpod_auth_firebase_account_user_identifier ON public.serverpod_auth_idp_firebase_account USING btree ("userIdentifier");


--
-- Name: serverpod_auth_google_account_user_identifier; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX serverpod_auth_google_account_user_identifier ON public.serverpod_auth_idp_google_account USING btree ("userIdentifier");


--
-- Name: serverpod_auth_idp_email_account_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX serverpod_auth_idp_email_account_email ON public.serverpod_auth_idp_email_account USING btree (email);


--
-- Name: serverpod_auth_idp_email_account_request_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX serverpod_auth_idp_email_account_request_email ON public.serverpod_auth_idp_email_account_request USING btree (email);


--
-- Name: serverpod_auth_idp_passkey_account_key_id_base64; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX serverpod_auth_idp_passkey_account_key_id_base64 ON public.serverpod_auth_idp_passkey_account USING btree ("keyIdBase64");


--
-- Name: serverpod_auth_idp_rate_limited_request_attempt_composite; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX serverpod_auth_idp_rate_limited_request_attempt_composite ON public.serverpod_auth_idp_rate_limited_request_attempt USING btree (domain, source, nonce, "attemptedAt");


--
-- Name: serverpod_auth_profile_user_profile_email_auth_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX serverpod_auth_profile_user_profile_email_auth_user_id ON public.serverpod_auth_core_profile USING btree ("authUserId");


--
-- Name: serverpod_cloud_storage_direct_upload_storage_path; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX serverpod_cloud_storage_direct_upload_storage_path ON public.serverpod_cloud_storage_direct_upload USING btree ("storageId", path);


--
-- Name: serverpod_cloud_storage_expiration; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX serverpod_cloud_storage_expiration ON public.serverpod_cloud_storage USING btree (expiration);


--
-- Name: serverpod_cloud_storage_path_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX serverpod_cloud_storage_path_idx ON public.serverpod_cloud_storage USING btree ("storageId", path);


--
-- Name: serverpod_future_call_identifier_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX serverpod_future_call_identifier_idx ON public.serverpod_future_call USING btree (identifier);


--
-- Name: serverpod_future_call_serverId_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "serverpod_future_call_serverId_idx" ON public.serverpod_future_call USING btree ("serverId");


--
-- Name: serverpod_future_call_time_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX serverpod_future_call_time_idx ON public.serverpod_future_call USING btree ("time");


--
-- Name: serverpod_health_connection_info_timestamp_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX serverpod_health_connection_info_timestamp_idx ON public.serverpod_health_connection_info USING btree ("timestamp", "serverId", granularity);


--
-- Name: serverpod_health_metric_timestamp_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX serverpod_health_metric_timestamp_idx ON public.serverpod_health_metric USING btree ("timestamp", "serverId", name, granularity);


--
-- Name: serverpod_log_sessionLogId_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "serverpod_log_sessionLogId_idx" ON public.serverpod_log USING btree ("sessionLogId");


--
-- Name: serverpod_method_endpoint_method_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX serverpod_method_endpoint_method_idx ON public.serverpod_method USING btree (endpoint, method);


--
-- Name: serverpod_migrations_ids; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX serverpod_migrations_ids ON public.serverpod_migrations USING btree (module);


--
-- Name: serverpod_query_log_sessionLogId_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "serverpod_query_log_sessionLogId_idx" ON public.serverpod_query_log USING btree ("sessionLogId");


--
-- Name: serverpod_session_log_isopen_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX serverpod_session_log_isopen_idx ON public.serverpod_session_log USING btree ("isOpen");


--
-- Name: serverpod_session_log_serverid_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX serverpod_session_log_serverid_idx ON public.serverpod_session_log USING btree ("serverId");


--
-- Name: serverpod_session_log_touched_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX serverpod_session_log_touched_idx ON public.serverpod_session_log USING btree (touched);


--
-- Name: media_attachments media_attachments_fk_0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.media_attachments
    ADD CONSTRAINT media_attachments_fk_0 FOREIGN KEY ("noteId") REFERENCES public.notes(id) ON DELETE CASCADE;


--
-- Name: media_attachments media_attachments_fk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.media_attachments
    ADD CONSTRAINT media_attachments_fk_1 FOREIGN KEY ("channelId") REFERENCES public.channels(id) ON DELETE CASCADE;


--
-- Name: notes notes_fk_0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_fk_0 FOREIGN KEY ("channelId") REFERENCES public.channels(id) ON DELETE CASCADE;


--
-- Name: serverpod_auth_core_jwt_refresh_token serverpod_auth_core_jwt_refresh_token_fk_0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_core_jwt_refresh_token
    ADD CONSTRAINT serverpod_auth_core_jwt_refresh_token_fk_0 FOREIGN KEY ("authUserId") REFERENCES public.serverpod_auth_core_user(id) ON DELETE CASCADE;


--
-- Name: serverpod_auth_core_profile serverpod_auth_core_profile_fk_0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_core_profile
    ADD CONSTRAINT serverpod_auth_core_profile_fk_0 FOREIGN KEY ("authUserId") REFERENCES public.serverpod_auth_core_user(id) ON DELETE CASCADE;


--
-- Name: serverpod_auth_core_profile serverpod_auth_core_profile_fk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_core_profile
    ADD CONSTRAINT serverpod_auth_core_profile_fk_1 FOREIGN KEY ("imageId") REFERENCES public.serverpod_auth_core_profile_image(id);


--
-- Name: serverpod_auth_core_profile_image serverpod_auth_core_profile_image_fk_0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_core_profile_image
    ADD CONSTRAINT serverpod_auth_core_profile_image_fk_0 FOREIGN KEY ("userProfileId") REFERENCES public.serverpod_auth_core_profile(id) ON DELETE CASCADE;


--
-- Name: serverpod_auth_core_session serverpod_auth_core_session_fk_0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_core_session
    ADD CONSTRAINT serverpod_auth_core_session_fk_0 FOREIGN KEY ("authUserId") REFERENCES public.serverpod_auth_core_user(id) ON DELETE CASCADE;


--
-- Name: serverpod_auth_idp_apple_account serverpod_auth_idp_apple_account_fk_0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_apple_account
    ADD CONSTRAINT serverpod_auth_idp_apple_account_fk_0 FOREIGN KEY ("authUserId") REFERENCES public.serverpod_auth_core_user(id) ON DELETE CASCADE;


--
-- Name: serverpod_auth_idp_email_account serverpod_auth_idp_email_account_fk_0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_email_account
    ADD CONSTRAINT serverpod_auth_idp_email_account_fk_0 FOREIGN KEY ("authUserId") REFERENCES public.serverpod_auth_core_user(id) ON DELETE CASCADE;


--
-- Name: serverpod_auth_idp_email_account_password_reset_request serverpod_auth_idp_email_account_password_reset_request_fk_0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_email_account_password_reset_request
    ADD CONSTRAINT serverpod_auth_idp_email_account_password_reset_request_fk_0 FOREIGN KEY ("emailAccountId") REFERENCES public.serverpod_auth_idp_email_account(id) ON DELETE CASCADE;


--
-- Name: serverpod_auth_idp_email_account_password_reset_request serverpod_auth_idp_email_account_password_reset_request_fk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_email_account_password_reset_request
    ADD CONSTRAINT serverpod_auth_idp_email_account_password_reset_request_fk_1 FOREIGN KEY ("challengeId") REFERENCES public.serverpod_auth_idp_secret_challenge(id) ON DELETE CASCADE;


--
-- Name: serverpod_auth_idp_email_account_password_reset_request serverpod_auth_idp_email_account_password_reset_request_fk_2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_email_account_password_reset_request
    ADD CONSTRAINT serverpod_auth_idp_email_account_password_reset_request_fk_2 FOREIGN KEY ("setPasswordChallengeId") REFERENCES public.serverpod_auth_idp_secret_challenge(id) ON DELETE CASCADE;


--
-- Name: serverpod_auth_idp_email_account_request serverpod_auth_idp_email_account_request_fk_0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_email_account_request
    ADD CONSTRAINT serverpod_auth_idp_email_account_request_fk_0 FOREIGN KEY ("challengeId") REFERENCES public.serverpod_auth_idp_secret_challenge(id) ON DELETE CASCADE;


--
-- Name: serverpod_auth_idp_email_account_request serverpod_auth_idp_email_account_request_fk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_email_account_request
    ADD CONSTRAINT serverpod_auth_idp_email_account_request_fk_1 FOREIGN KEY ("createAccountChallengeId") REFERENCES public.serverpod_auth_idp_secret_challenge(id) ON DELETE CASCADE;


--
-- Name: serverpod_auth_idp_firebase_account serverpod_auth_idp_firebase_account_fk_0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_firebase_account
    ADD CONSTRAINT serverpod_auth_idp_firebase_account_fk_0 FOREIGN KEY ("authUserId") REFERENCES public.serverpod_auth_core_user(id) ON DELETE CASCADE;


--
-- Name: serverpod_auth_idp_google_account serverpod_auth_idp_google_account_fk_0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_google_account
    ADD CONSTRAINT serverpod_auth_idp_google_account_fk_0 FOREIGN KEY ("authUserId") REFERENCES public.serverpod_auth_core_user(id) ON DELETE CASCADE;


--
-- Name: serverpod_auth_idp_passkey_account serverpod_auth_idp_passkey_account_fk_0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_auth_idp_passkey_account
    ADD CONSTRAINT serverpod_auth_idp_passkey_account_fk_0 FOREIGN KEY ("authUserId") REFERENCES public.serverpod_auth_core_user(id) ON DELETE CASCADE;


--
-- Name: serverpod_log serverpod_log_fk_0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_log
    ADD CONSTRAINT serverpod_log_fk_0 FOREIGN KEY ("sessionLogId") REFERENCES public.serverpod_session_log(id) ON DELETE CASCADE;


--
-- Name: serverpod_message_log serverpod_message_log_fk_0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_message_log
    ADD CONSTRAINT serverpod_message_log_fk_0 FOREIGN KEY ("sessionLogId") REFERENCES public.serverpod_session_log(id) ON DELETE CASCADE;


--
-- Name: serverpod_query_log serverpod_query_log_fk_0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.serverpod_query_log
    ADD CONSTRAINT serverpod_query_log_fk_0 FOREIGN KEY ("sessionLogId") REFERENCES public.serverpod_session_log(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict tjfH9hNLTMHx8wJeaCAU0jhDG5ARm5iLXM5mXhMSNQMdTHnFtW9Z8GjP7kvAIlt

