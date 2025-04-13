-- таблица ресурсов (документация)
create table resources (
    resource_id number primary key,
    title varchar2(255) not null, -- название ресурса
    owner_id number not null references employees(employee_id), -- владелец
    created_at timestamp default systimestamp,
    updated_at timestamp
);

create index idx_resources_owner on resources(owner_id);
create index idx_resources_title on resources(title);
create index idx_resources_created on resources(created_at);
