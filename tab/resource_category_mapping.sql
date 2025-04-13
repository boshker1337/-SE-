-- связь ресурсов с категориями
create table resource_category_mapping (
    mapping_id number primary key,
    resource_id number not null references resources(resource_id),
    category_id number not null references resource_categories(category_id),
    assigned_at timestamp default systimestamp,
    assigned_by number not null references employees(employee_id)
);

create index idx_rc_mapping_resource on resource_category_mapping(resource_id);
create index idx_rc_mapping_category on resource_category_mapping(category_id);
create index idx_rc_mapping_composite on resource_category_mapping(resource_id, category_id);
