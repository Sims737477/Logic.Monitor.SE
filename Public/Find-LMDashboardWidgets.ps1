<#
.SYNOPSIS
Find list of dashboard widgets containing mention of specified datasources

.DESCRIPTION
Find list of dashboard widgets containing mention of specified datasources

.EXAMPLE
Find-LMDashboardWidgets -DatasourceNames @("SNMP_NETWORK_INTERFACES","VMWARE_VCETNER_VM_PERFORMANCE")

.NOTES
Created groups will be placed in a main group called Azure Resources by Subscription in the parent group specified by the -ParentGroupId parameter

.INPUTS
DatasourceNames in an array. You can also pipe datasource names to this widget.

.LINK
Module repo: https://github.com/stevevillardi/Logic.Monitor.SE

.LINK
PSGallery: https://www.powershellgallery.com/packages/Logic.Monitor.SE
#>
Function Find-LMDashboardWidgets{
    Param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [Alias("DatasourceName")]
        [String[]]$DatasourceNames,

        [String]$GroupPathSearchString = "*"
    )

    #Check if we are logged in and have valid api creds
    Begin {}
    Process {
        If ($(Get-LMAccountStatus).Valid) {
            $Results = New-Object System.Collections.ArrayList
            $Dashboards = Get-LMDashboard | Where-Object {$_.groupFullPath -like "$GroupPathSearchString"}

            $i = 0
            $DashCount = ($Dashboards | Measure-Object).Count
            Foreach($Dashboard in $Dashboards){
                Write-Progress -Activity "Processing Dashboard: $($Dashboard.name)" -Status "$([Math]::Floor($($i/$DashCount*100)))% Completed" -PercentComplete $($i/$DashCount*100) -Id 0
                $Widgets = Get-LMDashboardWidget -DashboardId $Dashboard.Id

                $GraphWidgets = $Widgets | Where-Object {$_.type -eq "cgraph"}
                If($GraphWidgets.graphInfo.datapoints.dataSourceFullName){$GraphWidgetsFiltered = $GraphWidgets.graphInfo.datapoints | Where-Object {$DatasourceNames -contains $_.dataSourceFullName.Split("(")[-1].Replace(")","")}}
                
                $BigNumberWidgets = $Widgets | Where-Object {$_.type -eq "bigNumber"}
                If($BigNumberWidgets.bigNumberInfo.dataPoints.dataSourceFullName){$BigNumberWidgetsFiltered = $BigNumberWidgets.bigNumberInfo.dataPoints | Where-Object {$DatasourceNames -contains $_.dataSourceFullName.Split("(")[-1].Replace(")","")}}
                
                $PieWidgets = $Widgets | Where-Object {$_.type -eq "pieChart"}
                If($PieWidgets.pieChartInfo.dataPoints.dataSourceFullName){$PieWidgetsFiltered = $PieWidgets.pieChartInfo.dataPoints | Where-Object {$DatasourceNames -contains $_.dataSourceFullName.Split("(")[-1].Replace(")","")}}

                $TableWidgets = $Widgets | Where-Object {$_.type -eq "dynamicTable"}
                If($TableWidgets.dataSourceFullName){$TableWidgetsFiltered = $TableWidgets | Where-Object {$DatasourceNames -contains $_.dataSourceFullName.Split("(")[-1].Replace(")","")}}

                $SLAWidgets = $Widgets | Where-Object {$_.type -eq "deviceSLA"}
                If($SLAWidgets.metrics.dataSourceFullName){$SLAWidgetsFiltered = $SLAWidgets.metrics | Where-Object {$DatasourceNames -contains $_.dataSourceFullName.Split("(")[-1].Replace(")","")}}

                $NOCWidgets = $Widgets | Where-Object {$_.type -eq "noc"}
                If($NOCWidgets.items.dataSourceDisplayName){$NOCWidgetsFiltered = $NOCWidgets.items | Where-Object {$DatasourceNames -contains $_.dataSourceDisplayName.Replace("\","")}}

                $GaugeWidgets = $Widgets | Where-Object {$_.type -eq "gauge"}
                If($GaugeWidgets.dataPoint.dataSourceFullName){$GaugeWidgetsFiltered = $GaugeWidgets.dataPoint | Where-Object {$DatasourceNames -contains $_.dataSourceFullName.Split("(")[-1].Replace(")","")}}

                If($GraphWidgetsFiltered){
                    $GraphWidgetsFiltered | ForEach-Object {$RefObj = $_ ;$Results.Add([PSCustomObject]@{
                        dataSourceId = $_.dataSourceId
                        dataSourceFullName = $_.dataSourceFullName
                        dataPointId = $_.dataPointId
                        dataPointName = $_.dataPointName
                        widgetType = "cgraph"
                        widgetId = ($GraphWidgets | Where-Object {$_.graphInfo.datapoints -eq $RefObj}).Id
                        widgetName = ($GraphWidgets | Where-Object {$_.graphInfo.datapoints -eq $RefObj}).Name
                        dashboardId = $Dashboard.id
                        dashboardName = $Dashboard.name
                        dashboardPath = $Dashboard.groupFullPath
                    }) | Out-Null}
                }

                If($BigNumberWidgetsFiltered){
                    $BigNumberWidgetsFiltered | ForEach-Object {$RefObj = $_ ;$Results.Add([PSCustomObject]@{
                        dataSourceId = $_.dataSourceId
                        dataSourceFullName = $_.dataSourceFullName
                        dataPointId = $_.dataPointId
                        dataPointName = $_.dataPointName
                        widgetType = "bigNumber"
                        widgetId = ($BigNumberWidgets | Where-Object {$_.bigNumberInfo.dataPoints -eq $RefObj}).Id
                        widgetName = ($BigNumberWidgets | Where-Object {$_.bigNumberInfo.dataPoints -eq $RefObj}).Name
                        dashboardId = $Dashboard.id
                        dashboardName = $Dashboard.name
                        dashboardPath = $Dashboard.groupFullPath
                    }) | Out-Null}
                }

                If($PieWidgetsFiltered){
                    $PieWidgetsFiltered | ForEach-Object {$RefObj = $_ ;$Results.Add([PSCustomObject]@{
                        dataSourceId = $_.dataSourceId
                        dataSourceFullName = $_.dataSourceFullName
                        dataPointId = $_.dataPointId
                        dataPointName = $_.dataPointName
                        widgetType = "pieChart"
                        widgetId = ($PieWidgets | Where-Object {$_.pieChartInfo.dataPoints -eq $RefObj}).Id
                        widgetName = ($PieWidgets | Where-Object {$_.pieChartInfo.dataPoints -eq $RefObj}).Name
                        dashboardId = $Dashboard.id
                        dashboardName = $Dashboard.name
                        dashboardPath = $Dashboard.groupFullPath
                    }) | Out-Null}
                }

                If($TableWidgetsFiltered){
                    $TableWidgetsFiltered | ForEach-Object {$Results.Add([PSCustomObject]@{
                        dataSourceId = $_.dataSourceId
                        dataSourceFullName = $_.dataSourceFullName
                        dataPointId = "N/A"
                        dataPointName = "N/A"
                        widgetType = "dynamicTable"
                        widgetId = $_.id
                        widgetName = $_.name
                        dashboardId = $Dashboard.id
                        dashboardName = $Dashboard.name
                        dashboardPath = $Dashboard.groupFullPath
                    }) | Out-Null}
                }

                If($SLAWidgetsFiltered){
                    $SLAWidgetsFiltered | ForEach-Object {$RefObj = $_ ;$Results.Add([PSCustomObject]@{
                        dataSourceId = $_.dataSourceId
                        dataSourceFullName = $_.dataSourceFullName
                        dataPointId = $_.dataPointId
                        dataPointName = $_.dataPointName
                        widgetType = "deviceSLA"
                        widgetId = ($SLAWidgets | Where-Object {$_.metrics -eq $RefObj}).Id
                        widgetName = ($SLAWidgets | Where-Object {$_.metrics -eq $RefObj}).Name
                        dashboardId = $Dashboard.id
                        dashboardName = $Dashboard.name
                        dashboardPath = $Dashboard.groupFullPath
                    }) | Out-Null}
                }

                If($NOCWidgetsFiltered){
                    $NOCWidgetsFiltered | ForEach-Object {$RefObj = $_ ;$Results.Add([PSCustomObject]@{
                        dataSourceId = $_.dataSourceId
                        dataSourceFullName = $_.dataSourceFullName
                        dataPointId = $_.dataPointId
                        dataPointName = $_.dataPointName
                        widgetType = "noc"
                        widgetId = ($NOCWidgets | Where-Object {$_.items -eq $RefObj}).Id
                        widgetName = ($NOCWidgets | Where-Object {$_.items -eq $RefObj}).Name
                        dashboardId = $Dashboard.id
                        dashboardName = $Dashboard.name
                        dashboardPath = $Dashboard.groupFullPath
                    }) | Out-Null}
                }

                If($GaugeWidgetsFiltered){
                    $GaugeWidgetsFiltered | ForEach-Object {$RefObj = $_ ;$Results.Add([PSCustomObject]@{
                        dataSourceId = $_.dataSourceId
                        dataSourceFullName = $_.dataSourceFullName
                        dataPointId = $_.dataPointId
                        dataPointName = $_.dataPointName
                        widgetType = "gauge"
                        widgetId = ($GaugeWidgets | Where-Object {$_.dataPoint -eq $RefObj}).Id
                        widgetName = ($GaugeWidgets | Where-Object {$_.dataPoint -eq $RefObj}).Name
                        dashboardId = $Dashboard.id
                        dashboardName = $Dashboard.name
                        dashboardPath = $Dashboard.groupFullPath
                    }) | Out-Null}
                }
                $i++
            }

        }
        Else {
            Write-Error "Please ensure you are logged in before running any commands, use Connect-LMAccount to login and try again."
        }
    }
    End {
        Return (Add-ObjectTypeInfo -InputObject $Results -TypeName "LogicMonitor.WidgetSearch" )
    }
}