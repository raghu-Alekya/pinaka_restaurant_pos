$ck = 'ck_74739e5d026eb9c45628548c65dfa35a057cf0bb'
$cs = 'cs_41bccfc9f218445664eca0ba008294959f14af49'
$auth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ck}:${cs}"))

# Fetch specific known Dine-in order #16932 (the one user showed in screenshot)
Write-Host "=== Dine-in / Takeaway Order #16932 ==="
$o = Invoke-RestMethod -Uri "https://merchantrestaurant.alektasolutions.com/wp-json/wc/v3/orders/16932" -Headers @{ Authorization = $auth }
Write-Host "created_via: $($o.created_via)"
Write-Host "ALL META KEYS:"
$o.meta_data | ForEach-Object { Write-Host "  [$($_.key)] = $($_.value)" }

# Also fetch online order 17106 for comparison
Write-Host "`n=== Online Order #17106 (DD-PINAKA-201) ==="
$o2 = Invoke-RestMethod -Uri "https://merchantrestaurant.alektasolutions.com/wp-json/wc/v3/orders/17106" -Headers @{ Authorization = $auth }
Write-Host "created_via: $($o2.created_via)"
Write-Host "ALL META KEYS:"
$o2.meta_data | ForEach-Object { Write-Host "  [$($_.key)] = $($_.value)" }
