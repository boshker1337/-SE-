create or replace package employee_pkg as
/***************************************/
/*Пакет для работы с сотрудниками      */
/***************************************/
  -- добавление сотрудника
  procedure add_employee(pFirstName in varchar2, pLastName in varchar2, pDepartmentId in number, pEmployeeId out number);
    
  -- удаление сотрудника
  procedure remove_employee(pEmployeeId in number);
    
  -- получение списка сотрудников
  function get_employees_list return sys_refcursor;
    
  -- получение детальной информации о сотруднике
  function get_employee_details(pEmployeeId in number) return sys_refcursor;
    
  -- обновление настроек доступа
  procedure update_access_setting(pEmployeeId in number, p_allow_access in number);
    
  -- валидация сотрудника
  function validate_employee(pEmployeeId in number) return boolean;
  
end employee_pkg;

/
create or replace package body employee_pkg as
/***************************************/
/*Пакет для работы с сотрудниками      */
/***************************************/
  function validate_employee(pEmployeeId in number) return boolean is
    vCount number;
  begin
    select count(*) into vCount
      from employees
     where employee_id = pEmployeeId;
    
    if vCount > 0 then
      return true;
    end if;
    
    return false;
  end;

  procedure add_employee(pFirstName in varchar2, pLastName in varchar2, pDepartmentId in number, pEmployeeId out number) is
  begin
    if not department_pkg.validate_department(pDepartmentId) then
       raise_application_error(-20001, 'department not found');
    end if;
        
    pEmployeeId := employees_seq.nextval;
    insert into employees (employee_id, first_name, last_name, department_id)
                   values (pEmployeeId, pFirstName, pLastName, pDepartmentId);
        
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'add', 'employee', pEmployeeId, null, 'added new employee: '||pFirstName||' '||pLastName);
  end;
    
  procedure remove_employee(pEmployeeId in number) is
  begin
    if not validate_employee(pEmployeeId) then
      raise_application_error(-20002, 'employee not found');
    end if;
        
    -- проверяем, не является ли сотрудник начальником отдела
    for rec in (select department_id from departments where manager_id = pEmployeeId) loop
      raise_application_error(-20003, 'cannot remove department manager');
    end loop;
        
    delete from employees where employee_id = pEmployeeId;
        
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'delete', 'employee', pEmployeeId, null, 'employee removed');
  end;
    
  function get_employees_list return sys_refcursor is
    vCursor sys_refcursor;
  begin
    open vCursor for
      select e.employee_id, e.first_name, e.last_name, d.name as department
        from employees e
        join departments d on e.department_id = d.department_id;
          
    return vCursor;
  end;
    
  function get_employee_details(pEmployeeId in number) return sys_refcursor is
    vCursor sys_refcursor;
  begin
    if not validate_employee(pEmployeeId) then
      raise_application_error(-20002, 'employee not found');
    end if;
        
    open vCursor for
      select e.employee_id, e.first_name, e.last_name, e.allow_access,
             d.department_id, d.name as department_name,
             (select count(*) from resources r where r.owner_id = e.employee_id) as resources_count,
             (select count(*) from resource_access ra where ra.employee_id = e.employee_id) as shared_access_count
        from employees e
        join departments d on e.department_id = d.department_id
       where e.employee_id = pEmployeeId;
        
    return vCursor;
  end;
    
  procedure update_access_setting(pEmployeeId in number, p_allow_access in number) is
  begin
    if not validate_employee(pEmployeeId) then
      raise_application_error(-20002, 'employee not found');
    end if;
        
    update employees
       set allow_access = p_allow_access,
           updated_at = systimestamp
     where employee_id = pEmployeeId;
        
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'update', 'employee', pEmployeeId, null, 'access setting updated to: '||p_allow_access);
  end;

begin
  null;
end employee_pkg;
/
