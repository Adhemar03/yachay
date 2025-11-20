-- RPC: decrement skip (next question) for a user atomically and return the new count
create or replace function rpc_decrement_skip(p_user_id int)
returns table(new_count int)
language plpgsql
security definer
as $$
begin
  update users
  set skips_count = greatest(coalesce(skips_count,0) - 1, 0)
  where user_id = p_user_id
  returning skips_count as new_count;
end;
$$;
