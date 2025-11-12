-- RPCs to safely insert game sessions and get Top10 aggregates
-- Paste this into Supabase SQL editor and run as a privileged user.

 -- If a previous overload exists with the same signature, drop it first so
 -- we can recreate it with the desired return type.
 drop function if exists public.rpc_insert_gamesession(integer, integer) cascade;
 create or replace function public.rpc_insert_gamesession(p_user_id int, p_final_score int)
returns json
language plpgsql security definer as $$
declare
  rec record;
begin
  insert into public.gamesessions (user_id, game_mode, final_score)
    values (p_user_id, null, p_final_score)
    returning * into rec;
  return row_to_json(rec);
end;
$$;

 drop function if exists public.rpc_get_top10() cascade;
 create or replace function public.rpc_get_top10()
returns json
language sql security definer as $$
  with t as (
    select user_id, sum(final_score)::int as total
    from public.gamesessions
    group by user_id
    order by total desc
    limit 10
  )
  select json_build_object('data', coalesce(json_agg(row_to_json(t)), '[]'::json)) from t;
$$;

-- Return recent gamesessions for a given user as a single JSON object { data: [...] }
drop function if exists public.rpc_get_user_gamesessions(integer, integer) cascade;
create or replace function public.rpc_get_user_gamesessions(p_user_id int, p_limit int)
returns json
language sql security definer as $$
  with s as (
    select session_id, user_id, category_id, game_mode, final_score, created_at
    from public.gamesessions
    where user_id = p_user_id
    order by created_at desc
    limit p_limit
  )
  select json_build_object('data', coalesce(json_agg(row_to_json(s)), '[]'::json)) from s;
$$;
