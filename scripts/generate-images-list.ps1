param(
    [string]$InputPath = (Join-Path $PSScriptRoot "..\images.md"),
    [string]$OutputPath = (Join-Path $PSScriptRoot "..\ImagesList.md"),
    [string]$Registry = "registry.cn-hangzhou.aliyuncs.com",
    [string]$Namespace = "zrng",
    [string]$Title = "Docker Images List"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-IsSectionHeading {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $trimmed = $Text.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        return $false
    }

    if ($trimmed -notmatch '^[A-Za-z0-9./ +_-]{1,40}$') {
        return $false
    }

    if ($trimmed.Contains("=") -or $trimmed.Contains(":") -or $trimmed.Contains("(")) {
        return $false
    }

    return $true
}

function Resolve-ImageEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Line
    )

    $cleanLine = ($Line -replace "\s+#.*$", "").Trim()
    if ([string]::IsNullOrWhiteSpace($cleanLine)) {
        return $null
    }

    $parts = @($cleanLine -split "\s+" | Where-Object { $_ })
    if ($parts.Count -lt 1) {
        return $null
    }

    $originImage = $parts[0]
    $newName = ""
    $platform = ""

    if ($parts.Count -eq 2) {
        if ($parts[1] -match "^\[(.+)\]$") {
            $platform = $parts[1]
        }
        else {
            $newName = $parts[1]
        }
    }
    elseif ($parts.Count -ge 3) {
        $newName = $parts[1]
        if ($parts[2] -match "^\[(.+)\]$") {
            $platform = $parts[2]
        }
    }

    if ($newName) {
        $finalName = $newName
    }
    else {
        $imageNameTag = ($originImage -split "/")[-1]
        $imageNameTag = ($imageNameTag -split "@")[0]
        $finalName = $imageNameTag.Replace("/", "")
    }

    $platformArch = ""
    if ($platform -match "^\[(.+)\]$") {
        $platformArch = $Matches[1]
        if ($platformArch -and $platformArch -notin @("amd64", "x86_64")) {
            $finalName = "$finalName-$platformArch"
        }
    }

    $repositoryName = ($finalName -split ":", 2)[0]
    $fullImage = "$Registry/$Namespace/$finalName"

    return [PSCustomObject]@{
        OriginImage = $originImage
        NewName = $newName
        Platform = $platformArch
        FinalName = $finalName
        RepositoryName = $repositoryName
        FullImage = $fullImage
    }
}

function Get-SectionTitleFromRepository {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepositoryName
    )

    $map = @{
        "alpine" = "Alpine"
        "nginx" = "Nginx"
        "node" = "Node"
        "python" = "Python"
        "dozzle" = "Dozzle"
        "postgres" = "PostgreSQL"
        "mssql" = "MSSQL"
        "mysql" = "MySQL"
        "redis" = "Redis"
        "elasticsearch" = "Elasticsearch"
        "clickhouse-server" = "ClickHouse"
        "etcd" = "Milvus"
        "milvus" = "Milvus"
        "qdrant" = "Qdrant"
        "masstransit-rabbitmq" = "RabbitMQ"
        "minio" = "MinIO"
        "ollama" = "LLM / AI"
        "maxkb" = "LLM / AI"
        "langgenius-dify-api" = "LLM / AI"
        "langgenius-dify-web" = "LLM / AI"
        "langgenius-dify-sandbox" = "LLM / AI"
        "langgenius-dify-plugin-daemon" = "LLM / AI"
        "semitechnologies-weaviate" = "LLM / AI"
        "ubuntu-squid" = "LLM / AI"
        "gitlab-ce" = "GitLab"
        "gitlab-runner" = "GitLab"
        "docker" = "Docker"
        "gogs" = "Gogs"
        "seq" = "Seq"
        "yapi" = "YAPI"
        "mdnice" = "Mdnice"
        "keycloak" = "Keycloak"
        "kibana" = "Kibana"
        "grafana" = "Grafana"
        "prometheus" = "Prometheus"
        "smalte" = "Smalte"
        "tinyurl" = "Apps"
        "ai-stream-viewer" = "Apps"
        "dotnetruntime" = ".NET Runtime"
        "dotnetaspnet" = ".NET ASP.NET"
        "dotnetsdk" = ".NET SDK"
    }

    if ($map.ContainsKey($RepositoryName)) {
        return $map[$RepositoryName]
    }

    if ($RepositoryName -match "^[a-z0-9][a-z0-9._/-]*$") {
        return (Get-Culture).TextInfo.ToTitleCase($RepositoryName.Replace("-", " "))
    }

    return $RepositoryName
}

function Get-SectionInfo {
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$CurrentSection,
        [Parameter(Mandatory = $true)]
        [string]$RepositoryName
    )

    $normalizedSection = if ($null -eq $CurrentSection) { "" } else { $CurrentSection.Trim() }

    if ($normalizedSection -ieq "dotnet") {
        $title = Get-SectionTitleFromRepository -RepositoryName $RepositoryName
        return [PSCustomObject]@{
            Key = $title.ToLowerInvariant()
            Title = $title
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($normalizedSection)) {
        $titleMap = @{
            "alpine" = "Alpine"
            "nginx" = "Nginx"
            "node" = "Node"
            "python" = "Python"
            "postgresql" = "PostgreSQL"
            "mssql" = "MSSQL"
            "mysql" = "MySQL"
            "redis" = "Redis"
            "elasticsearch" = "Elasticsearch"
            "clickhouse" = "ClickHouse"
            "milvus" = "Milvus"
            "qdrant" = "Qdrant"
            "rabbitmq" = "RabbitMQ"
            "minio" = "MinIO"
            "llm / ai" = "LLM / AI"
            "gitlab" = "GitLab"
            "docker" = "Docker"
            "gogs" = "Gogs"
            "seq" = "Seq"
            "yapi" = "YAPI"
            "mdnice" = "Mdnice"
            "keycloak" = "Keycloak"
            "kibana" = "Kibana"
            "grafana" = "Grafana"
            "prometheus" = "Prometheus"
            "smalte" = "Smalte"
            "apps" = "Apps"
        }

        $key = $normalizedSection.ToLowerInvariant()
        $title = if ($titleMap.ContainsKey($key)) {
            $titleMap[$key]
        }
        else {
            $normalizedSection
        }

        return [PSCustomObject]@{
            Key = $key
            Title = $title
        }
    }

    $fallbackTitle = Get-SectionTitleFromRepository -RepositoryName $RepositoryName
    return [PSCustomObject]@{
        Key = $fallbackTitle.ToLowerInvariant()
        Title = $fallbackTitle
    }
}

$resolvedInputPath = [System.IO.Path]::GetFullPath($InputPath)
$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)

if (-not (Test-Path -LiteralPath $resolvedInputPath)) {
    throw "Input file not found: $resolvedInputPath"
}

$sections = New-Object System.Collections.Generic.List[object]
$sectionLookup = @{}
$currentSection = $null

foreach ($line in [System.IO.File]::ReadAllLines($resolvedInputPath)) {
    $trimmedLine = $line.Trim()

    if ([string]::IsNullOrWhiteSpace($trimmedLine)) {
        continue
    }

    if ($trimmedLine.StartsWith("#")) {
        if ($trimmedLine.StartsWith("##")) {
            continue
        }

        $commentText = ($trimmedLine -replace "^#\s*", "").Trim()
        if (-not [string]::IsNullOrWhiteSpace($commentText) -and (Test-IsSectionHeading -Text $commentText)) {
            $currentSection = $commentText
        }

        continue
    }

    $entry = Resolve-ImageEntry -Line $trimmedLine
    if ($null -eq $entry) {
        continue
    }

    $sectionInfo = Get-SectionInfo -CurrentSection $currentSection -RepositoryName $entry.RepositoryName
    $sectionKey = $sectionInfo.Key

    if (-not $sectionLookup.ContainsKey($sectionKey)) {
        $section = [PSCustomObject]@{
            Key = $sectionKey
            Title = $sectionInfo.Title
            Commands = New-Object System.Collections.Generic.List[string]
            CommandSet = New-Object 'System.Collections.Generic.HashSet[string]'
        }
        $sectionLookup[$sectionKey] = $section
        $sections.Add($section) | Out-Null
    }

    $command = "docker pull $($entry.FullImage)"
    if ($sectionLookup[$sectionKey].CommandSet.Add($command)) {
        $sectionLookup[$sectionKey].Commands.Add($command) | Out-Null
    }
}

$builder = New-Object System.Text.StringBuilder
[void]$builder.AppendLine("# $Title")
[void]$builder.AppendLine()
[void]$builder.AppendLine(('Image prefix: `{0}/{1}`' -f $Registry, $Namespace))
[void]$builder.AppendLine()

for ($i = 0; $i -lt $sections.Count; $i++) {
    $section = $sections[$i]

    [void]$builder.AppendLine("---")
    [void]$builder.AppendLine()
    [void]$builder.AppendLine("## $($section.Title)")
    [void]$builder.AppendLine()
    [void]$builder.AppendLine('```bash')
    foreach ($command in $section.Commands) {
        [void]$builder.AppendLine($command)
    }
    [void]$builder.AppendLine('```')
    [void]$builder.AppendLine()
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$content = $builder.ToString().TrimEnd([Environment]::NewLine.ToCharArray()) + [Environment]::NewLine
[System.IO.File]::WriteAllText($resolvedOutputPath, $content, $utf8NoBom)

Write-Host "Generated $resolvedOutputPath from $resolvedInputPath"
