-- RPC: increment a power counter (used by tienda when user purchases)
-- p_power must be 'hint' or 'skip'
create or replace function rpc_increment_power(p_user_id int, p_power text, p_amount int)
returns table(new_count int)
language plpgsql
security definer
as $$
begin
  if p_power = 'hint' then
    update users set hints_count = coalesce(hints_count,0) + p_amount where user_id = p_user_id returning hints_count as new_count;
  elsif p_power = 'skip' then
    update users set skips_count = coalesce(skips_count,0) + p_amount where user_id = p_user_id returning skips_count as new_count;
  else
    raise exception 'unknown power type %', p_power;
  end if;
end;
$$;
