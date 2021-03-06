﻿#region Copyright & License

# Copyright © 2012 - 2021 François Chabot
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.u
# See the License for the specific language governing permissions and
# limitations under the License.

#endregion

[CmdletBinding()]
[OutputType([hashtable])]
param(
   [Parameter(Mandatory = $false)]
   [ValidateNotNullOrEmpty()]
   [int]
   $BamArchiveWindowTimeLength = 30,

   [Parameter(Mandatory = $false)]
   [ValidateNotNullOrEmpty()]
   [int]
   $BamOnlineWindowTimeLength = 15,

   [Parameter(Mandatory = $false)]
   [ValidateNotNullOrEmpty()]
   [string]
   $BizTalkAdministratorGroup = "$($env:COMPUTERNAME)\BizTalk Server Administrators",

   [Parameter(Mandatory = $false)]
   [ValidateNotNullOrEmpty()]
   [string]
   $BizTalkApplicationUserGroup = "$($env:COMPUTERNAME)\BizTalk Application Users",

   [Parameter(Mandatory = $false)]
   [ValidateNotNullOrEmpty()]
   [string]
   $BizTalkIsolatedHostUserGroup = "$($env:COMPUTERNAME)\BizTalk Isolated Host Users",

   [Parameter(Mandatory = $false)]
   [ValidateNotNullOrEmpty()]
   [string]
   $BizTalkServerOperatorEmail = "biztalk.factory@stateless.be",

   [Parameter(Mandatory = $false)]
   [ValidateNotNullOrEmpty()]
   [string]
   $ClaimStoreCheckOutDirectory = "C:\Files\Drops\BizTalk.Factory\CheckOut",

   [Parameter(Mandatory = $false)]
   [ValidateNotNullOrEmpty()]
   [string]
   $EnvironmentSettingOverridesType,

   [Parameter(Mandatory = $false)]
   [ValidateNotNullOrEmpty()]
   [string]
   $ManagementServer = $env:COMPUTERNAME,

   [Parameter(Mandatory = $false)]
   [ValidateNotNullOrEmpty()]
   [string]
   $MonitoringServer = $env:COMPUTERNAME,

   [Parameter(Mandatory = $false)]
   [ValidateNotNullOrEmpty()]
   [string]
   $ProcessingServer = $env:COMPUTERNAME

   # [Parameter(Mandatory = $false)]
   # [ValidateNotNullOrEmpty()]
   # [string[]]
   # TODO this is a global variable ; it should be bound to some resource
   # TODO $FileAdapterFolderUsers
)

Set-StrictMode -Version Latest

ApplicationManifest -Name BizTalk.Factory.Activity.Tracking -Description 'BizTalk.Factory''s activity tracking applicatioin add-on for general purpose BizTalk Server development.' -Reference BizTalk.Factory -Build {
   Assembly -Path (Get-ResourceItem -Name Be.Stateless.BizTalk.Activity.Tracking)
   BamActivityModel -Path (Get-ResourceItem -Name ActivityModel -Extension .xml)
   BamIndex -Activity Process -Name BeginTime, InterchangeID, ProcessName, Value1, Value2, Value3
   BamIndex -Activity ProcessMessagingStep -Name MessagingStepActivityID, ProcessActivityID
   BamIndex -Activity MessagingStep -Name InterchangeID, Time, Value1, Value2, Value3
   Binding -Path (Get-ResourceItem -Name Be.Stateless.BizTalk.Factory.Activity.Tracking.Binding) -EnvironmentSettingOverridesType $EnvironmentSettingOverridesType
   Map -Path (Get-ResourceItem -Name Be.Stateless.BizTalk.Claim.Check.Maps)
   ProcessDescriptor -Path (Get-ResourceItem -Name Be.Stateless.BizTalk.Activity.Tracking) -DatabaseServer $ManagementServer
   Schema -Path (Get-ResourceItem -Name Be.Stateless.BizTalk.Claim.Check.Schemas)
   SqlDeploymentScript -Path (Get-ResourceItem -Extension .sql -Name TurnOffGlobalTracking, Create.MonitoringObjects) -Server $ManagementServer
   SqlUndeploymentScript -Path (Get-ResourceItem -Extension .sql -Name Drop.MonitoringObjects) -Server $ManagementServer
   SqlDeploymentScript -Path (Get-ResourceItem -Extension .sql -Name Create.ClaimCheckObjects) -Server $ProcessingServer
   SqlUndeploymentScript -Path (Get-ResourceItem -Extension .sql -Name Drop.ClaimCheckObjects) -Server $ProcessingServer
   SqlDeploymentScript -Path (Get-ResourceItem -Extension .sql -Name Create.BAMPrimaryImportObjects) -Server $MonitoringServer -Variables @{
      BizTalkApplicationUserGroup = $BizTalkApplicationUserGroup
      BamOnlineWindowTimeLength   = $BamOnlineWindowTimeLength
   }
   SqlUndeploymentScript -Path (Get-ResourceItem -Extension .sql -Name Drop.BAMPrimaryImportObjects) -Server $MonitoringServer -Variables @{
      BizTalkApplicationUserGroup = $BizTalkApplicationUserGroup
   }
   SqlDeploymentScript -Path (Get-ResourceItem -Extension .sql -Name Create.BizTalkServerOperator) -Server $ManagementServer -Variables @{
      BizTalkServerOperatorEmail = $BizTalkServerOperatorEmail
   }
   SqlUndeploymentScript -Path (Get-ResourceItem -Extension .sql -Name Drop.BizTalkServerOperator) -Server $ManagementServer
   SqlDeploymentScript -Path (Get-ResourceItem -Extension .sql -Name Create.BamTrackingActivitiesMaintenanceJob) -Server $MonitoringServer -Variables @{
      BamArchiveWindowTimeLength  = $BamArchiveWindowTimeLength
      ClaimStoreCheckOutDirectory = $ClaimStoreCheckOutDirectory
      MonitoringDatabaseServer    = $MonitoringServer
   }
   SqlUndeploymentScript -Path (Get-ResourceItem -Extension .sql -Name Drop.BamTrackingActivitiesMaintenanceJob) -Server $MonitoringServer
   SsoConfigStore -Path (Get-ResourceItem -Name Be.Stateless.BizTalk.Factory.Activity.Tracking.Binding) `
      -AdministratorGroups $BizTalkAdministratorGroup `
      -UserGroups $BizTalkApplicationUserGroup, $BizTalkIsolatedHostUserGroup `
      -EnvironmentSettingOverridesType $EnvironmentSettingOverridesType
}
