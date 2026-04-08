# BONUS: Quorum + Geodistribucion en CockroachDB
# Ejecutar desde raiz del proyecto en PowerShell

Write-Host "Levantando cluster de latencia para bonus..."
docker compose -f infra/docker-compose.latency.yml up -d

Write-Host "Mostrando estado de nodos..."
docker exec -it cockroach-node1-latency ./cockroach node status --insecure --host=10.0.0.2:26357

Write-Host "Deteniendo dos nodos para forzar falta de quorum..."
docker stop cockroach-node2-latency
$LASTEXITCODE | Out-Null
docker stop cockroach-node3-latency
$LASTEXITCODE | Out-Null

Write-Host "Intentando escritura con quorum insuficiente (esperado: fallo o timeout)..."
docker exec -it cockroach-node1-latency ./cockroach sql --insecure --host=10.0.0.2:26357 -e "CREATE DATABASE IF NOT EXISTS bonus_test;"

Write-Host "Restaurando nodos..."
docker start cockroach-node2-latency
$LASTEXITCODE | Out-Null
docker start cockroach-node3-latency
$LASTEXITCODE | Out-Null

Write-Host "Bonus quorum/geodistribucion finalizado"
