-- комментарии к ресурсам
create table resource_comments (
    comment_id number primary key,
    resource_id number not null references resources(resource_id),
    employee_id number not null references employees(employee_id),
    comment_text clob not null,
    created_at timestamp default systimestamp,
    updated_at timestamp
);

create index idx_resource_comments_resource on resource_comments(resource_id);
create index idx_resource_comments_employee on resource_comments(employee_id);
create index idx_resource_comments_created on resource_comments(created_at);
