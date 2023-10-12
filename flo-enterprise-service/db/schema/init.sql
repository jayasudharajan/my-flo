-- #NOTE: schema bootstrap only happens if ./db/tmp/postgres is missing!
-- (See same message in docker-compose file)

-- *********************************************
-- CREATE TABLES IF THEY DON'T EXIST
-- *********************************************

-- DROP TABLE public.mud_task;
CREATE TABLE IF NOT EXISTS public.mud_task (
	id bpchar(32) NOT NULL,
	mac_address bpchar(12) NULL,
	"type" varchar NOT NULL,
	status int4 NOT NULL,
	created_at timestamp NOT NULL,
	updated_at timestamp NOT NULL,
	CONSTRAINT mud_task_pk PRIMARY KEY (id)
);
CREATE INDEX mud_task_mac_address_index ON public.mud_task USING btree (mac_address);

-- DROP TABLE public.mud_threshold_defaults;
CREATE TABLE IF NOT EXISTS public.mud_threshold_defaults (
	account_id bpchar(32) NULL,
	threshold_values_json json NOT NULL,
	start_minute int4 NOT NULL DEFAULT 0,
	end_minute int4 NOT NULL DEFAULT 0,
	"order" int4 NOT NULL DEFAULT 0,
	repeat_json json NOT NULL,
	created_at timestamp NOT NULL,
	updated_at timestamp NOT NULL,
	make varchar NULL
);
