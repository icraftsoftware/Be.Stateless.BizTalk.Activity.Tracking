﻿#region Copyright & License

// Copyright © 2012 - 2020 François Chabot
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
// http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#endregion

using System;
using System.Collections;
using System.Configuration.Install;
using Be.Stateless.BizTalk.Install.Command;

namespace Be.Stateless.BizTalk.Install
{
	public abstract class ProcessNameInstaller : Installer
	{
		internal ProcessNameInstaller() { }

		#region Base Class Member Overrides

		public override void Install(IDictionary stateSaver)
		{
			base.Install(stateSaver);
			var cmd = new ProcessNameRegistrationCommand {
				DataSource = Context.Parameters["DataSource"],
				ProcessNames = GetProcessNames()
			};
			cmd.Execute(Console.WriteLine);
		}

		public override void Uninstall(IDictionary savedState)
		{
			base.Uninstall(savedState);
			var cmd = new ProcessNameUnregistrationCommand {
				DataSource = Context.Parameters["DataSource"],
				ProcessNames = GetProcessNames()
			};
			cmd.Execute(Console.WriteLine);
		}

		#endregion

		protected abstract string[] GetProcessNames();
	}
}
