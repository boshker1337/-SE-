-- таблица предоставленных доступов
create table resource_access (
    access_id number primary key,
    resource_id number not null references resources(resource_id),
    employee_id number not null references employees(employee_id),
    granted_by number not null references employees(employee_id), -- кто предоставил доступ
    granted_at timestamp default systimestamp,
    is_manager_granted number(1) default 0 -- 1 - доступ предоставлен начальником
);

create index idx_resource_access_resource on resource_access(resource_id);
create index idx_resource_access_employee on resource_access(employee_id);
create index idx_resource_access_granted on resource_access(granted_by);
create index idx_resource_access_composite on resource_access(resource_id, employee_id);
