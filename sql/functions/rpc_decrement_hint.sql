-- RPC: decrement hint (50/50) for a user atomically and return the new count
create or replace function rpc_decrement_hint(p_user_id int)
returns table(new_count int)
language plpgsql
security definer
as $$
declare
  v_new int;
begin
  update users
  set hints_count = greatest(coalesce(hints_count,0) - 1, 0)
  where user_id = p_user_id
  returning hints_count into v_new;
  return query select v_new as new_count;
end;
$$;
