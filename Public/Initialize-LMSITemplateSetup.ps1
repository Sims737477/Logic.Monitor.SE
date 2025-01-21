<#
.SYNOPSIS
    This function initializes a LogicMonitor ServiceInsight that contains default standardized properties that all clients should utilize in SI Templates. 
    It also pushes the PropertySource that will make those properties Auto.props. 

.DESCRIPTION
    The Initialize LMSITemplate Setup script generates an SI that contains normalized properties, then pushes a PropertySource to turn those into Auto.props. 

.PARAMETER SetupDummyServiceInsight
    A switch to control the setup of the LM SI. This parameter is used in the 'Individual' parameter set.

.EXAMPLE
    Initialize-LMSITemplateSetup -SetupDummyServiceInsight

    This command runs all setup processes for the SI and PropSource

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
                # Base URI for module templates
                $GitubURI = "https://raw.githubusercontent.com/Sims737477"

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
                    "DummyService"       = "True"
                    "predef.bizservice.members"          = "$ServiceInsightProps"
                }

                #Before provisioning the SI we need an active collector for the PropSource to work. 
                $collector = Get-LMCollector -BatchSize 1
                
                if ($collector) {
                    #Create new SI resource
                    $ServiceInsightResource = Get-LMDevice -name "SI_Prop_Normalizer"
                    If(!$ServiceInsightResource){
                        Write-Host "[INFO]: Service insight resource (LogicMonitor SI Property Normalizer) is deploying" -ForegroundColor Gray
                        $ServiceInsightResource = New-LMDevice -name "SI_Prop_Normalizer" -DisplayName "LogicMonitor SI Property Normalizer" -PreferredCollectorId $collector[0].id -DeviceType 6 -Properties $SIProperties
                    }
                    Else{
                        Write-Host "[INFO]: Service insight resource (LogicMonitor SI Property Normalizer) already exists, skipping creation" -ForegroundColor Gray
                    }
                }else{
                    Write-Error "[ERROR]: There are no collectors in the portal. Please assign a collector to the Service once they're available." 
                    # IF we don't have a collector we can still provision the SI, but the propsource won't run and the collector needs to be manually assigned. 
                    #Create new SI resource
                    $ServiceInsightResource = Get-LMDevice -name "SI_Prop_Normalizer"
                    If(!$ServiceInsightResource){
                        Write-Host "[INFO]: Service insight resource (LogicMonitor SI Property Normalizer) is deploying" -ForegroundColor Gray
                        $ServiceInsightResource = New-LMDevice -name "SI_Prop_Normalizer" -DisplayName "LogicMonitor SI Property Normalizer" -PreferredCollectorId -4 -DeviceType 6 -Properties $SIProperties
                        Write-Error "The SI Prop Normalizer was deployed, but there were no active Collectors to assign to the SI. Please manually assign the collector."
                    }
                    Else{
                        Write-Host "[INFO]: Service insight resource (LogicMonitor SI Property Normalizer) already exists, skipping creation" -ForegroundColor Gray
                    }
                }
                $NormalizingPropSource = Get-LMPropertySource -Name "NormalisedProps"
                if (!$NormalizingPropSource){
                    #Upload PropertyNormalizer PropertySource. 
                    Try{
                        $NormalizingPropSource = (Invoke-WebRequest -Uri "$GitubURI/LM_templates/main/NormalisedProps.json" -UseBasicParsing).Content
                        Import-LMLogicModule -File $NormalizingPropSource -Type propertyrules -ErrorAction Stop
                    }
                    Catch{
                        #Error
                        Write-Error "[ERROR]: Unable to add PropertySource template from source: $_" 
                    }

                }else{
                    Write-Host "[INFO]: Property Normalizing PropSource Already Exists." -ForegroundColor Gray
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

