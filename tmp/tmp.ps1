$AZ_BACKEND_POOLS_APP_GATEWAY | ForEach {

    $TMP = $_
  
    $POOL_NAME = $TMP.BackendAddressPool.Id | split-path -leaf
    $SERVERS = $TMP.BackendHttpSettingsCollection.Servers | Select-Object Address,Health
  
    # find backend pool names
  
    echo $SERVERS
    echo $POOL_NAME
    echo $HTTP_SETTINGS_NAME
  
    $SERVERS_UNHEALTHY=($SERVERS | Where-Object {$_.Health -eq "Unhealthy"}).Address
    $SERVERS_HEALTHY=($SERVERS | Where-Object {$_.Health -eq "Healthy"}).Address
  
    echo ">>> SERVERS UNH"
    $SERVERS_UNHEALTHY
  
    echo ">>> SERVERS H"
  
    ##############################################################################
    #### Zero servers unhealthy - Abort
    ##############################################################################
    if (-Not $SERVERS_UNHEALTHY ) {
      echo ">>> App GW backend pool servers are healthy."
      echo ">>> Abort."
  
      $SERVERS=(Get-AzApplicationGatewayBackendAddressPool `
      -Name $POOL_NAME `
      -ApplicationGateway $AZ_APP_GATEWAY)
  
      $SERVERS | ConvertTo-Json -Depth 100
  
    ##############################################################################
    #### All servers unhealthy - remove from backend pool
    ##############################################################################
    } elseif (-Not $SERVERS_HEALTHY ) {
      echo ">>> All of app GW backend pool servers are unhealthy. Set backend pool $POOL_NAME servers list to empty."
      $AZ_APP_GATEWAY =(Set-AzApplicationGatewayBackendAddressPool `
      -Name $POOL_NAME `
      -ApplicationGateway $AZ_APP_GATEWAY)
  
      $AZ_APP_GATEWAY =(Set-AzApplicationGateway `
      -ApplicationGateway $AZ_APP_GATEWAY)
  
      $EMPTY_SERVERS=(Get-AzApplicationGatewayBackendAddressPool `
      -Name $POOL_NAME `
      -ApplicationGateway $AZ_APP_GATEWAY)
  
      $EMPTY_SERVERS | ConvertTo-Json -Depth 100
    
    ##############################################################################
    #### Some servers unhealthy - remove some from backend pool
    ##############################################################################
    } else {
      echo ">>> Unhealthy APP GW backend pool servers detected: $SERVERS_UNHEALTHY "
  
      echo ">>> New backend pool servers will be: $SERVERS_HEALTHY"
  
      $AZ_APP_GATEWAY=(Set-AzApplicationGatewayBackendAddressPool `
      -Name $POOL_NAME `
      -ApplicationGateway $AZ_APP_GATEWAY `
      -BackendIPAddresses $SERVERS_HEALTHY)
  
      $AZ_APP_GATEWAY =(Set-AzApplicationGateway `
      -ApplicationGateway $AZ_APP_GATEWAY)
  
      $UPDATED_SERVERS=(Get-AzApplicationGatewayBackendAddressPool `
      -Name $POOL_NAME `
      -ApplicationGateway $AZ_APP_GATEWAY)
  
      $UPDATED_SERVERS | ConvertTo-Json -Depth 100
  
      echo ">>> New backend pool servers updated to: ${UPDATED_SERVERS} == ${SERVERS_HEALTHY}"
    }
  
  }
  
  