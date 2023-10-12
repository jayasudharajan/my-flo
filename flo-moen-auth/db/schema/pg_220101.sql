begin;

create table if not exists cognito_user (
    id uuid primary key not null,
    flo_user uuid not null,
    issuer varchar(256),
    created timestamp without time zone default current_timestamp not null
);
create unique index if not exists cognito_user_flo_user_idx on cognito_user using btree(flo_user);

alter table cognito_user
    add column if not exists acc_id uuid,
    add column if not exists flo_acc_id uuid;

create index if not exists cognito_user_account_idx on cognito_user using btree(acc_id);
create index if not exists cognito_user_flo_account_idx on cognito_user using btree(flo_acc_id);

drop index if exists cognito_user_flo_user_idx;

create unique index if not exists cognito_user_flo_user_idx on cognito_user using btree(flo_user,issuer);

commit;