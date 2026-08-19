$ck = 'ck_74739e5d026eb9c45628548c65dfa35a057cf0bb'
$cs = 'cs_41bccfc9f218445664eca0ba008294959f14af49'
$auth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ck}:${cs}"))

# Fetch orders and show ALL meta_data keys for orders that have IDs (Pinaka POS orders vs WC REST orders)
$orders = Invoke-RestMethod -Uri "https://merchantrestaurant.alektasolutions.com/wp-json/wc/v3/orders?per_page=20&orderby=date&order=desc" -Headers @{ Authorization = $auth }

Write-Host "`n=== Orders with IDs (Pinaka POS custom orders have ID, REST-created may not) ==="
$ordersWithId = $orders | Where-Object { $_.id -ne $null -and $_.id -ne '' }

# Show first 5 in detail
$ordersWithId | Select-Object -First 5 | ForEach-Object {
    Write-Host "`n--- Order ID: $($_.id) | Status: $($_.status) | created_via: $($_.created_via) ---"
    Write-Host "ALL META KEYS:"
    $_.meta_data | ForEach-Object { Write-Host "  [$($_.key)] = $($_.value)" }
}
