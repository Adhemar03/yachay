-- SQL function to award the "Líder del Ranking" achievement to current Top10 users
-- This script creates a stored procedure that finds the Top10 users (by total final_score in gamesessions)
-- and inserts rows to userachievements for users who don't already have the achievement.

-- Usage: run once (to create). Then schedule it with your DB scheduler (pg_cron, Supabase scheduled jobs, etc.)

CREATE OR REPLACE FUNCTION public.award_lider_ranking()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  lid integer;
BEGIN
  -- obtener achievement_id por nombre (case-insensitive)
  SELECT achievement_id INTO lid
  FROM achievements
  WHERE name ILIKE 'Líder del Ranking'
  LIMIT 1;

  IF lid IS NULL THEN
    RAISE NOTICE 'award_lider_ranking: achievement "Líder del Ranking" not found';
    RETURN;
  END IF;

  -- calcular Top10 por suma de puntajes en gamesessions
  WITH totals AS (
    SELECT user_id, COALESCE(SUM(final_score), 0) AS total_score
    FROM gamesessions
    GROUP BY user_id
    ORDER BY total_score DESC
    LIMIT 10
  )
  -- insertar en userachievements sólo donde no exista ya
  INSERT INTO userachievements (user_id, achievement_id, earned_at)
  SELECT t.user_id, lid, NOW()
  FROM totals t
  LEFT JOIN userachievements ua
    ON ua.user_id = t.user_id AND ua.achievement_id = lid
  WHERE ua.user_id IS NULL;
END;
$$;

-- Optional: ejemplo para ejecutar inmediatamente
-- SELECT public.award_lider_ranking();

-- Nota: Para programarlo periódicamente en Supabase, use la sección de "Database > Scheduled Jobs"
-- o configure pg_cron si está disponible.
