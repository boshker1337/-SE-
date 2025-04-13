-- категории ресурсов
create table resource_categories (
    category_id number primary key,
    name varchar2(100) not null,
    description varchar2(500)
);

create index idx_resource_categories_name on resource_categories(name);
