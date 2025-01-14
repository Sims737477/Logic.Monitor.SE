<#
.SYNOPSIS
    This function initializes the Logic Monitor (POV) setup for SEs by automating various tasks required during POV setup.

.DESCRIPTION
    The Initialize-LMPOVSetup function sets up various components of the Logic Monitor POV. 
    It can set up the website, portal metrics, alert analysis, and LM container. 
    The setup for each component can be controlled individually or all at once.

.PARAMETER Website
    The name of the website to be set up. This parameter is used in both 'All' and 'Individual' parameter sets.

.PARAMETER WebsiteHttpType
    The HTTP type of the website. Defaults to "https". This parameter is used in both 'All' and 'Individual' parameter sets.

.PARAMETER PortalMetricsAPIUsername
    The username for the Portal Metrics API. Defaults to "lm_portal_metrics". This parameter is used in both 'All' and 'Individual' parameter sets.

.PARAMETER LogsAPIUsername
    The username for the Logs API. Defaults to "lm_logs". This parameter is used in both 'All' and 'Individual' parameter sets.

.PARAMETER SetupWebsite
    A switch to control the setup of the website. This parameter is used in the 'Individual' parameter set.

.PARAMETER SetupPortalMetrics
    A switch to control the setup of the portal metrics. This parameter is used in the 'Individual' parameter set.

.PARAMETER SetupAlertAnalysis
    A switch to control the setup of the alert analysis. This parameter is used in the 'Individual' parameter set.

.PARAMETER SetupLMContainer
    A switch to control the setup of the LM container. This parameter is used in the 'Individual' parameter set.

.PARAMETER LMContainerAPIUsername
    The username for the LM Container API. Defaults to "lm_container". This parameter is used in both 'All' and 'Individual' parameter sets.

.EXAMPLE
    Initialize-LMPOVSetup -RunAll -IncludeDefaults -Website example.com

    This command runs all setup processes including default options and creates a webcheck for example.com.

.INPUTS
    The function does not accept input from the pipeline.

.OUTPUTS
    The function does not return any output.

.NOTES
    The function throws an error if it fails to set up any component.
#>


<#
.SYNOPSIS
    This function initializes the Logic Monitor (POV) setup for SEs by automating various tasks required during POV setup.

.DESCRIPTION
    The Initialize-LMPOVSetup function sets up various components of the Logic Monitor POV. 
    It can set up the website, portal metrics, alert analysis, and LM container. 
    The setup for each component can be controlled individually or all at once.

.PARAMETER Website
    The name of the website to be set up. This parameter is used in both 'All' and 'Individual' parameter sets.

.PARAMETER WebsiteHttpType
    The HTTP type of the website. Defaults to "https". This parameter is used in both 'All' and 'Individual' parameter sets.

.PARAMETER PortalMetricsAPIUsername
    The username for the Portal Metrics API. Defaults to "lm_portal_metrics". This parameter is used in both 'All' and 'Individual' parameter sets.

.PARAMETER LogsAPIUsername
    The username for the Logs API. Defaults to "lm_logs". This parameter is used in both 'All' and 'Individual' parameter sets.

.PARAMETER SetupWebsite
    A switch to control the setup of the website. This parameter is used in the 'Individual' parameter set.

.PARAMETER SetupPortalMetrics
    A switch to control the setup of the portal metrics. This parameter is used in the 'Individual' parameter set.

.PARAMETER SetupAlertAnalysis
    A switch to control the setup of the alert analysis. This parameter is used in the 'Individual' parameter set.

.PARAMETER SetupLMContainer
    A switch to control the setup of the LM container. This parameter is used in the 'Individual' parameter set.

.PARAMETER LMContainerAPIUsername
    The username for the LM Container API. Defaults to "lm_container". This parameter is used in both 'All' and 'Individual' parameter sets.

.EXAMPLE
    Initialize-LMPOVSetup -RunAll -IncludeDefaults -Website example.com

    This command runs all setup processes including default options and creates a webcheck for example.com.

.INPUTS
    The function does not accept input from the pipeline.

.OUTPUTS
    The function does not return any output.

.NOTES
    The function throws an error if it fails to set up any component.
#>

#TODO: Update information above. 
Function Initialize-LMSITemplateSetup {
    
    [CmdletBinding(DefaultParameterSetName = 'Individual')]
    Param (
        [Parameter(ParameterSetName = 'Individual')]
        [Switch]$SetupDummyServiceInsight
    )

    #Check if we are logged in and have valid api creds
    Begin {
        #Check for newer version of Logic.Monitor module
        Update-LogicMonitorSEModule -CheckOnly
        Write-Host "[INFO]: Service insight resource (LogicMonitor SI Property Normalizer) is instantiating" -ForegroundColor Gray
    }
    Process {
        $PortalInfo = Get-LMAccountStatus
        write-Host "Checking portal connection"
        If ($($PortalInfo)) {

            #Create dummy service insight that hosts properties for normalization
            If($SetupDummyServiceInsight){
                $ServiceInsightProps = @{
                    device = @(
                        @{
                            deviceGroupFullPath = "*";
                            deviceDisplayName = "*";
                            deviceProperties = @()
                        }
                    )
                } | ConvertTo-Json -Depth 3
                
                #Create pre-built hashtable of SI properties
                $SIProperties = @{
                    "predef.bizService.evalMembersInterval" = "30"
                    "location.region"    = "fill_me_in"
                    "location.country"   = "fill_me_in"
                    "location.state"     = "fill_me_in"
                    "location.city"      = "fill_me_in"
                    "location.site"      = "fill_me_in"
                    "location.type"      = "fill_me_in"
                    "environment"        = "fill_me_in"
                    "owner"              = "fill_me_in"
                    "version"            = "fill_me_in"
                    "service"            = "fill_me_in"
                    "service_component"  = "fill_me_in"
                    "application"        = "fill_me_in"
                    "customer"           = "fill_me_in"
                    "sn.location.region" = "fill_me_in"
                    "sn.location.country"= "fill_me_in"
                    "sn.location.state"  = "fill_me_in"
                    "sn.location.city"   = "fill_me_in"
                    "sn.location.street" = "fill_me_in"
                    "sn.location.type"   = "fill_me_in"
                    "sn.environment"     = "fill_me_in"
                    "sn.service.name"    = "fill_me_in"
                    "sn.service_component" = "fill_me_in"
                    "sn.application"     = "fill_me_in"
                    "sn.customer"        = "fill_me_in"
                    "predef.bizservice.members"          = "$ServiceInsightProps"
                }

                #Create new SI resource
                $ServiceInsightResource = Get-LMDevice -name "SI_Prop_Normalizer"
                If(!$ServiceInsightResource){
                    Write-Host "[INFO]: Service insight resource (LogicMonitor SI Property Normalizer) is deploying" -ForegroundColor Gray
                    $ServiceInsightResource = New-LMDevice -name "SI_Prop_Normalizer" -DisplayName "LogicMonitor SI Property Normalizer" -PreferredCollectorId -4 -DeviceType 6 -Properties $SIProperties
                }
                Else{
                    Write-Host "[INFO]: Service insight resource (LogicMonitor SI Property Normalizer) already exists, skipping creation" -ForegroundColor Gray
                }
            }

            #TODO Deploy the PropSource Normalizer (Where do we host the XML?)
            #Can we add the normalized properties as a function too? 
            #Reverse Engineer those APIs 



        }
        Else {
            Write-Error "Please ensure you are logged in before running any commands, use Connect-LMAccount to login and try again."
        }
    }
    End {}
}

