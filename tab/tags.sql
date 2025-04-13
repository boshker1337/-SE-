-- теги
create table tags (
    tag_id number primary key,
    name varchar2(50) not null unique
);

create index idx_tags_name on tags(name);
