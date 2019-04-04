# Command line DCRUM Health Check data collection tool
# Chris Vidler - Dynatrace DCRUM SME 2019



# configuration
$serveraddr = "http://127.0.0.1/"

# login (admin reqd.), token takes precedence over user/pass if defined.
# seems you need the Internal API token, not a public token. Copy from RUMC
#$username = "adminuser"
#$password = "Password1"
# or
$apitoken = ""

# query timeout (seconds)
$resttimeout = 900





# depreaciated - now automatically determined
## determine DMI query compatability, pick the highest one that matches your CAS
## 0 = 12.3.x
## 1 = 12.4.x
## 2 = 2017.x, 2018.x
##$cas_version = 2


# --- code follows ---

Write-Host "DC RUM / NAM Capacity Planning Data Collection" -ForegroundColor Yellow
Write-Host "Check connectivity, credentials and version to $serveraddr"

# build authentication string
if ($apitoken) {
    $header = @{ "Authorization" = "Bearer $apitoken" }
    Write-Host "Using token authentication"
} else {
    $header = "${username}:${password}"
    #write-host $header
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($header)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $basic = "Basic $base64"
    #write-host $basic
    $header = @{ "Authorization" = "$basic" }
    Write-Host "Using basic (user/pass) authentication"
}



# clean up serveraddr of suffix '/'
if ($serveraddr.Substring($serveraddr.Length-1,1) = "/") { $serveraddr = $serveraddr.Substring(0, $serveraddr.Length -1) }



# version (and access) check
# version is only checked on the CAS you initially query,
# may cause issues in mixed version farms - it's unsupported anyway.
$uri = $serveraddr + "/RemoteServlet?test=1"
Try
{
    $verstring = @(Invoke-WebRequest -Uri $uri -Headers $header -TimeoutSec $resttimeout -ErrorAction Stop).Content.Split('|')
}
Catch
{
    $ErrorMessage = $_.Exception.Message
    write-host "Error accessing CAS: The error message was $ErrorMessage"
    Break
}
$verstring = @($verstring[11]).Split(':')
write-host "CAS version:" $verstring[1]
$cas_version = [long]("{0:D2}{1:D2}{2:D2}" -f [int]$verstring[1].split('.')[0], [int]$verstring[1].split('.')[1], [int]$verstring[1].split('.')[2])
#write-host "CAS version:" $cas_version



# list all CAS in cluster
#$uri = $serveraddr + "/rest/dmiquery/getDMIData3"
#$post =  @{"appId"="SYSTEMDIAG"
#"viewId"="MemoryStatus"
#"dimensionIds"=@("dataProd","begT")
#"metricIds"=@('cRestart')
#"resolution"="d"
#"dimFilters"=@()
#"metricFilters"=@()
#"sort"=@()
#"topFilter"=0
#"timePeriod"="d"
#"numberOfPeriods"=365
#"dataSourceId"="ALL_AGGR"} | ConvertTo-Json -Compress
#$post
#$header += @{"Content-Type"="application/json"}

$uri = $uri + "?appId=SYSTEMDIAG&viewId=MemoryStatus&dimensionIds=['dataProd','begT']&metricIds=['cRestart']&resolution=d&dimFilters=[]&metricFilters=[]&sort=[]&topFilter=0&timePeriod=d&numberOfPeriods=365&dataSourceId=ALL_AGGR"
Try
{
    #$cases = @(Invoke-WebRequest -Uri $uri -Headers $header -TimeoutSec $resttimeout -Method Post -Body $post -ErrorAction Stop).Content | ConvertFrom-Json | select -expand formattedData -ErrorAction Stop
    $cases = @(Invoke-WebRequest -Uri $uri -Headers $header -TimeoutSec $resttimeout -ErrorAction Stop).Content | ConvertFrom-Json | select -expand formattedData -ErrorAction Stop
}
Catch
{
    $ErrorMessage = $_.Exception.Message
    write-host "Error accessing CAS: The error message was $ErrorMessage"
    Break
}
$cases = $cases | ForEach-Object { $_[0] } | unique
#$cases = $cases | ForEach-Object { $_[0] }             # DEBUG CODE - DOESN'T REMOVE DUPLICATES A BAD IDEA
[int]$num_cases = $cases.count
write-host $num_cases "CASes in this cluster:" $cases

#break

# array of REST queries and query names (used to build file names) to run
# minimum version compatability, "REST query string", "query name"
$querylist = @(
# MEM_Output
@(120300,"rest/dmiquery/getDMIData2?appId=SYSTEMDIAG&viewId=MemoryStatus&dimensionIds=['begT','dataProd']&metricIds=['cRestart','avgUsedM','procMemResident','procMemUsage','xmxMem','totalMem']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","MEM_Output"),

# PRC_Output
@(120300,"rest/dmiquery/getDMIData3?appId=SYSTEMDIAG&viewId=ProcStatus&dimensionIds=['begT','dataProd']&metricIds=['procTime','avgProcTime','maxProcTime','avgDowTime','maxDowTime','partProcTimeT1','partCpuUsageT1','cpuTime','cpuUsage','cntCPUs','procLin','avgDelay']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","PRC_Output"),

# SES_Output
@(120300,"rest/dmiquery/getDMIData3?appId=SYSTEMDIAG&viewId=MemoryStatus&dimensionIds=['begT','dataProd']&metricIds=['maxSessions','maxRawSessions','maxAggrSessions','sessThreshold','sessAlert']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","SES_Output"),

# DSK_Output 12.4+ only
@(120400,"rest/dmiquery/getDMIData3?appId=SYSTEMDIAG&viewId=DiskUsage&dimensionIds=['begT','dataProd','disk']&metricIds=['usedBytes','freeBytes','bytes']&resolution=1&dimFilters=[]&metricFilters=[['bytes','>',0,1]]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","DSK_Output"),

# DBS_Output 12.3 and 12.4+ versions
@(120300,"rest/dmiquery/getDMIData3?appId=HM&viewId=DbStatus&dimensionIds=['begT','dataProd','tableGrp']&metricIds=['avgData','avgUnused','avgSize','avgIndex','maxStoredInterval','avgStoredInterval','avgRows','avgTablesCount']&resolution=r&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&top=0&timePeriod=d&numberOfPeriods=1&dataSourceId=ALL_AGGR","DBS_Output"),
@(120400,"rest/dmiquery/getDMIData3?appId=SYSTEMDIAG&viewId=TableStorage&dimensionIds=['begT','dataProd','groupName']&metricIds=['dataB','unusedB','totalB','indexSizeB','cfgStoragePeriod','actualStoragePeriod','rowsCnt','tableCnt']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","DBS_Output"),

# TSK_Output 12.3 and 12.4+ versions
@(120300,"rest/dmiquery/getDMIData3?appId=SYSTEMDIAG&viewId=TaskSchedulerStatus&dimensionIds=['begT','dataProd','taskName']&metricIds=['avgExecT','minExecT','maxExecT','maxTaskT']&resolution=r&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=d&numberOfPeriods=1&dataSourceId=ALL_AGGR","TSK_Output"),
@(120400,"rest/dmiquery/getDMIData3?appId=SYSTEMDIAG&viewId=TaskSchedulerStatus&dimensionIds=['begT','dataProd','taskName']&metricIds=['avgExecT','minExecT','maxExecT','maxTaskT']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","TSK_Output"),

# AMD_GBL_Output 12.4+ only
@(120400,"rest/dmiquery/getDMIData3?appId=AMD&viewId=AMDGlobalStatistics&dimensionIds=['begT','dataProd','probe']&metricIds=['ip4tcp','ip4udp','ip4fragBytes','ip4dup','ip4frag','ip6tcp','ip6udp','ip6fragBytes','ip6dup','ip6frag','malformed','ip4all','ip6all','badChkSum','ip4dup_p','ip6dup_p']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","AMD_GBL_Output"),

# AMD_DRV_Output 12.4+ only
@(120400,"rest/dmiquery/getDMIData3?appId=AMD&viewId=AMDDriverStatistics&dimensionIds=['begT','dataProd','probe','drvMode']&metricIds=['sampling_r','dropped_r','non_IP','samplingBase','overrun','checksum','drvTooBig','dropped','sampling','drvOutLink','drvOutCfg','drvOutLb','decodables','non_IP_p','rcvd','samplingLevel']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","AMD_DRV_Output"),

# AMD CPU Output 12.3 and 12.4+ versions
@(120300,"rest/dmiquery/getDMIData3?appId=SYSTEMDIAG&viewId=ProbeCPUStatistics&dimensionIds=['begT','dataProd','probe','objectName']&metricIds=['hardirqA','idleA','iowaitA','niceA','softirqA','stealA','systemA','userA']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&top=0&timePeriod=d&numberOfPeriods=1&dataSourceId=ALL_AGGR","AMD_CPU_Output"),
@(120400,"rest/dmiquery/getDMIData3?appId=AMD&viewId=AMDCPUStatistics&dimensionIds=['begT','dataProd','probe','cpuNum']&metricIds=['hardirqA','idleA','iowaitA','niceA','softirqA','stealA','systemA','userA']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","AMD_CPU_Output"),

# AMD_DSK_Output 12.4+ only
@(120400,"rest/dmiquery/getDMIData3?appId=AMD&viewId=AMDDiskUsageStatistics&dimensionIds=['begT','dataProd','probe','hddMount']&metricIds=['usedBytes','bytes']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","AMD_DSK_Output"),

# AMD_SES_Output 12.4+ only
@(120400,"rest/dmiquery/getDMIData3?appId=AMD&viewId=AMDAnalyserStatistics&dimensionIds=['begT','dataProd','probe']&metricIds=['anlUnidirectional_r','anlClnSeqMissing_r','anlSrvSeqMissing_r','anlSessions','anlClnSeqGaps','anlSrvSeqGaps','anlUnidirectional','anlPktProcessed']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","AMD_SES_Output"),

# AMD_INT_Output 12.3 and 12.4+ versions
@(120300,"rest/dmiquery/getDMIData3?appId=SYSTEMDIAG&viewId=ProbeIfcStatistics&dimensionIds=['begT','dataProd','probe','ifcName','ifcType','ifcState']&metricIds=['ifcSpeed','rx_overruns','tx_overruns','rx_errors_r','rx_bytes','rx_errors','rx_packets','rx_dropped','tx_bytes','tx_errors','tx_packets','tx_dropped']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&top=0&timePeriod=d&numberOfPeriods=1&dataSourceId=ALL_AGGR","AMD_INT_Output"),
@(120400,"rest/dmiquery/getDMIData3?appId=AMD&viewId=AMDInterfacesStatistics&dimensionIds=['begT','dataProd','probe','ifcName','ifcType','ifcState','ifcSpeed']&metricIds=['rx_overruns','tx_overruns','rx_errors_r','rx_bytes','rx_errors','rx_packets','rx_dropped','tx_bytes','tx_errors','tx_packets','tx_dropped']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","AMD_INT_Output"),

# STS_Output
@(120300,"rest/dmiquery/getDMIData2?appId=SYSTEMDIAG&viewId=ModuleStatuses&dimensionIds=['dataProd','Status','module','Object','Information','type_32','type_2','type_128','type_4','type_1','type_64']&metricIds=['maxTaskT']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['undefined',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","STS_Output")
)
$num_queries = $querylist.count 



# run each query in turn
$total_queries = $num_cases * $num_queries
$j = 0
$i = 0
$q = 0
foreach ($cas in $cases)
{
    $j += 1
    $i = 0
    foreach ($query in $querylist) 
    {
        $i += 1
        $q += 1
        Write-Progress -Id 1 -Activity "Collecting data from CASes" -Status "Collecting from $cas $j of $num_cases" -PercentComplete (($q/$total_queries)*100)
        Write-Progress -Id 2 -Activity "Collecting from $cas" -Status ("Collecting dataset " + $query[2] + " $i of $num_queries") -PercentComplete (($i/$num_queries)*100)

        # check query version compatability
        if ($cas_version -ge $query[0]) {
            $uri = "${serveraddr}"+$query[1]
            $out = $cas+"_"+$query[2]+".json"
            #write-host "${uri},${out}"
            write-host "Running Query #${i}:" $query[2]
            Try
            {
                $jsonresult = (Invoke-WebRequest -Uri $uri -Headers $header -TimeoutSec $resttimeout -ErrorAction Stop).Content
            }
            Catch
            {
                $ErrorMessage = $_.Exception.Message
                write-host "Error running query" $query[2] "The error message was $ErrorMessage"
                Break
            }

            

            # output result to file (if not null)
            if ($jsonresult.Equals('{}')) {
                write-host "Query" $query[2] "returned null result."
            } else {
                $errstate = $jsonresult | ConvertFrom-Json | select -expand dmiServiceError
                if (!$errstate.error ) {
                    $jsonresult | Out-File $out
                    write-host "Query results written to $out."
                } else {
                    write-host "DMI Error in query $query[2]."
                }
            }


        } else {
            # CAS version below any available compatible query
            write-host "Skipping version incompatible query #${i}:" $query[2]
        }
    }
}



write-host "Done."
