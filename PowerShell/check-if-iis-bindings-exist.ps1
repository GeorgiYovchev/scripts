$siteName = "prod-pronet"

# All host headers you want to check
$domains = @(
"ultraplay.goldenbahis820.com",
"ultraplay.goldenbahis821.com",
"ultraplay.goldenbahis822.com",
"ultraplay.goldenbahis823.com",
"ultraplay.goldenbahis824.com",
"ultraplay.goldenbahis825.com",
"ultraplay.goldenbahis826.com",
"ultraplay.goldenbahis827.com",
"ultraplay.goldenbahis828.com",
"ultraplay.goldenbahis829.com",
"ultraplay.690truvabet.com",
"ultraplay.691truvabet.com",
"ultraplay.692truvabet.com",
"ultraplay.693truvabet.com",
"ultraplay.694truvabet.com",
"ultraplay.695truvabet.com",
"ultraplay.696truvabet.com",
"ultraplay.697truvabet.com",
"ultraplay.698truvabet.com",
"ultraplay.699truvabet.com",
"ultraplay.700truvabet.com",
"ultraplay.701truvabet.com",
"ultraplay.702truvabet.com",
"ultraplay.703truvabet.com",
"ultraplay.704truvabet.com",
"ultraplay.705truvabet.com",
"ultraplay.706truvabet.com",
"ultraplay.707truvabet.com",
"ultraplay.708truvabet.com",
"ultraplay.281golegol.com",
"ultraplay.282golegol.com",
"ultraplay.283golegol.com",
"ultraplay.284golegol.com",
"ultraplay.285golegol.com",
"ultraplay.286golegol.com",
"ultraplay.287golegol.com",
"ultraplay.288golegol.com",
"ultraplay.289golegol.com",
"ultraplay.290golegol.com"
)

# Get existing bindings for the site
$bindings = Get-WebBinding -Name $siteName | Where-Object { $_.protocol -eq "http" -and $_.bindingInformation -like "*:80:*" }

# Extract host headers from the bindings
$existingHosts = $bindings.bindingInformation.Split(":") | Where-Object {$_ -match "\."}

# Compare
foreach ($domain in $domains) {
    if ($existingHosts -contains $domain) {
        Write-Host "$domain ✅ Already bound"
    }
    else {
        Write-Host "$domain ❌ Missing" -ForegroundColor Red
    }
}
