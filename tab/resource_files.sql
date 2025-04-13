-- прикрепленные файлы
create table resource_files (
    file_id number primary key,
    resource_id number not null references resources(resource_id),
    file_name varchar2(255) not null,
    file_size number not null,
    file_type varchar2(100),
    file_content blob,
    uploaded_at timestamp default systimestamp,
    uploaded_by number not null references employees(employee_id)
);

create index idx_resource_files_resource on resource_files(resource_id);
create index idx_resource_files_uploaded on resource_files(uploaded_by);
create index idx_resource_files_name on resource_files(file_name);
