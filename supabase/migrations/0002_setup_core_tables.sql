BEGIN;

CREATE TABLE IF NOT EXISTS public.app_users (
    id uuid PRIMARY KEY,
    email text NOT NULL UNIQUE,
    phone text NOT NULL,
    full_name text NOT NULL,
    role text NOT NULL CHECK (role IN ('advertiser', 'influencer')),
    auth_method text NOT NULL CHECK (auth_method IN ('email', 'external')),
    email_verified boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT NOW()
);

ALTER TABLE public.app_users
    OWNER TO postgres;

ALTER TABLE public.app_users
    DISABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.terms_acceptances (
    id bigserial PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.app_users (id) ON DELETE CASCADE,
    terms_version text NOT NULL,
    consented_at timestamptz NOT NULL DEFAULT NOW(),
    created_at timestamptz NOT NULL DEFAULT NOW(),
    CONSTRAINT terms_acceptances_user_terms_unique UNIQUE (user_id, terms_version)
);

ALTER TABLE public.terms_acceptances
    OWNER TO postgres;

ALTER TABLE public.terms_acceptances
    DISABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.advertiser_profiles (
    user_id uuid PRIMARY KEY REFERENCES public.app_users (id) ON DELETE CASCADE,
    company_name text NOT NULL,
    location text NOT NULL,
    category text NOT NULL,
    business_registration_no text NOT NULL UNIQUE,
    verification_status text NOT NULL DEFAULT '검증대기' CHECK (verification_status IN ('성공', '검증대기', '실패')),
    created_at timestamptz NOT NULL DEFAULT NOW(),
    updated_at timestamptz NOT NULL DEFAULT NOW()
);

ALTER TABLE public.advertiser_profiles
    OWNER TO postgres;

ALTER TABLE public.advertiser_profiles
    DISABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.influencer_profiles (
    user_id uuid PRIMARY KEY REFERENCES public.app_users (id) ON DELETE CASCADE,
    birth_date date NOT NULL,
    created_at timestamptz NOT NULL DEFAULT NOW(),
    updated_at timestamptz NOT NULL DEFAULT NOW()
);

ALTER TABLE public.influencer_profiles
    OWNER TO postgres;

ALTER TABLE public.influencer_profiles
    DISABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.influencer_channels (
    id bigserial PRIMARY KEY,
    influencer_id uuid NOT NULL REFERENCES public.influencer_profiles (user_id) ON DELETE CASCADE,
    channel_type text NOT NULL CHECK (channel_type IN ('Naver', 'YouTube', 'Instagram', 'Threads')),
    channel_name text NOT NULL,
    channel_url text NOT NULL,
    verification_status text NOT NULL DEFAULT '검증대기' CHECK (verification_status IN ('검증대기', '검증성공', '검증실패')),
    created_at timestamptz NOT NULL DEFAULT NOW(),
    updated_at timestamptz NOT NULL DEFAULT NOW(),
    CONSTRAINT influencer_channels_unique_url UNIQUE (influencer_id, channel_url)
);

ALTER TABLE public.influencer_channels
    OWNER TO postgres;

ALTER TABLE public.influencer_channels
    DISABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.campaigns (
    id bigserial PRIMARY KEY,
    advertiser_id uuid NOT NULL REFERENCES public.advertiser_profiles (user_id) ON DELETE CASCADE,
    title text NOT NULL,
    recruit_start_date date NOT NULL,
    recruit_end_date date NOT NULL,
    benefits text NOT NULL,
    mission text NOT NULL,
    store_info text NOT NULL,
    max_participants integer NOT NULL CHECK (max_participants > 0),
    recruit_status text NOT NULL DEFAULT '모집중' CHECK (recruit_status IN ('모집중', '모집종료', '선정완료')),
    created_at timestamptz NOT NULL DEFAULT NOW(),
    updated_at timestamptz NOT NULL DEFAULT NOW(),
    CONSTRAINT campaigns_recruit_period_valid CHECK (recruit_start_date <= recruit_end_date)
);

ALTER TABLE public.campaigns
    OWNER TO postgres;

ALTER TABLE public.campaigns
    DISABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.applications (
    id bigserial PRIMARY KEY,
    campaign_id bigint NOT NULL REFERENCES public.campaigns (id) ON DELETE CASCADE,
    influencer_id uuid NOT NULL REFERENCES public.influencer_profiles (user_id) ON DELETE CASCADE,
    motivation text NOT NULL,
    planned_visit_date date NOT NULL,
    status text NOT NULL DEFAULT '신청완료' CHECK (status IN ('신청완료', '선정', '반려')),
    created_at timestamptz NOT NULL DEFAULT NOW(),
    updated_at timestamptz NOT NULL DEFAULT NOW(),
    CONSTRAINT applications_unique_submission UNIQUE (campaign_id, influencer_id)
);

ALTER TABLE public.applications
    OWNER TO postgres;

ALTER TABLE public.applications
    DISABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

COMMIT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'set_timestamp_advertiser_profiles'
    ) THEN
        CREATE TRIGGER set_timestamp_advertiser_profiles
        BEFORE UPDATE ON public.advertiser_profiles
        FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
    END IF;
EXCEPTION
    WHEN others THEN
        RAISE;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'set_timestamp_influencer_profiles'
    ) THEN
        CREATE TRIGGER set_timestamp_influencer_profiles
        BEFORE UPDATE ON public.influencer_profiles
        FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
    END IF;
EXCEPTION
    WHEN others THEN
        RAISE;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'set_timestamp_influencer_channels'
    ) THEN
        CREATE TRIGGER set_timestamp_influencer_channels
        BEFORE UPDATE ON public.influencer_channels
        FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
    END IF;
EXCEPTION
    WHEN others THEN
        RAISE;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'set_timestamp_campaigns'
    ) THEN
        CREATE TRIGGER set_timestamp_campaigns
        BEFORE UPDATE ON public.campaigns
        FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
    END IF;
EXCEPTION
    WHEN others THEN
        RAISE;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'set_timestamp_applications'
    ) THEN
        CREATE TRIGGER set_timestamp_applications
        BEFORE UPDATE ON public.applications
        FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
    END IF;
EXCEPTION
    WHEN others THEN
        RAISE;
END;
$$;
