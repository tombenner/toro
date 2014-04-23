DO $$ BEGIN

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "hstore";

CREATE TABLE toro_jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  queue TEXT NOT NULL CHECK (LENGTH(queue) > 0),
  class_name TEXT NOT NULL CHECK (LENGTH(class_name) > 0),
  args TEXT NOT NULL,
  name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  scheduled_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  finished_at TIMESTAMPTZ,
  status TEXT NOT NULL CHECK (LENGTH(status) > 0),
  started_by TEXT,
  properties HSTORE
);

END $$ LANGUAGE plpgsql;

CREATE FUNCTION toro_notify() RETURNS TRIGGER AS $$ BEGIN
  PERFORM pg_notify('toro_' || new.queue, '');
  RETURN NULL;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER toro_notify
AFTER INSERT ON toro_jobs
FOR EACH ROW
EXECUTE PROCEDURE toro_notify();

CREATE FUNCTION toro_pop(queues TEXT[], process_name TEXT) RETURNS toro_jobs AS $$
DECLARE
  result toro_jobs;
BEGIN
  WITH next_job AS (
    SELECT
      *
    FROM
      toro_jobs
    WHERE
      queue = ANY(queues)
    AND (
        status = 'queued'
      OR
        (status = 'scheduled' AND scheduled_at <= NOW())
    )
    ORDER BY
      created_at ASC
    LIMIT 1
  )
  UPDATE
    toro_jobs
  SET
    status = 'running',
    started_at = NOW(),
    started_by = process_name
  FROM
    next_job
  WHERE
    toro_jobs.id = next_job.id
  RETURNING
    next_job.* INTO result;
  RETURN result;
END $$ LANGUAGE plpgsql;

CREATE INDEX toro_jobs_queue_created_at_index ON toro_jobs (queue, created_at) WHERE status = 'queued' OR status = 'scheduled';
