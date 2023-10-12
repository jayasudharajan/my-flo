begin;

create table if not exists linked_location (
    flo_loc_id uuid primary key not null,
    moen_loc_id uuid not null,
    flo_acc_id uuid not null,
    created timestamp without time zone default current_timestamp not null
);
create unique index if not exists linked_location_moen_loc_idx on linked_location using btree(moen_loc_id);
create index if not exists linked_location_flo_acc_idx on linked_location using btree(flo_acc_id);

commit;