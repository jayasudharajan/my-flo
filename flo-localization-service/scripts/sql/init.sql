DROP TABLE IF EXISTS assets cascade;
CREATE TABLE assets (
  id varchar,
  name varchar default '',
  type varchar default 'display',
  locale varchar default 'en-us',
  released boolean default false,
  value varchar default '',
  tags varchar[] default array[]::varchar[],
  created timestamp with time zone default now() not null,
  updated timestamp with time zone default now() not null,
  primary key(id),
  unique (type, name, locale)
);

DROP TABLE IF EXISTS locales cascade;
CREATE TABLE locales (
  id varchar,
  fallback varchar default 'en-us',
  released boolean default false,
  created timestamp with time zone default now() not null,
  updated timestamp with time zone default now() not null,
  primary key (id)
);

DROP TABLE IF EXISTS tags cascade;
CREATE TABLE tags (
  id varchar,
  description varchar default '',
  created timestamp with time zone default now() not null,
  updated timestamp with time zone default now() not null,
  primary key(id)
);