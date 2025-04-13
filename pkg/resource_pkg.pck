create or replace package resource_pkg as
/*****************************************/
/*Пакет для работы с ресурсами           */
/*****************************************/
    -- добавление ресурса
    procedure add_resource(pTitle in varchar2, pOwnerId in number, pResourceId out number);
    
    -- удаление ресурса
    procedure remove_resource(pResourceId in number, pEmployeeId in number/*кто удаляет*/);  
    
    -- получение списка ресурсов сотрудника
    function get_employee_resources(pEmployeeId in number) return sys_refcursor;
    
    -- получение списка доступных ресурсов (тех, к которым сотруднику предоставили доступ)
    function get_shared_resources(pEmployeeId in number) return sys_refcursor;
    
    -- предоставление доступа к ресурсу
    procedure grant_resource_access(pResourceId in number, pOwnerId in number/*владелец ресурса*/, pEmployeeId in number/*кому предоставляем доступ*/,pGrantedBy in number/*кто предоставляет доступ*/);
    
    -- удаление доступа к ресурсу
    procedure revoke_resource_access(pAccessId in number, pRequestedBy in number/*кто запрашивает удаление*/);
    
    -- добавление ограничения доступа
    procedure add_access_restriction(pEmployeeId in number, pRestrictedEmployeeId in number);
    
    -- удаление ограничения доступа
    procedure remove_access_restriction(pRestrictionId in number, pRequestedBy in number);
    
    -- валидация ресурса
    function validate_resource(pResourceId in number ) return boolean;
    
    -- создание новой версии ресурса
    procedure create_resource_version(pResourceId in number, pTitle in varchar2, pContent in clob, pEmployeeId in number);
    
    -- получение истории версий ресурса
    function get_resource_versions(pResourceId in number ) return sys_refcursor;
    
    -- добавление категории к ресурсу
    procedure add_resource_category(pResourceId in number, pCategoryId in number, pEmployeeId in number);
    
    -- удаление категории у ресурса
    procedure remove_resource_category(pMappingId in number, pEmployeeId in number);
    
    -- добавление комментария
    procedure add_comment(pResourceId in number, pEmployeeId in number, pCommentText in clob, pCommentId out number);
    
    -- обновление комментария
    procedure update_comment(pCommentId in number, pEmployeeId in number, pNewText in clob);
    
    -- добавление тега к ресурсу
    procedure add_tag_to_resource(pResourceId in number, pTagId in number, pEmployeeId in number);
    
    -- создание нового тега
    procedure create_tag(pName in varchar2, pTagId out number);
    
    -- поиск ресурсов с фильтрами
    function search_resources(pSearchText in varchar2 default null, pCategoryId in number default null, pTagId in number default null,
                              pOwnerId in number default null, pCreatedFrom in date default null, pCreatedTo in date default null) return sys_refcursor;
    
    -- прикрепление файла к ресурсу
    procedure attach_file(pResourceId in number, pFileName in varchar2, pFileSize in number, pFileType in varchar2,
                          pFileContent in blob, pEmployeeId in number, pFileId out number);
    
    -- Запрет доступа (общий или для конкретных сотрудников)
    procedure restrict_access(pEmployeeId in number, -- ID сотрудника, который устанавливает ограничение
                              pRestrictAll in number, -- 1 - запретить всем, 0 - снять общий запрет
                              pRestrictedEmployeeId in number default null -- Конкретный сотрудник для запрета (Может реализовать списком?????)
    );
    
    -- Удаление предоставленного доступа
    procedure revoke_granted_access(pAccessId in number,-- ID записи о доступе
                                    pRequestedBy in number -- ID сотрудника, который запрашивает отзыв
    );
    
    -- Проверка прав на управление доступом
    function can_manage_access(pEmployeeId in number, -- ID сотрудника, который пытается управлять доступом
                               pTargetEmployeeId in number  -- ID сотрудника, к чьим ресурсам обращаются
    ) return boolean;
    
end resource_pkg;
/
create or replace package body resource_pkg as
/*****************************************/
/*Пакет для работы с ресурсами           */
/*****************************************/
  procedure add_resource(pTitle in varchar2, pOwnerId in number, pResourceId out number) is
  begin
    if not employee_pkg.validate_employee(pOwnerId) then
      raise_application_error(-20002, 'owner not found');
    end if;
      
    pResourceId := resources_seq.nextval;
    insert into resources (resource_id, title, owner_id)
                   values (pResourceId, pTitle, pOwnerId);
      
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'add', 'resource', pResourceId, pOwnerId, 'added new resource: '||pTitle);
  end;
  
  procedure remove_resource(pResourceId in number, pEmployeeId in number) is
    vOwnerId number;
  begin
    if validate_resource(pResourceId) then
      raise_application_error(-20004, 'resource not found');
    end if;
      
    -- проверяем, является ли сотрудник владельцем ресурса
    select owner_id into vOwnerId
      from resources
     where resource_id = pResourceId;
      
    if vOwnerId != pEmployeeId then
      raise_application_error(-20005, 'only resource owner can delete it');
    end if;
      
    -- сначала удаляем все доступы к ресурсу
    delete from resource_access where resource_id = pResourceId;
      
    -- затем удаляем сам ресурс
    delete from resources where resource_id = pResourceId;
      
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'delete', 'resource', pResourceId, pEmployeeId, 'resource removed');
  end;
  
  function get_employee_resources(pEmployeeId in number) return sys_refcursor is
    vCursor sys_refcursor;
  begin
    if not employee_pkg.validate_employee(pEmployeeId) then
      raise_application_error(-20002, 'employee not found');
    end if;
      
    open vCursor for
      select r.resource_id, r.title, r.created_at
        from resources r
       where r.owner_id = pEmployeeId
       order by r.created_at desc;
      
    return vCursor;
  end;
  
  function get_shared_resources(pEmployeeId in number) return sys_refcursor is
    vCursor sys_refcursor;
  begin
    if not employee_pkg.validate_employee(pEmployeeId) then
      raise_application_error(-20002, 'employee not found');
    end if;
      
    open vCursor for
      select r.resource_id, r.title, e.first_name||' '||e.last_name as owner_name,
             ra.granted_at, ra.is_manager_granted
        from resource_access ra
        join resources r on ra.resource_id = r.resource_id
        join employees e on r.owner_id = e.employee_id
       where ra.employee_id = pEmployeeId
       order by ra.granted_at desc;
      
    return vCursor;
  end;
  
  procedure grant_resource_access(pResourceId in number, pOwnerId in number, pEmployeeId in number, pGrantedBy in number) is
    vIsManager number := 0;
    vDepartmentId number;
    vAllowAccess number;
    vIsRestricted number;
  begin
    -- проверка существования ресурса и владельца
    if validate_resource(pResourceId) then
      raise_application_error(-20004, 'resource not found');
    end if;
      
    if not employee_pkg.validate_employee(pOwnerId) then
      raise_application_error(-20002, 'owner not found');
    end if;
      
    if not employee_pkg.validate_employee(pEmployeeId) then
      raise_application_error(-20002, 'employee not found');
    end if;
      
    if not employee_pkg.validate_employee(pGrantedBy) then
      raise_application_error(-20002, 'grantor not found');
    end if;
      
    -- проверяем, является ли предоставляющий доступ начальником
    select count(*) into vIsManager
      from departments
     where manager_id = pGrantedBy;
      
    if vIsManager = 1 then
      -- если начальник, проверяем, что он начальник отдела сотрудника
      select d.department_id into vDepartmentId
        from employees e
        join departments d on e.department_id = d.department_id
       where e.employee_id = pEmployeeId;
          
      select count(*) into vIsManager
        from departments
       where department_id = vDepartmentId
         and manager_id = pGrantedBy;
    end if;
      
    -- если не начальник, проверяем, что предоставляет доступ владелец ресурса
    if vIsManager = 0 and pGrantedBy != pOwnerId then
      raise_application_error(-20006, 'only owner or manager can grant access');
    end if;
      
    -- проверяем, разрешает ли сотрудник доступ
    select allow_access into vAllowAccess
      from employees
     where employee_id = pEmployeeId;
      
    if vAllowAccess = 0 then
      raise_application_error(-20007, 'employee does not allow access');
    end if;
      
    -- проверяем, не запретил ли владелец ресурса доступ этому сотруднику
    if pGrantedBy != pOwnerId then
      select count(*) into vIsRestricted
        from access_restrictions
       where employee_id = pOwnerId
         and (restricted_employee_id = pGrantedBy or restricted_employee_id is null);
          
      if vIsRestricted > 0 and vIsManager = 0 then
        raise_application_error(-20036, 'владелец ресурса запретил предоставлять доступ');
      end if;
    end if;
      
    -- проверяем, не запретил ли сотрудник доступ конкретно этому человеку
    select count(*) into vIsRestricted
      from access_restrictions
     where employee_id = pEmployeeId
       and restricted_employee_id = pGrantedBy;
      
    if vIsRestricted > 0 and vIsManager = 0 then
      raise_application_error(-20008, 'employee restricted access for this user');
    end if;
      
    -- проверяем, не предоставлен ли уже доступ
    select count(*) into vIsRestricted
      from resource_access
     where resource_id = pResourceId
       and employee_id = pEmployeeId;
      
    if vIsRestricted > 0 then
      raise_application_error(-20009, 'access already granted');
    end if;
      
    -- предоставляем доступ
    insert into resource_access (access_id, resource_id, employee_id, granted_by, is_manager_granted)
                         values (resource_access_seq.nextval, pResourceId, pEmployeeId, pGrantedBy, vIsManager);
      
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'grant', 'access', resource_access_seq.currval, pGrantedBy, 'access granted to resource '||pResourceId||' for employee '||pEmployeeId);
  end;
  
  procedure revoke_resource_access(pAccessId in number, pRequestedBy in number) is
    vAccessRec resource_access%rowtype;
    vIsManager number := 0;
    vDepartmentId number;
  begin
    -- получаем информацию о доступе
    select * into vAccessRec
      from resource_access
     where access_id = pAccessId;
      
    -- проверяем, является ли запрашивающий начальником
    select count(*) into vIsManager
      from departments
     where manager_id = pRequestedBy;
      
    if vIsManager = 1 then
      -- если начальник, проверяем, что он начальник отдела сотрудника
      select e.department_id into vDepartmentId
        from employees e
       where e.employee_id = vAccessRec.employee_id;
          
      select count(*) into vIsManager
        from departments
       where department_id = vDepartmentId
         and manager_id = pRequestedBy;
    end if;
      
    -- проверяем права на удаление доступа
    if vIsManager = 0 and 
      pRequestedBy != vAccessRec.granted_by and 
      pRequestedBy != vAccessRec.employee_id then
      raise_application_error(-20010, 'no rights to revoke this access');
    end if;
      
    -- если доступ предоставлен начальником, только он может его удалить
    if vAccessRec.is_manager_granted = 1 and vIsManager = 0 then
      raise_application_error(-20011, 'only manager can revoke manager-granted access');
    end if;
      
    -- удаляем доступ
    delete from resource_access where access_id = pAccessId;
      
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'revoke', 'access', pAccessId, pRequestedBy, 'access revoked');
  end;
  
  procedure add_access_restriction(pEmployeeId in number, pRestrictedEmployeeId in number ) is
    vCount number;
  begin
    if not employee_pkg.validate_employee(pEmployeeId) then
      raise_application_error(-20002, 'employee not found');
    end if;
      
    if not employee_pkg.validate_employee(pRestrictedEmployeeId) then
      raise_application_error(-20002, 'restricted employee not found');
    end if;
      
    -- проверяем, не существует ли уже такого ограничения
    select count(*) into vCount
      from access_restrictions
     where employee_id = pEmployeeId
       and restricted_employee_id = pRestrictedEmployeeId;
      
    if vCount > 0 then
      raise_application_error(-20012, 'restriction already exists');
    end if;
      
    -- добавляем ограничение
    insert into access_restrictions (restriction_id, employee_id, restricted_employee_id)
                             values (access_restrictions_seq.nextval, pEmployeeId, pRestrictedEmployeeId);
      
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'add', 'restriction', access_restrictions_seq.currval, pEmployeeId, 'added restriction for employee '||pRestrictedEmployeeId);
  end;
  
  procedure remove_access_restriction(pRestrictionId in number, pRequestedBy in number) is
    vEmployeeId number;
  begin
    -- получаем сотрудника, который установил ограничение
    select employee_id into vEmployeeId
      from access_restrictions
     where restriction_id = pRestrictionId;
      
    -- проверяем права на удаление
    if vEmployeeId != pRequestedBy then
      raise_application_error(-20013, 'only restriction owner can remove it');
    end if;
      
    -- удаляем ограничение
    delete from access_restrictions where restriction_id = pRestrictionId;
      
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'remove', 'restriction', pRestrictionId, pRequestedBy, 'access restriction removed');
  end;
  
  function validate_resource(pResourceId in number) return boolean is
    vCount number;
  begin
    select count(*) into vCount
      from resources
     where resource_id = pResourceId;
    
    if vCount > 0 then
      return true;
    end if;
     
    return false;
  end;
  
  procedure create_resource_version(pResourceId in number, pTitle in varchar2, pContent in clob, pEmployeeId in number) is
    vVersionNumber number;
  begin
    if not validate_resource(pResourceId) then
      raise_application_error(-20004, 'resource not found');
    end if;
      
    -- получаем следующий номер версии
    select nvl(max(version_number), 0) + 1 into vVersionNumber
      from resource_versions
     where resource_id = pResourceId;
      
    -- создаем новую версию
    insert into resource_versions (version_id, resource_id, title, content, version_number, created_by)
                           values (resource_versions_seq.nextval, pResourceId, pTitle, pContent, vVersionNumber, pEmployeeId);
      
    -- обновляем текущий заголовок ресурса
    update resources
       set title = pTitle,
           updated_at = systimestamp
     where resource_id = pResourceId;
      
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'version', 'resource', pResourceId, pEmployeeId, 'created new version '||vVersionNumber);
  end;
  
  function get_resource_versions(pResourceId in number) return sys_refcursor is
    vCursor sys_refcursor;
  begin
    open vCursor for
      select v.version_id, v.title, v.version_number, 
             v.created_at, e.first_name||' '||e.last_name as created_by
        from resource_versions v
        join employees e on v.created_by = e.employee_id
       where v.resource_id = pResourceId
       order by v.version_number desc;
      
    return vCursor;
  end;
  
  procedure add_resource_category(pResourceId in number, pCategoryId in number, pEmployeeId in number ) is
    vCount number;
  begin
    -- проверяем существование категории
    select count(*) into vCount
      from resource_categories
     where category_id = pCategoryId;
      
    if vCount = 0 then
      raise_application_error(-20015, 'category not found');
    end if;
      
    -- проверяем, не добавлена ли уже категория
    select count(*) into vCount
      from resource_category_mapping
     where resource_id = pResourceId
       and category_id = pCategoryId;
      
    if vCount > 0 then
      raise_application_error(-20016, 'resource already has this category');
    end if;
      
    -- добавляем категорию
    insert into resource_category_mapping (mapping_id, resource_id, category_id, assigned_by)
                                   values (resource_category_mapping_seq.nextval, pResourceId, pCategoryId,pEmployeeId);
      
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'add', 'category', pCategoryId, pEmployeeId, 'added category to resource '||pResourceId);
  end;
  
  procedure remove_resource_category(pMappingId in number, pEmployeeId in number) is
    vResourceId number;
    vCategoryId number;
  begin
    -- получаем информацию
    select resource_id, category_id into vResourceId, vCategoryId
      from resource_category_mapping
     where mapping_id = pMappingId;
      
    -- удаляем категорию
    delete from resource_category_mapping
     where mapping_id = pMappingId;
      
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'remove', 'category', vCategoryId, pEmployeeId, 'removed category from resource '||vResourceId);
  end;
  
  procedure add_comment(pResourceId in number, pEmployeeId in number, pCommentText in clob, pCommentId out number) is
    vHasAccess number;
  begin
    -- проверяем доступ к ресурсу
    select count(*) into vHasAccess
      from resource_access
     where resource_id = pResourceId
       and employee_id = pEmployeeId;
      
    if vHasAccess = 0 then
      -- проверяем, не владелец ли
      select count(*) into vHasAccess
        from resources
       where resource_id = pResourceId
        and owner_id = pEmployeeId;
          
      if vHasAccess = 0 then
        raise_application_error(-20017, 'no access to resource');
      end if;
    end if;
      
    -- добавляем комментарий
    pCommentId := resource_comments_seq.nextval;
    insert into resource_comments (comment_id, resource_id, employee_id, comment_text)
                           values (pCommentId, pResourceId, pEmployeeId, pCommentText);
      
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'add', 'comment', pCommentId, pEmployeeId, 'added comment to resource '||pResourceId);
  end;
  
  procedure update_comment(pCommentId in number, pEmployeeId in number, pNewText in clob) is
    vCommentAuthor number;
  begin
    -- получаем автора комментария
    select employee_id into vCommentAuthor
      from resource_comments
     where comment_id = pCommentId;
      
    -- проверяем права на редактирование
    if vCommentAuthor != pEmployeeId then
      raise_application_error(-20018, 'only comment author can edit it');
    end if;
      
    -- обновляем комментарий
    update resource_comments
       set comment_text = pNewText,
           updated_at = systimestamp
     where comment_id = pCommentId;
      
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'update', 'comment', pCommentId, pEmployeeId, 'comment updated');
  end;
  
  procedure add_tag_to_resource(pResourceId in number, pTagId in number, pEmployeeId in number ) is
    vCount number;
  begin
    -- проверяем существование тега
    select count(*) into vCount
      from tags
     where tag_id = pTagId;
      
    if vCount = 0 then
      raise_application_error(-20019, 'tag not found');
    end if;
      
    -- проверяем, не добавлен ли уже тег
    select count(*) into vCount
      from resource_tags
     where resource_id = pResourceId
       and tag_id = pTagId;
      
    if vCount > 0 then
      raise_application_error(-20020, 'tag already added to resource');
    end if;
      
    -- добавляем тег
    insert into resource_tags (resource_tag_id, resource_id, tag_id, assigned_by)
                       values (resource_tags_seq.nextval, pResourceId, pTagId, pEmployeeId);
      
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'add', 'tag', pTagId, pEmployeeId, 'added tag to resource '||pResourceId);
  end;
  
  procedure create_tag(pName in varchar2, pTagId out number) is
    vCount number;
  begin
    -- проверяем, не существует ли уже тега с таким именем
    select count(*) into vCount
      from tags
     where lower(name) = lower(pName);
      
    if vCount > 0 then
      raise_application_error(-20021, 'tag already exists');
    end if;
      
    -- создаем тег
    pTagId := tags_seq.nextval;
    insert into tags (tag_id, name)
              values (pTagId, pName);
      
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'create', 'tag', pTagId, null, 'created new tag: '||pName);
  end;
  
  function search_resources( pSearchText in varchar2 default null, pCategoryId in number default null, pTagId in number default null,
                             pOwnerId in number default null, pCreatedFrom in date default null, pCreatedTo in date default null ) return sys_refcursor is
    vCursor sys_refcursor;
    vSql varchar2(4000);
    vWhere varchar2(2000) := ' where 1=1 ';
  begin
    -- формируем условия поиска
    if pSearchText is not null then
      vWhere := vWhere || 
                ' and (lower(r.title) like ''%''||lower(:pSearchText)||''%'' ' ||
                ' or exists (select 1 from resource_versions v ' ||
                ' where v.resource_id = r.resource_id ' ||
                ' and lower(v.content) like ''%''||lower(:pSearchText)||''%'')) ';
    end if;
        
    if pCategoryId is not null then
      vWhere := vWhere || 
              ' and exists (select 1 from resource_category_mapping cm ' ||
              ' where cm.resource_id = r.resource_id ' ||
              ' and cm.category_id = :pCategoryId) ';
    end if;
        
    if pTagId is not null then
      vWhere := vWhere || 
              ' and exists (select 1 from resource_tags rt ' ||
              ' where rt.resource_id = r.resource_id ' ||
              ' and rt.tag_id = :pTagId) ';
    end if;
        
    if pOwnerId is not null then
      vWhere := vWhere || ' and r.owner_id = :pOwnerId ';
    end if;
        
    if pCreatedFrom is not null then
      vWhere := vWhere || ' and r.created_at >= :pCreatedFrom ';
    end if;
        
    if pCreatedTo is not null then
      vWhere := vWhere || ' and r.created_at <= :pCreatedTo ';
    end if;
        
    vSql := 'select r.resource_id, r.title, ' ||
            'e.first_name||'' ''||e.last_name as owner_name, ' ||
            'r.created_at ' ||
            'from resources r ' ||
            'join employees e on r.owner_id = e.employee_id ' ||
            vWhere ||
            'order by r.created_at desc';
        
    -- открываем курсор с соответствующими параметрами
    if pSearchText is not null and pCategoryId is not null and pTagId is not null and pOwnerId is not null and pCreatedFrom is not null and pCreatedTo is not null then
      open vCursor for vSql 
      using pSearchText, pSearchText, pCategoryId, pTagId, 
      pOwnerId, pCreatedFrom, pCreatedTo;
    elsif pSearchText is not null and pCategoryId is not null and pTagId is not null and pOwnerId is not null then
      open vCursor for vSql 
      using pSearchText, pSearchText, pCategoryId, pTagId, pOwnerId;
    elsif pSearchText is not null and pCategoryId is not null then
      open vCursor for vSql 
      using pSearchText, pSearchText, pCategoryId;
    elsif pSearchText is not null then
      open vCursor for vSql 
      using pSearchText, pSearchText;
    else
      open vCursor for vSql;
    end if;
        
    return vCursor;
  end;
  
  procedure attach_file(pResourceId in number, pFileName in varchar2, pFileSize in number, pFileType in varchar2,
                        pFileContent in blob, pEmployeeId in number, pFileId out number ) is
    vHasAccess number;
  begin
    -- проверяем доступ к ресурсу
    select count(*) into vHasAccess
      from resource_access
     where resource_id = pResourceId
       and employee_id = pEmployeeId;
      
    if vHasAccess = 0 then
      -- проверяем, не владелец ли
      select count(*) into vHasAccess
        from resources
       where resource_id = pResourceId
         and owner_id = pEmployeeId;
          
      if vHasAccess = 0 then
        raise_application_error(-20017, 'no access to resource');
      end if;
    end if;
      
    -- прикрепляем файл
    pFileId := resource_files_seq.nextval;
    insert into resource_files (file_id, resource_id, file_name, file_size, file_type, file_content, uploaded_by)
                        values (pFileId, pResourceId, pFileName, pFileSize, pFileType, pFileContent, pEmployeeId);
      
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'attach', 'file', pFileId, pEmployeeId, 'attached file to resource '||pResourceId);

  end;
  procedure restrict_access(pEmployeeId in number, pRestrictAll in number, pRestrictedEmployeeId in number default null) is
    vIsManager number;
  begin
    -- валидация входных данных
    if not employee_pkg.validate_employee(pEmployeeId) then
      raise_application_error(-20030, 'сотрудник не найден');
    end if;
      
    -- если указан конкретный сотрудник для запрета
    if pRestrictedEmployeeId is not null then
      if not employee_pkg.validate_employee(pRestrictedEmployeeId) then
        raise_application_error(-20031, 'указанный сотрудник для ограничения не найден');
      end if;
          
      -- проверяем, не пытается ли сотрудник ограничить доступ своему начальнику
      select count(*) into vIsManager
        from departments d
        join employees e on d.department_id = e.department_id
       where d.manager_id = pRestrictedEmployeeId
         and e.employee_id = pEmployeeId;
          
      if vIsManager > 0 then
        raise_application_error(-20032, 'нельзя ограничить доступ своему начальнику');
      end if;
          
      -- добавляем или удаляем ограничение для конкретного сотрудника
      if pRestrictAll = 1 then
        -- проверяем, нет ли уже такого ограничения
        declare
          vExists number;
        begin
          select count(*) into vExists
            from access_restrictions
           where employee_id = pEmployeeId
             and restricted_employee_id = pRestrictedEmployeeId;
                  
          if vExists = 0 then
            insert into access_restrictions (restriction_id, employee_id, restricted_employee_id ) 
                                     values (access_restrictions_seq.nextval, pEmployeeId, pRestrictedEmployeeId);
                      --LOG!!!!!!!!!!!!!!!!!!
          end if;
        end;
      else
        delete from access_restrictions
         where employee_id = pEmployeeId
           and restricted_employee_id = pRestrictedEmployeeId;
              --LOG!!!!!!!!!!!!!!!!!!
      end if;
    else
      -- устанавливаем или снимаем общий запрет доступа
      update employees
         set allow_access = case when pRestrictAll = 1 then 0 else 1 end,
             updated_at = systimestamp
       where employee_id = pEmployeeId;
          --LOG!!!!!!!!!!!!!!!!!!
    end if;
      
    commit;
  exception
    when others then
        --LOG!!!!!!!!!!!!!!!!!!
      rollback;
      raise;
  end;
  
  procedure revoke_granted_access(pAccessId in number, pRequestedBy   in number) is
    vAccessRec resource_access%rowtype;
    vIsManager number := 0;
    vIsOwner number := 0;
    vTargetEmployeeId number;
  begin
    -- получаем информацию о доступе
    begin
      select * into vAccessRec
        from resource_access
       where access_id = pAccessId;
    exception
      when no_data_found then
        raise_application_error(-20033, 'запись о доступе не найдена');
    end;
      
    -- проверяем права на отзыв доступа
    -- 1. проверяем, является ли запрашивающий владельцем ресурса
    select count(*) into vIsOwner
      from resources
     where resource_id = vAccessRec.resource_id
       and owner_id = pRequestedBy;
      
    -- 2. проверяем, является ли запрашивающий начальником
    if vIsOwner = 0 then
      -- получаем отдел сотрудника, которому предоставлен доступ
      select e.department_id into vTargetEmployeeId
        from employees e
       where e.employee_id = vAccessRec.employee_id;
          
      -- проверяем, является ли запрашивающий начальником отдела
      select count(*) into vIsManager
        from departments
       where department_id = vTargetEmployeeId
         and manager_id = pRequestedBy;
    end if;
      
    -- 3. проверяем, является ли запрашивающий тем, кому предоставлен доступ
    if vIsOwner = 0 and vIsManager = 0 and vAccessRec.employee_id != pRequestedBy then
      raise_application_error(-20034, 'недостаточно прав для отзыва доступа');
    end if;
      
    -- 4. если доступ предоставлен начальником, проверяем особые условия
    if vAccessRec.is_manager_granted = 1 then
      -- получаем отдел сотрудника, которому предоставлен доступ
      select e.department_id into vTargetEmployeeId
        from employees e
       where e.employee_id = vAccessRec.employee_id;
          
      -- проверяем, является ли запрашивающий текущим начальником
      select count(*) into vIsManager
        from departments
       where department_id = vTargetEmployeeId
         and manager_id = pRequestedBy;
          
      if vIsManager = 0 then
        raise_application_error(-20035, 'доступ предоставлен начальником - только начальник может его отозвать');
      end if;
    end if;
      
    -- удаляем доступ
    delete from resource_access
     where access_id = pAccessId;
      --LOG!!!!!!!!!!!!!!!!!!
      
    commit;
  exception
    when others then
        --LOG!!!!!!!!!!!!!!!!!!
      rollback;
      raise;
  end;
  
  function can_manage_access(pEmployeeId in number, pTargetEmployeeId in number) return boolean is
    vIsManager number := 0;
    vTargetDepartmentId number;
  begin
    -- проверяем валидность сотрудников
    if not employee_pkg.validate_employee(pEmployeeId) or not employee_pkg.validate_employee(pTargetEmployeeId) then
      return false;
    end if;
      
    -- сотрудник всегда может управлять своими настройками
    if pEmployeeId = pTargetEmployeeId then
      return true;
    end if;
      
    -- получаем отдел целевого сотрудника
    select department_id into vTargetDepartmentId
      from employees
     where employee_id = pTargetEmployeeId;
      
    -- проверяем, является ли сотрудник начальником отдела целевого сотрудника
    select count(*) into vIsManager
      from departments
     where department_id = vTargetDepartmentId
       and manager_id = pEmployeeId;
      
    if vIsManager > 0 then
      return true;
    end if;
      
    return false;
  exception
    when others then
        --LOG!!!!!!!!!!!!!!!!!!
      return false;
  end ;

begin
  null;
end resource_pkg;
/
