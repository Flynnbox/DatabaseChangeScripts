/* CHANGE SCRIPT CONTENT TEMPLATE V2.0 */

/* SECTION[METADATA] BEGIN */
/********************************************************************/
/* IMPORTANT: Ensure that each metadata value is proceeded by a " = " and followed by a newline character to avoid errors when parsing */
declare
   /* Name of Change Script: Use format of [YYYYMMDD]_[SEQUENCE NUMBER]_[NAME].sql */
  @FILE_NAME varchar(500) = '<File Name, varchar(500), YYYYMMDD_SequenceNumber_Name>.sql'

   /* Brief Summary of the Changes */
  ,@DESCRIPTION varchar(max) = '<Description, varchar(max), Brief Summary>'

   /* Application or other Context associated with script:
      used for categorization of your scripts */
  ,@EXECUTING_CONTEXT int = <ExecutionContent, int, 100>

   /* Change Script Unique ID: 
      use "select newid()" to generate a value when script is authored */
  ,@CHANGE_SCRIPT_GUID uniqueidentifier = '<Change Script Guid, uniqueidentifier, >'

   /* Start at 1 and increment by 1 each time you make a change to the script: 
      used to force overwrite of a previous version of the script on deploy */
  ,@VERSION tinyint = 1

  /* 0 = Undeploy, 1 = Deploy */
  ,@DEPLOY_ENABLED bit = 1
  ;
/********************************************************************/
/* SECTION[METADATA] END */

use Billing;

/* SECTION[UNDEPLOY_SCRIPT] BEGIN */
/********************************************************************
											Your undeploy code goes here
*********************************************************************/
/* SECTION[UNDEPLOY_SCRIPT] END */


/* SECTION[DEPLOY_SCRIPT] BEGIN */
/********************************************************************
											Your deploy code goes here
*********************************************************************/
/* SECTION[DEPLOY_SCRIPT] END */
