-- история изменений ресурсов
create table resource_versions (
    version_id number primary key,
    resource_id number not null references resources(resource_id),
    title varchar2(255) not null,
    content clob,
    version_number number not null,
    created_at timestamp default systimestamp,
    created_by number not null references employees(employee_id)
);

create index idx_resource_versions_resource on resource_versions(resource_id);
create index idx_resource_versions_created on resource_versions(created_by);
create index idx_resource_versions_number on resource_versions(resource_id, version_number);
