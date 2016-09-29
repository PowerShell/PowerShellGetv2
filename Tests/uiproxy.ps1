#param($command)

$source = @"
using System;
using System.Collections.Generic;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Management.Automation.Host;

namespace HostUIProxy
{
    public class HostProxy : System.Management.Automation.Host.PSHost
    {
        private System.Management.Automation.Host.PSHost realHost;
        private System.Management.Automation.Host.PSHostUserInterface uiProxy;

        public HostProxy(System.Management.Automation.Host.PSHost realHost, string filePath, int sessionCount)
        {
            this.realHost = realHost;
            uiProxy = new HostUIProxy(realHost.UI, filePath, sessionCount);
        }

        public override System.Globalization.CultureInfo CurrentCulture
        {
            get { return realHost.CurrentCulture; }
        }

        public override System.Globalization.CultureInfo CurrentUICulture
        {
            get { return realHost.CurrentUICulture; }
        }

        public override void EnterNestedPrompt()
        {
            realHost.EnterNestedPrompt();
        }

        public override void ExitNestedPrompt()
        {
            realHost.ExitNestedPrompt();
        }

        public override Guid InstanceId
        {
            get { return realHost.InstanceId; }
        }

        public override string Name
        {
            get { return realHost.Name; }
        }

        public override void NotifyBeginApplication()
        {
            realHost.NotifyBeginApplication();
        }

        public override void NotifyEndApplication()
        {
            realHost.NotifyEndApplication();
        }

        public override void SetShouldExit(int exitCode)
        {
            realHost.SetShouldExit(exitCode);
        }

        public override System.Management.Automation.Host.PSHostUserInterface UI
        {
            get { return uiProxy; }
        }

        public override Version Version
        {
            get { return realHost.Version; }
        }
    }

    public class HostUIProxy : System.Management.Automation.Host.PSHostUserInterface
    {
        private string filePath = string.Empty;
        private int choiceToMake = 0;
        private int sessionCount = 1;
        private System.Management.Automation.Host.PSHostUserInterface realUI;

        public HostUIProxy(System.Management.Automation.Host.PSHostUserInterface realUI, string filePath, int sessionCount)
        {
            this.filePath = filePath;
            this.realUI = realUI;
            this.sessionCount = sessionCount;
        }

        public int ChoiceToMake
        {
            get { return choiceToMake; }
            set { choiceToMake = value; }
        }

        public override Dictionary<string, System.Management.Automation.PSObject> Prompt(string caption, string message, System.Collections.ObjectModel.Collection<System.Management.Automation.Host.FieldDescription> descriptions)
        {
            return realUI.Prompt(caption, message, descriptions);
        }

        public override int PromptForChoice(string caption, string message, System.Collections.ObjectModel.Collection<System.Management.Automation.Host.ChoiceDescription> choices, int defaultChoice)
        {
            WriteToFile(this.filePath, message,"PromptForChoice");
            return ChoiceToMake;
            //return realUI.PromptForChoice(caption, message, choices, defaultChoice);
        }

        public override System.Management.Automation.PSCredential PromptForCredential(string caption, string message, string userName, string targetName, System.Management.Automation.PSCredentialTypes allowedCredentialTypes, System.Management.Automation.PSCredentialUIOptions options)
        {
            return realUI.PromptForCredential(caption, message, userName, targetName, allowedCredentialTypes, options);
        }

        public override System.Management.Automation.PSCredential PromptForCredential(string caption, string message, string userName, string targetName)
        {
            return realUI.PromptForCredential(caption, message, userName, targetName);
        }

        public override System.Management.Automation.Host.PSHostRawUserInterface RawUI
        {
            get { return realUI.RawUI; }
        }

        public override string ReadLine()
        {
            return realUI.ReadLine();
        }

        public override System.Security.SecureString ReadLineAsSecureString()
        {
            return realUI.ReadLineAsSecureString();
        }

        public override void Write(ConsoleColor foregroundColor, ConsoleColor backgroundColor, string value)
        {
            WriteToFile(this.filePath, value,"writewithcolor");
            //realUI.Write(foregroundColor, backgroundColor, value);
        }

        public override void Write(string value)
        {
            WriteToFile(this.filePath, value,"write");
            //realUI.Write(value);
        }

        public override void WriteDebugLine(string message)
        {
            WriteToFile(this.filePath, message, "WriteDebugLine");
            //realUI.WriteDebugLine(message);
        }

        public override void WriteErrorLine(string value)
        {
            WriteToFile(this.filePath, value, "WriteErrorLine");
            //realUI.WriteErrorLine(value);
        }

        public override void WriteLine(string value)
        {
            WriteToFile(this.filePath, value, "WriteLine");
            //realUI.WriteLine(value);
        }

        public override void WriteProgress(long sourceId, System.Management.Automation.ProgressRecord record)
        {
            WriteToFile(this.filePath, record.ToString(), "WriteProgress");
            //realUI.WriteProgress(sourceId, record);
        }

        public override void WriteVerboseLine(string message)
        {
            WriteToFile(this.filePath, message, "WriteVerboseLine");
            //realUI.WriteVerboseLine(message);
        }

        public override void WriteWarningLine(string message)
        {
            WriteToFile(this.filePath, message, "WriteWarningLine");
            //realUI.WriteWarningLine(message.ToUpper());
        }

        private void WriteToFile(string filePath, string message,string type)
        {
           // Validate filepath parameter.          
           // handle null value.
           if (filePath == null)
           {
              throw new ArgumentNullException("filePath cannot be null");
           }
           // handle empty value. 
           if (filePath.Length == 0)
           {
             throw new ArgumentException("filePath cannot be empty");
           }
            
            try
            {

                if (!System.IO.Directory.Exists(filePath))
                {
                    System.IO.Directory.CreateDirectory(filePath);
                }
                for (int i = 0; i < sessionCount; i++)
                {
                    string tempFileName = System.IO.Path.Combine(filePath, (string.Concat(string.Format("{0}-{1}.txt",type,i))));
  
                    System.IO.File.AppendAllText(tempFileName, message.Trim());
                }
            }
            finally
            {
                GC.Collect();
            }
        }
    }
}
"@

Function CreateRunSpace($filePath,$sessionCount)
{
    if ([Type]::GetType('HostUIProxy.HostProxy',$false) -eq $null)
    {
    	add-type -TypeDefinition $source -language CSharp 
    }
    $Global:proxy = new-object HostUIProxy.HostProxy($host,$filePath,$sessionCount)

    $runspace = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($proxy)
    $runspace.Open()

    return $runspace
}

Function ExecuteCommand
{
    [CmdletBinding()]
    param($runspace, $command)

    if($runspace -ne $null)
    {
        $pipe =  $runspace.CreatePipeline($command)

        $pipe.invoke()  
        
        if ($pipe.HadErrors)
        {
            $pipe.Error.ReadToEnd() | write-error
        } 
    }
}

Function CloseRunSpace($runspace)
{
    if($runspace -ne $null)
    {
        $runspace.Close()
    }
}



