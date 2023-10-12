CREATE TABLE public.user_delivery_system_config (
  user_id UUID NOT NULL,
  version SMALLINT NOT NULL DEFAULT 1,
  CONSTRAINT user_delivery_system_config_pk PRIMARY KEY (user_id)
);

