# Command line DCRUM Health Check data collection tool
# Chris Vidler - Dynatrace DCRUM SME 2017

# configuration
$serveraddr = "http://192.168.93.189/"
$username = "adminuser"
$password = "Password1"

# 0 = 12.3.x
# 1 = 12.4.x
# 2 = 2017.x
$cas_version = 0


# --- code follows ---

# build authentication string
$header = "${username}:${password}"
#write-host $header
$bytes = [System.Text.Encoding]::ASCII.GetBytes($header)
$base64 = [System.Convert]::ToBase64String($bytes)
$basic = "Basic $base64"
#write-host $basic
$header = @{ "Authorization" = "$basic" }

# array of REST queries and output file names to run
# version compatability, "REST query string", "query name"
$querylist = @(
# MEM_Output
@(0,"rest/dmiquery/getDMIData2?appId=SYSTEMDIAG&viewId=MemoryStatus&dimensionIds=['begT','dataProd']&metricIds=['cRestart','avgUsedM','procMemResident','procMemUsage','xmxMem','totalMem']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","MEM_Output"),

# PRC_Output
@(0,"rest/dmiquery/getDMIData3?appId=SYSTEMDIAG&viewId=ProcStatus&dimensionIds=['begT','dataProd']&metricIds=['procTime','avgProcTime','maxProcTime','avgDowTime','maxDowTime','partProcTimeT1','partCpuUsageT1','cpuTime','cpuUsage','cntCPUs','procLin','avgDelay']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","PRC_Output"),

# SES_Output
@(0,"rest/dmiquery/getDMIData3?appId=SYSTEMDIAG&viewId=MemoryStatus&dimensionIds=['begT','dataProd']&metricIds=['maxSessions','maxRawSessions','maxAggrSessions','sessThreshold','sessAlert']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","SES_Output"),

# DSK_Output 12.4+ only
@(1,"rest/dmiquery/getDMIData3?appId=SYSTEMDIAG&viewId=DiskUsage&dimensionIds=['begT','dataProd','disk']&metricIds=['usedBytes','freeBytes','bytes']&resolution=1&dimFilters=[]&metricFilters=[['bytes','>',0,1]]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","DSK_Output"),

# DBS_Output 12.3 and 12.4+ versions
@(0,"rest/dmiquery/getDMIData3?appId=HM&viewId=DbStatus&dimensionIds=['begT','dataProd','tableGrp']&metricIds=['avgData','avgUnused','avgSize','avgIndex','maxStoredInterval','avgStoredInterval','avgRows','avgTablesCount']&resolution=r&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&top=0&timePeriod=d&numberOfPeriods=1&dataSourceId=ALL_AGGR","DBS_Output"),
@(1,"rest/dmiquery/getDMIData3?appId=SYSTEMDIAG&viewId=TableStorage&dimensionIds=['begT','dataProd','groupName']&metricIds=['dataB','unusedB','totalB','indexSizeB','cfgStoragePeriod','actualStoragePeriod','rowsCnt','tableCnt']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","DBS_Output"),

# TSK_Output 12.3 and 12.4+ versions
@(0,"rest/dmiquery/getDMIData3?appId=SYSTEMDIAG&viewId=TaskSchedulerStatus&dimensionIds=['begT','dataProd','taskName']&metricIds=['avgExecT','minExecT','maxExecT','maxTaskT']&resolution=r&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=d&numberOfPeriods=1&dataSourceId=ALL_AGGR","TSK_Output"),
@(1,"rest/dmiquery/getDMIData3?appId=SYSTEMDIAG&viewId=TaskSchedulerStatus&dimensionIds=['begT','dataProd','taskName']&metricIds=['avgExecT','minExecT','maxExecT','maxTaskT']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","TSK_Output"),

# AMD_GBL_Output 12.4+ only
@(1,"rest/dmiquery/getDMIData3?appId=AMD&viewId=AMDGlobalStatistics&dimensionIds=['begT','dataProd','probe']&metricIds=['ip4tcp','ip4udp','ip4fragBytes','ip4dup','ip4frag','ip6tcp','ip6udp','ip6fragBytes','ip6dup','ip6frag','malformed','ip4all','ip6all','badChkSum','ip4dup_p','ip6dup_p']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","AMD_GBL_Output"),

# AMD_DRV_Output 12.4+ only
@(1,"rest/dmiquery/getDMIData3?appId=AMD&viewId=AMDDriverStatistics&dimensionIds=['begT','dataProd','probe','drvMode']&metricIds=['sampling_r','dropped_r','non_IP','samplingBase','overrun','checksum','drvTooBig','dropped','sampling','drvOutLink','drvOutCfg','drvOutLb','decodables','non_IP_p','rcvd','samplingLevel']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","AMD_DRV_Output"),

# AMD CPU Output 12.3 and 12.4+ versions
@(0,"rest/dmiquery/getDMIData3?appId=SYSTEMDIAG&viewId=ProbeCPUStatistics&dimensionIds=['begT','dataProd','probe','objectName']&metricIds=['hardirqA','idleA','iowaitA','niceA','softirqA','stealA','systemA','userA']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&top=0&timePeriod=d&numberOfPeriods=1&dataSourceId=ALL_AGGR","AMD_CPU_Output"),
@(1,"rest/dmiquery/getDMIData3?appId=AMD&viewId=AMDCPUStatistics&dimensionIds=['begT','dataProd','probe','cpuNum']&metricIds=['hardirqA','idleA','iowaitA','niceA','softirqA','stealA','systemA','userA']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","AMD_CPU_Output"),

# AMD_DSK_Output 12.4+ only
@(1,"rest/dmiquery/getDMIData3?appId=AMD&viewId=AMDDiskUsageStatistics&dimensionIds=['begT','dataProd','probe','hddMount']&metricIds=['usedBytes','bytes']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","AMD_DSK_Output"),

# AMD_SES_Output 12.4+ only
@(1,"rest/dmiquery/getDMIData3?appId=AMD&viewId=AMDAnalyserStatistics&dimensionIds=['begT','dataProd','probe']&metricIds=['anlUnidirectional_r','anlClnSeqMissing_r','anlSrvSeqMissing_r','anlSessions','anlClnSeqGaps','anlSrvSeqGaps','anlUnidirectional','anlPktProcessed']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","AMD_SES_Output"),

# AMD_INT_Output 12.3 and 12.4+ versions
@(0,"rest/dmiquery/getDMIData3?appId=SYSTEMDIAG&viewId=ProbeIfcStatistics&dimensionIds=['begT','dataProd','probe','ifcName','ifcType','ifcState']&metricIds=['ifcSpeed','rx_overruns','tx_overruns','rx_errors_r','rx_bytes','rx_errors','rx_packets','rx_dropped','tx_bytes','tx_errors','tx_packets','tx_dropped']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&top=0&timePeriod=d&numberOfPeriods=1&dataSourceId=ALL_AGGR","AMD_INT_Output"),
@(1,"rest/dmiquery/getDMIData3?appId=AMD&viewId=AMDInterfacesStatistics&dimensionIds=['begT','dataProd','probe','ifcName','ifcType','ifcState','ifcSpeed']&metricIds=['rx_overruns','tx_overruns','rx_errors_r','rx_bytes','rx_errors','rx_packets','rx_dropped','tx_bytes','tx_errors','tx_packets','tx_dropped']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['begT',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","AMD_INT_Output"),

# STS_Output
@(0,"rest/dmiquery/getDMIData2?appId=SYSTEMDIAG&viewId=ModuleStatuses&dimensionIds=['dataProd','Status','module','Object','Information','type_32','type_2','type_128','type_4','type_1','type_64']&metricIds=['maxTaskT']&resolution=1&dimFilters=[]&metricFilters=[]&sort=[['undefined',DESC]]&topFilter=0&timePeriod=30D&numberOfPeriods=1&dataSourceId=ALL_AGGR","STS_Output")
)

# run each query in turn
$i = 0
foreach ($query in $querylist) 
{
    $i += 1
    # check query version compatability
    if ($cas_version -ge $query[0]) {
        $uri = "${serveraddr}"+$query[1]
        $out = $query[2]+".json"
        #write-host "${uri},${out}"
        write-host "Running Query #${i}:" $query[2]
        Invoke-WebRequest -Uri $uri -OutFile $out -Headers $header -TimeoutSec 900
    } else {
        write-host "Skipping version incompatible query #${i}:" $query[2]
    }
}

