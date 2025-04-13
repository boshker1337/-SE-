-- связь ресурсов с тегами
create table resource_tags (
    resource_tag_id number primary key,
    resource_id number not null references resources(resource_id),
    tag_id number not null references tags(tag_id),
    assigned_at timestamp default systimestamp,
    assigned_by number not null references employees(employee_id)
);

create index idx_resource_tags_resource on resource_tags(resource_id);
create index idx_resource_tags_tag on resource_tags(tag_id);
create index idx_resource_tags_composite on resource_tags(resource_id, tag_id);
