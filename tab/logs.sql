--Логи
create table logs (
    log_id number primary key,
    action_type varchar2(50) not null,
    entity_type varchar2(50) not null,
    entity_id number,
    performed_by number references employees(employee_id),
    performed_at timestamp default systimestamp,
    details varchar2(4000)
);

create index idx_app_logs_id in logs(log_id);
create index idx_app_logs_action_type in logs(action_type);
create index idx_app_logs_performed_at in logs(performed_at);
