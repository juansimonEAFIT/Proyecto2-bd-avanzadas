param(
	[int]$DelayMs = 180,
	[int]$DurationSeconds = 90,
	[int]$Writes = 12
)

$ErrorActionPreference = "Stop"
$ResultsDir = Join-Path $PSScriptRoot "..\docs\results"
$ResultPath = Join-Path $ResultsDir "bonus_quorum_geodistribution.json"

function Invoke-CrdbSql {
	param(
		[Parameter(Mandatory = $true)][string]$Sql
	)

	docker exec -i cockroach-node1-latency ./cockroach sql --insecure --host=cockroach-node1-latency:26257 -e $Sql
}

function Wait-CrdbReady {
	param(
		[int]$Attempts = 20,
		[int]$DelaySeconds = 2
	)

	for ($i = 1; $i -le $Attempts; $i++) {
		$oldLoopErrorAction = $ErrorActionPreference
		$ErrorActionPreference = "Continue"
		docker exec -i cockroach-node1-latency ./cockroach sql --insecure --host=cockroach-node1-latency:26257 -e "SELECT 1;" > $null 2> $null
		$ErrorActionPreference = $oldLoopErrorAction
		if ($LASTEXITCODE -eq 0) {
			Write-Host "CockroachDB listo para SQL"
			return
		}

		Write-Host "Esperando disponibilidad SQL ($i/$Attempts)..."
		Start-Sleep -Seconds $DelaySeconds
	}

	throw "CockroachDB no quedo listo a tiempo"
}

Write-Host "[1/8] Levantando cluster de latencia"
docker compose -f infra/docker-compose.latency.yml up -d

Write-Host "[2/8] Inicializando cluster (si ya estaba inicializado, puede mostrar warning y continuar)"
$oldErrorAction = $ErrorActionPreference
$ErrorActionPreference = "Continue"
docker compose -f infra/docker-compose.latency.yml up cockroach-init-latency *> $null
$ErrorActionPreference = $oldErrorAction

Wait-CrdbReady

Write-Host "[3/8] Estado de nodos"
Invoke-CrdbSql "SET allow_unsafe_internals = true; SELECT node_id, locality, sql_address, is_live FROM crdb_internal.gossip_nodes ORDER BY node_id;"

Write-Host "[4/8] Aplicando script SQL de bonus"
Get-Content scripts/cockroachdb/04-bonus-quorum-geodistribution.sql -Raw |
docker exec -i cockroach-node1-latency ./cockroach sql --insecure --host=cockroach-node1-latency:26257

Write-Host "[5/8] Inyectando latencia de ${DelayMs}ms por ${DurationSeconds}s en nodos remotos"
docker pull gaiaadm/pumba:latest *> $null

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock gaiaadm/pumba:latest --log-level info netem --duration "${DurationSeconds}s" delay --time $DelayMs 're2:^cockroach-node(2|3)-latency$'

Write-Host "[6/8] Midiendo latencia de escrituras"
$timings = @()
for ($i = 1; $i -le $Writes; $i++) {
	$elapsed = (Measure-Command {
		Invoke-CrdbSql "INSERT INTO bonus_geo.geo_ping (writer_region, payload) VALUES ('us-east1', 'write-$i');"
	}).TotalMilliseconds

	$timings += [Math]::Round($elapsed, 2)
	Write-Host "  write-$i => ${elapsed}ms"
}

$avg = ($timings | Measure-Object -Average).Average
$min = ($timings | Measure-Object -Minimum).Minimum
$max = ($timings | Measure-Object -Maximum).Maximum

Write-Host "Resumen latencia -> avg: $([Math]::Round($avg,2))ms | min: ${min}ms | max: ${max}ms"

Write-Host "[7/8] Prueba de quorum: detener dos nodos y forzar escritura"
docker stop cockroach-node2-latency *> $null
docker stop cockroach-node3-latency *> $null

$quorumFailed = $false
try {
	Invoke-CrdbSql "INSERT INTO bonus_geo.geo_ping (writer_region, payload) VALUES ('quorum-test', 'should-fail');"
	if ($LASTEXITCODE -ne 0) {
		throw "quorum write failed"
	}
} catch {
	$quorumFailed = $true
	Write-Host "Resultado esperado: escritura rechazada por quorum insuficiente"
}

if (-not $quorumFailed) {
	Write-Host "Advertencia: la escritura no fallo. Revisa replicas/leaseholder del range probado."
}

Write-Host "[8/8] Restaurando nodos"
docker start cockroach-node2-latency *> $null
docker start cockroach-node3-latency *> $null
Wait-CrdbReady
Invoke-CrdbSql "SET allow_unsafe_internals = true; SELECT node_id, locality, sql_address, is_live FROM crdb_internal.gossip_nodes ORDER BY node_id;"

New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null
$payload = [ordered]@{
	executed_at_utc = (Get-Date).ToUniversalTime().ToString("o")
	delay_ms = $DelayMs
	duration_seconds = $DurationSeconds
	writes = $Writes
	latency_ms = [ordered]@{
		average = [Math]::Round($avg, 2)
		minimum = [Math]::Round($min, 2)
		maximum = [Math]::Round($max, 2)
		raw = $timings
	}
	quorum_write_rejected = $quorumFailed
}
$payload | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $ResultPath
Write-Host "[+] Resultado guardado en $ResultPath"

Write-Host "Bonus geodistribucion + latencia + quorum finalizado"
