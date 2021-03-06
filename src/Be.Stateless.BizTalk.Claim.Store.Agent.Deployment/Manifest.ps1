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
   [Parameter(Mandatory = $true)]
   [ValidateNotNullOrEmpty()]
   [pscredential]
   $Credential,

   [Parameter(Mandatory = $false)]
   [ValidateNotNullOrEmpty()]
   [ValidateScript( { Test-Path -Path $_ } )]
   [string]
   $CheckInDirectory = 'C:\Files\Drops\BizTalk.Factory\CheckIn',

   [Parameter(Mandatory = $false)]
   [ValidateNotNullOrEmpty()]
   [ValidateScript( { Test-Path -Path $_ } )]
   [string]
   $CheckOutDirectory = 'C:\Files\Drops\BizTalk.Factory\CheckOut',

   [Parameter(Mandatory = $false)]
   [ValidateNotNullOrEmpty()]
   [ValidateScript( { Test-Path -Path $_ } )]
   [string]
   $LogDirectory = 'C:\Files\Logs\',

   [Parameter(Mandatory = $false)]
   [ValidateSet('ALL', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL', 'OFF')]
   [string]
   $LogLevel = 'DEBUG',

   [Parameter(Mandatory = $false)]
   [ValidateNotNullOrEmpty()]
   [string]
   $ProcessingServer = $env:COMPUTERNAME,

   [Parameter(Mandatory = $false)]
   [AllowEmptyCollection()]
   [ValidateNotNull()]
   [string[]]
   $TargetHosts = @($env:COMPUTERNAME)
)

Set-StrictMode -Version Latest

$claimStoreAgentConfigurationFile = Get-ResourceItem -Name Be.Stateless.BizTalk.Claim.Store.Agent.exe -Extension .config

LibraryManifest -Name BizTalk.Factory.Claim.Store.Agent -Description 'BizTalk.Factory''s Claim Store Agent.' -Build {
   EventLogSource -Name 'Claim Store Agent' -LogName Application
   WindowsService -Path (Get-ResourceItem -Name Be.Stateless.BizTalk.Claim.Store.Agent) `
      -Name BF_CSA `
      -Credential $Credential `
      -StartupType AutomaticDelayedStart `
      -DisplayName 'BizTalk Factory Claim Store Agent' `
      -Description 'This service moves the files that are captured by the claim and tracking infrastructure on the BizTalk Server nodes towards a central location. Stopping the service will cause claimed and tracked files to accumulate on the BizTalk Server nodes disk.' `
      -Condition ($env:COMPUTERNAME -in $TargetHosts)
   XmlConfigurationAction -Path $claimStoreAgentConfigurationFile `
      -Update /configuration/be.stateless/biztalk/claimStore/agent `
      -Attributes @{ checkOutDirectory = $CheckOutDirectory }
   XmlConfigurationAction -Path $claimStoreAgentConfigurationFile `
      -Update /configuration/be.stateless/biztalk/claimStore/agent/checkInDirectories/directory `
      -Attributes @{ path = $CheckInDirectory }
   XmlConfigurationAction -Path $claimStoreAgentConfigurationFile `
      -Update "/configuration/connectionStrings/add[@name='TransientStateDb']" `
      -Attributes @{ connectionString = "Data Source=$ProcessingServer;Initial Catalog=BizTalkFactoryTransientStateDb;Integrated Security=True" }
   XmlConfigurationAction -Path $claimStoreAgentConfigurationFile `
      -Update "/configuration/log4net/appender[@name='RollingFileAppender']/file" `
      -Attributes @{ value = Join-Path -Path $LogDirectory -ChildPath 'Claim.Store.Agent.log' }
   XmlConfigurationAction -Path $claimStoreAgentConfigurationFile `
      -Update /configuration/log4net/root/level `
      -Attributes @{ value = $LogLevel }
}
