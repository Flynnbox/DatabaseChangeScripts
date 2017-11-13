# Database Change Scripts

## Overview
The only method to deploy (or rollback) schema and data changes in a database environment will be through the use of Change Scripts in the [\V1.0.0\FMI.Billing.Database\dbo\ChangeScripts](http://git.foundationmedicine.com/billing/FMI-Billing/tree/master/V1.0.0/FMI.Billing.Database/dbo/ChangeScripts) folder.  
Changes to programmatic database objects (e.g. stored procs, user defined functions, views, triggers, etc) will continue to be through addition or editing of files in the appropriate directory in the [\V1.0.0\FMI.Billing.Database\dbo](http://git.foundationmedicine.com/billing/FMI-Billing/tree/master/V1.0.0/FMI.Billing.Database/dbo) folder.

## Authoring a Change Script
1. A change script should contain an isolated set of changes (schema, data, or both) for a single story or feature.  
   If the changes contained relate to different features or stories consider splitting it into two or more change scripts.  
   A given release may have zero, one, or many change scripts depending on the number of features requiring database changes.  

2. Change scripts should not contain changes to programmable behavior (e.g. jobs, stored procs, functions, views, triggers, etc).  
   These should instead be added into the appropriate directory in the [\V1.0.0\FMI.Billing.Database\dbo](http://git.foundationmedicine.com/billing/FMI-Billing/tree/master/V1.0.0/FMI.Billing.Database/dbo) folder and will be deployed automatically.  
  
3. The template to use when creating a new change script is located in [\V1.0.0\FMI.Billing.Database\Templates\ChangeScript_Content_Template.sql](http://git.foundationmedicine.com/billing/FMI-Billing/blob/master/V1.0.0/FMI.Billing.Database/Templates/ChangeScript_Content_Template.sql).  
   This file has Template Parameters you can automatically fill in in SQL Server Query Analyzer by pressing Ctrl-Shift-M to open the "Replace Template Parameter" dialog.  
   *Do not change the structure of the file as the template is parsed and compiled with the [\V1.0.0\FMI.Billing.Database\Templates\ChangeScript_Master_Template.sql](http://git.foundationmedicine.com/billing/FMI-Billing/blob/master/V1.0.0/FMI.Billing.Database/Templates/ChangeScript_Master_Template.sql) file.*  
   The result of combining the two files is to create the final deployed script which is writted to the \V1.0.0\FMI.Billing.Database\dbo\ChangeScripts_PostCompile folder (note this folder is created automatically and is not part of the project checked into git).
4. Change scripts have a **@FILE_NAME** and should be named in a consistent fashion.  
   When naming the file use the standard naming scheme of "[YYYYMMDD]_[Two digit sequence number, begin with 00 for each new day]_[Camel cased label of key change].sql" (for example “20161223_03_PatientBilling_AddColumn_ParentTRF.sql”).  
   The two digit sequence number is used to explicitly order scripts created on the same day when the order in which they are run is significant.  
   If ordering between scripts is important, consider combining them into a single script.  
   The **@FILE_NAME** and the name of the change script file should match.
5. Change scripts have a **@DESCRIPTION** that summarizes the changes being made.
6. Change scripts have an **@EXECUTING_CONTEXT** integer value which uniquely identifies that project or application they are associated with.  
   The **@EXECUTING_CONTEXT** for Duckling is 100.
7. Change scripts have a **@CHANGE_SCRIPT_GUID**, which uniquely identifies them.  
   This unique identifier allows the script to detect if it is already in a given environment and prevent re-deploy.  
   You can create a GUID in sql server by running the statement “select newid()”.
8. Change scripts have a **@VERSION** value and are versioned so that during iterative development they can be deployed multiple times to an environment.  
   If the change script is updated after it has been deployed to any database, then the **@VERSION** number should also be incremented by 1.  
   This will allow a re-deploy to go forward because the new version number is not yet present in that environment.  
9. Change Scripts have a **@DEPLOY_ENABLED** bit value which indicates whether they will be scheduled for Deploy or Undeploy.  
   Use a value of 1 for Deploy and a value of 0 to Undeploy (or disable deployment of) the change. 
10. Change scripts have a Undeploy section for your code marked out with **/\* SECTION[UNDEPLOY_SCRIPT] BEGIN \*/** and **/\* SECTION[UNDEPLOY_SCRIPT] END */**.  
    All code related to rolling back this change should go in this section.  
    Avoid making use of "go" batch statement.  If this is not possible, break your change script into multiple changes.
    The Undeploy section of the change script is run before any Deploy to clean up prior versions of Deployed artifacts.  
    Undeploy code should be authored to be able to rollback all changes from the deployment to the prior state AND be able to be run multiple times in an environment without error.  
    This requires checking for the presence of changed objects and handling them appropriately (e.g. if creating a table and it exists, drop it, etc).  
    Ask your tech lead if you have a question on how to handle a specific case.  
    In the case of changes to data discuss with your tech lead how to handle this as it may be very difficult or impossible to rollback updates to records.
11. Change scripts have a Deploy section for your code marked out with **/\* SECTION[DEPLOY_SCRIPT] BEGIN \*/** and **/\* SECTION[DEPLOY_SCRIPT] END */**.  
    All code related to deployment should go in this section.  
    Avoid making use of "go" batch statement.  If this is not possible, break your change script into multiple changes.
    The code should be authored to be able to be deployed multiple times into an environment without error.  
    This requires checking for the presence of changed objects and handling them appropriately (e.g. if creating a table and it exists, drop it first before creating again, etc).  
    Ask your tech lead if you have a question on how to handle a specific case.  
    In the case of changes to data discuss with your tech lead how to handle this as it may be very difficult or impossible to updates to records multiple times.
12. When a change script runs (either deploy or undeploy) it checks for the existence of a record in the logDatabaseChange table with the **@EXECUTING_CONTEXT**, **@CHANGE_SCRIPT_GUID**, **@VERSION** of that change script.  
    If no such record exists, it inserts a new record with a value of 100 (for a Deploy) or 200 (for an Undeploy).  
    If a Deploy was scheduled and it succeeds then the ChangeStatusId value in the table should be 110 after the script runs.  
    If a Undeploy was scheduled and it succeeds, then the ChangeStatusId value in the table should be 210 after the script runs.  
    You can query this table if you want to understand which changes have been deployed in which database.   
    *DO NOT make any manual updates or inserts into the logDatabaseChange table because this can interfere with the correct functioning of the change script template.*
    Ask your tech lead if you have any questions.

Please feel free to take a look at existing change scripts as examples of how to author new change scripts (note that 20161221_00_logDatabaseChange.sql and 20161222_00_logDatabaseChange_CreateDucklingContext.sql do not follow the standard pattern and should not be used for reference).