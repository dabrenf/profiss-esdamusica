-- Supabase schema for Go2Backstage

-- Create users table
CREATE TABLE public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  profile_picture_url TEXT,
  city TEXT NOT NULL,
  bio TEXT,
  portfolio_url TEXT,
  professional_functions TEXT[] NOT NULL DEFAULT '{}',
  online_status BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create jobs table
CREATE TABLE public.jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  city TEXT NOT NULL,
  job_function TEXT NOT NULL,
  event_date DATE NOT NULL,
  event_time TIME,
  salary_range TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create applications table
CREATE TABLE public.applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID REFERENCES public.jobs(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL DEFAULT 'Enviado',
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(job_id, user_id)
);

-- Create messages table
CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  receiver_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Policies for users
CREATE POLICY "Users can view all profiles" ON public.users
  FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" ON public.users
  FOR UPDATE USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can insert their own profile" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = auth_user_id);

-- Policies for jobs
CREATE POLICY "Jobs are viewable by everyone" ON public.jobs
  FOR SELECT USING (true);

CREATE POLICY "Users can create jobs" ON public.jobs
  FOR INSERT WITH CHECK (
    auth.uid() = (SELECT auth_user_id FROM public.users WHERE id = creator_id)
  );

CREATE POLICY "Users can update their own jobs" ON public.jobs
  FOR UPDATE USING (
    auth.uid() = (SELECT auth_user_id FROM public.users WHERE id = creator_id)
  );

CREATE POLICY "Users can delete their own jobs" ON public.jobs
  FOR DELETE USING (
    auth.uid() = (SELECT auth_user_id FROM public.users WHERE id = creator_id)
  );

-- Policies for applications
CREATE POLICY "Applications visible to creator and applicant" ON public.applications
  FOR SELECT USING (
    auth.uid() = (SELECT auth_user_id FROM public.users WHERE id = user_id)
    OR auth.uid() = (
      SELECT auth_user_id
      FROM public.users u
      JOIN public.jobs j ON u.id = j.creator_id
      WHERE j.id = job_id
    )
  );

CREATE POLICY "Users can create applications" ON public.applications
  FOR INSERT WITH CHECK (
    auth.uid() = (SELECT auth_user_id FROM public.users WHERE id = user_id)
  );

CREATE POLICY "Users can update their own applications" ON public.applications
  FOR UPDATE USING (
    auth.uid() = (SELECT auth_user_id FROM public.users WHERE id = user_id)
  );

-- Policies for messages
CREATE POLICY "Users can view own messages" ON public.messages
  FOR SELECT USING (
    auth.uid() = (SELECT auth_user_id FROM public.users WHERE id = sender_id)
    OR auth.uid() = (SELECT auth_user_id FROM public.users WHERE id = receiver_id)
  );

CREATE POLICY "Users can send messages" ON public.messages
  FOR INSERT WITH CHECK (
    auth.uid() = (SELECT auth_user_id FROM public.users WHERE id = sender_id)
  );

-- Function to keep updated_at in sync
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Function to create user profile when auth user is created
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  INSERT INTO public.users (auth_user_id, name, email, city, professional_functions)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'city', ''),
    ARRAY[COALESCE(NEW.raw_user_meta_data->>'professional_functions', '')]::TEXT[]
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

