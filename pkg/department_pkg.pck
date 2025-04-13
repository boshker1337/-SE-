create or replace package department_pkg as
/*****************************************/
/*Пакет для работы с отделами            */
/*****************************************/
  -- добавление отдела
  procedure add_department(pName in varchar2, pManagerId in number, pDepartmentId out number);
    
  -- получение информации об отделе
  function get_department_info(pDepartmentId in number) return sys_refcursor;
    
  -- валидация отдела
  function validate_department(pDepartmentId in number) return boolean;
    
  -- добавление подчиненного отдела
  procedure add_child_department(pName in varchar2, pManagerId in number, pParentId in number, pDepartmentId out number);
    
end department_pkg;
/
create or replace package body department_pkg as
/*****************************************/
/*Пакет для работы с отделами            */
/*****************************************/
  procedure add_department(pName in varchar2, pManagerId in number, pDepartmentId out number) is
  begin
    pDepartmentId := departments_seq.nextval;
    insert into departments (department_id, name, manager_id)
                     values (pDepartmentId, pName, pManagerId);
        
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'add', 'department', pDepartmentId, null, 'added new department: '||pName);

  end;
    
  function get_department_info(pDepartmentId in number) return sys_refcursor is
    vCursor sys_refcursor;
  begin
    open vCursor for
      select d.department_id, d.name, e.employee_id, e.first_name, e.last_name
        from departments d
        left join employees e on d.manager_id = e.employee_id
       where d.department_id = pDepartmentId;
        
    return vCursor;
  end;
    
  function validate_department(pDepartmentId in number) return boolean is
    vCount number;
  begin
    select count(*) into vCount
      from departments
     where department_id = pDepartmentId;
        
    if vCount > 0 then
      return true;
    end if;
        
    return false;
  end;
    
  procedure add_child_department(pName in varchar2, pManagerId in number, pParentId in number, pDepartmentId out number) is
  begin
    if not validate_department(pParentId) then
      raise_application_error(-20014, 'parent department not found');
    end if;
        
    pDepartmentId := departments_seq.nextval;
    insert into departments (department_id, name, manager_id, parent_id)
                     values (pDepartmentId, pName, pManagerId, pParentId);
        
    --логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'add', 'department', pDepartmentId, null, 'added child department: '||pName||' to parent '||pParentId);
  end;
  
begin
  null;
end department_pkg;
/
