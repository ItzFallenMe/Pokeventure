-- Pokéventure social schema.
-- Run in the Supabase SQL editor, or with `supabase db push`, once per project.
-- Anonymous sign-in must be enabled: Authentication → Providers → Anonymous.

create extension if not exists pgcrypto;

-- One row per trainer. The id is the Supabase auth user, so anonymous and
-- upgraded accounts share the same profile.
create table if not exists public.players (
  id uuid primary key references auth.users (id) on delete cascade,
  trainer_name text not null
    check (char_length(trainer_name) between 3 and 20),
  friend_code text not null unique,
  last_seen timestamptz not null default now(),
  created_at timestamptz not null default now()
);

-- Six characters from an unambiguous alphabet (no 0/O/1/I).
create or replace function public.generate_friend_code()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  candidate text;
  i int;
begin
  loop
    candidate := '';
    for i in 1..6 loop
      candidate := candidate || substr(
        alphabet,
        1 + floor(random() * length(alphabet))::int,
        1
      );
    end loop;
    exit when not exists (
      select 1 from public.players where friend_code = candidate
    );
  end loop;
  return candidate;
end;
$$;

alter table public.players
  alter column friend_code set default public.generate_friend_code();

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.players (id) on delete cascade,
  addressee_id uuid not null references public.players (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check (requester_id <> addressee_id)
);

-- One row per pair, whichever direction the request was sent in.
create unique index if not exists friendships_pair_key
  on public.friendships (
    least(requester_id, addressee_id),
    greatest(requester_id, addressee_id)
  );
create index if not exists friendships_addressee_idx
  on public.friendships (addressee_id, status);
create index if not exists friendships_requester_idx
  on public.friendships (requester_id, status);

alter table public.players enable row level security;
alter table public.friendships enable row level security;

-- Trainer cards are public to signed-in players: that is how a friend code
-- search resolves to a name. No email or auth metadata lives in this table.
drop policy if exists "players are readable by signed-in users" on public.players;
create policy "players are readable by signed-in users"
  on public.players for select
  to authenticated
  using (true);

drop policy if exists "players create their own profile" on public.players;
create policy "players create their own profile"
  on public.players for insert
  to authenticated
  with check (id = auth.uid());

drop policy if exists "players update their own profile" on public.players;
create policy "players update their own profile"
  on public.players for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

drop policy if exists "friendships are visible to both players" on public.friendships;
create policy "friendships are visible to both players"
  on public.friendships for select
  to authenticated
  using (auth.uid() in (requester_id, addressee_id));

drop policy if exists "players send their own friend requests" on public.friendships;
create policy "players send their own friend requests"
  on public.friendships for insert
  to authenticated
  with check (requester_id = auth.uid() and status = 'pending');

drop policy if exists "addressees answer friend requests" on public.friendships;
create policy "addressees answer friend requests"
  on public.friendships for update
  to authenticated
  using (addressee_id = auth.uid())
  with check (addressee_id = auth.uid());

drop policy if exists "both players can remove a friendship" on public.friendships;
create policy "both players can remove a friendship"
  on public.friendships for delete
  to authenticated
  using (auth.uid() in (requester_id, addressee_id));
