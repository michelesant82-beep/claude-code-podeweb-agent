# Gestione Server - Pagina Pode.Web
# Stack: Pode 2.12.1 + Pode.Web 0.8.3 | PS 5.1 compatible
#
# Dati in memoria (mock) - in produzione sostituire con query DB
$script:ServerList = @(
    [ordered]@{ ID = 1; Hostname = 'web-srv-01'; IP = '10.0.0.1';  Tipo = 'Web'; Monitorato = $true;  Stato = 'Online';  UltimoCheck = '2026-02-19 08:00' }
    [ordered]@{ ID = 2; Hostname = 'db-srv-01';  IP = '10.0.0.2';  Tipo = 'DB';  Monitorato = $true;  Stato = 'Online';  UltimoCheck = '2026-02-19 08:01' }
    [ordered]@{ ID = 3; Hostname = 'app-srv-01'; IP = '10.0.0.3';  Tipo = 'App'; Monitorato = $false; Stato = 'Offline'; UltimoCheck = '2026-02-19 07:55' }
    [ordered]@{ ID = 4; Hostname = 'web-srv-02'; IP = '10.0.0.4';  Tipo = 'Web'; Monitorato = $true;  Stato = 'Online';  UltimoCheck = '2026-02-19 08:02' }
    [ordered]@{ ID = 5; Hostname = 'app-srv-02'; IP = '10.0.0.5';  Tipo = 'App'; Monitorato = $true;  Stato = 'Offline'; UltimoCheck = '2026-02-19 07:50' }
)

Start-PodeServer {

    Add-PodeEndpoint -Address '*' -Port 8080 -Protocol Http

    Import-PodeWebTemplates -Theme Dark

    Add-PodeWebPage -Name 'Gestione Server' -Icon 'server' -ScriptBlock {

        # ------------------------------------------------------------------
        # 1. KPI TILES
        # ------------------------------------------------------------------
        New-PodeWebGrid -Cells @(

            New-PodeWebCell -Width 4 -Content @(
                New-PodeWebTile -Name 'KPI_Totale' -DisplayName 'Totale Server' `
                    -Icon 'server' -Colour Blue `
                    -AutoRefresh -RefreshInterval 30 `
                    -ScriptBlock {
                        $script:ServerList.Count
                    }
            )

            New-PodeWebCell -Width 4 -Content @(
                New-PodeWebTile -Name 'KPI_Online' -DisplayName 'Server Online' `
                    -Icon 'check-circle' -Colour Green `
                    -AutoRefresh -RefreshInterval 30 `
                    -ScriptBlock {
                        @($script:ServerList | Where-Object { $_.Stato -eq 'Online' }).Count
                    }
            )

            New-PodeWebCell -Width 4 -Content @(
                New-PodeWebTile -Name 'KPI_Offline' -DisplayName 'Server Offline' `
                    -Icon 'alert-circle' -Colour Red `
                    -AutoRefresh -RefreshInterval 30 `
                    -ScriptBlock {
                        @($script:ServerList | Where-Object { $_.Stato -eq 'Offline' }).Count
                    }
            )
        )

        # ------------------------------------------------------------------
        # 2. PULSANTE AGGIUNGI SERVER (FUORI dalla tabella)
        # ------------------------------------------------------------------
        New-PodeWebButton -Name 'AggiungiServer' -DisplayName 'Aggiungi Server' `
            -Icon 'plus' -Colour Green `
            -ScriptBlock {
                Show-PodeWebModal -Name 'ModalAggiungi'
            }

        New-PodeWebButton -Name 'RefreshTabella' -DisplayName 'Aggiorna' `
            -Icon 'refresh' -Colour Blue `
            -ScriptBlock {
                Sync-PodeWebTable -Name 'TabellaServer'
            }

        # ------------------------------------------------------------------
        # 3. TABELLA SERVER con filtro, ordinamento e click su riga
        # ------------------------------------------------------------------
        New-PodeWebTable -Name 'TabellaServer' -DisplayName 'Elenco Server' `
            -SimpleFilter -SimpleSort -Compact `
            -Click -DataColumn 'ID' `
            -ClickScriptBlock {
                $serverId = [int]$WebEvent.Data['Value']
                Show-PodeWebModal -Name 'ModalDettaglio' -DataValue $serverId
            } `
            -ScriptBlock {
                foreach ($srv in $script:ServerList) {

                    # Badge colorato per Stato
                    if ($srv.Stato -eq 'Online') {
                        $statoBadge = New-PodeWebBadge -Value 'Online' -Colour Green
                    } else {
                        $statoBadge = New-PodeWebBadge -Value 'Offline' -Colour Red
                    }

                    [ordered]@{
                        ID          = $srv.ID
                        Hostname    = $srv.Hostname
                        IP          = $srv.IP
                        Stato       = $statoBadge
                        'Ultimo Check' = $srv.UltimoCheck
                    }
                }
            }

        # ------------------------------------------------------------------
        # 4. MODAL FORM - Aggiungi Server
        # ------------------------------------------------------------------
        New-PodeWebModal -Name 'ModalAggiungi' -DisplayName 'Aggiungi Nuovo Server' `
            -Icon 'plus' -Size Large -AsForm `
            -Content @(
                New-PodeWebGrid -Cells @(
                    New-PodeWebCell -Width 6 -Content @(
                        New-PodeWebTextbox -Name 'add_hostname' -DisplayName 'Hostname' `
                            -Placeholder 'es. web-srv-03' -Required
                    )
                    New-PodeWebCell -Width 6 -Content @(
                        New-PodeWebTextbox -Name 'add_ip' -DisplayName 'Indirizzo IP' `
                            -Placeholder 'es. 10.0.0.10' -Required
                    )
                )
                New-PodeWebGrid -Cells @(
                    New-PodeWebCell -Width 6 -Content @(
                        New-PodeWebSelect -Name 'add_tipo' -DisplayName 'Tipo Server' `
                            -Options @('Web', 'DB', 'App') -SelectedValue 'Web'
                    )
                    New-PodeWebCell -Width 6 -Content @(
                        New-PodeWebCheckbox -Name 'add_monitorato' `
                            -Options @('Monitorato') -Checked
                    )
                )
            ) `
            -ScriptBlock {
                $hostname    = $WebEvent.Data['add_hostname']
                $ip          = $WebEvent.Data['add_ip']
                $tipo        = $WebEvent.Data['add_tipo']
                $monitorato  = $WebEvent.Data['add_monitorato'] -eq 'Monitorato'

                # Validazione base
                if ([string]::IsNullOrWhiteSpace($hostname)) {
                    Show-PodeWebToast -Message 'Hostname obbligatorio.' -Title 'Errore' -Duration 4000
                    return
                }
                if ([string]::IsNullOrWhiteSpace($ip)) {
                    Show-PodeWebToast -Message 'Indirizzo IP obbligatorio.' -Title 'Errore' -Duration 4000
                    return
                }

                # Aggiunta alla lista (in produzione: INSERT su DB)
                $nuovoId = ($script:ServerList | Measure-Object -Property ID -Maximum).Maximum + 1
                $script:ServerList += [ordered]@{
                    ID          = $nuovoId
                    Hostname    = $hostname
                    IP          = $ip
                    Tipo        = $tipo
                    Monitorato  = $monitorato
                    Stato       = 'Offline'
                    UltimoCheck = (Get-Date -Format 'yyyy-MM-dd HH:mm')
                }

                Show-PodeWebToast -Message "Server '$hostname' aggiunto con ID $nuovoId." -Title 'Successo'
                Sync-PodeWebTable -Name 'TabellaServer'
                Hide-PodeWebModal
            }

        # ------------------------------------------------------------------
        # 5. MODAL DETTAGLIO - Click su riga tabella
        # ------------------------------------------------------------------
        New-PodeWebModal -Name 'ModalDettaglio' -DisplayName 'Dettaglio Server' `
            -Icon 'server' -Size Large `
            -Content @(
                New-PodeWebGrid -Cells @(
                    New-PodeWebCell -Width 6 -Content @(
                        New-PodeWebTextbox -Name 'det_hostname' -DisplayName 'Hostname' -ReadOnly
                    )
                    New-PodeWebCell -Width 6 -Content @(
                        New-PodeWebTextbox -Name 'det_ip' -DisplayName 'Indirizzo IP' -ReadOnly
                    )
                )
                New-PodeWebGrid -Cells @(
                    New-PodeWebCell -Width 4 -Content @(
                        New-PodeWebTextbox -Name 'det_tipo' -DisplayName 'Tipo' -ReadOnly
                    )
                    New-PodeWebCell -Width 4 -Content @(
                        New-PodeWebTextbox -Name 'det_stato' -DisplayName 'Stato' -ReadOnly
                    )
                    New-PodeWebCell -Width 4 -Content @(
                        New-PodeWebTextbox -Name 'det_ultimocheck' -DisplayName 'Ultimo Check' -ReadOnly
                    )
                )
                New-PodeWebGrid -Cells @(
                    New-PodeWebCell -Width 6 -Content @(
                        New-PodeWebTextbox -Name 'det_monitorato' -DisplayName 'Monitorato' -ReadOnly
                    )
                )
            ) `
            -ScriptBlock {
                $serverId = [int]$WebEvent.Data['Value']

                # Ricerca server nella lista (in produzione: SELECT su DB)
                $srv = $script:ServerList | Where-Object { $_.ID -eq $serverId } | Select-Object -First 1

                if ($null -eq $srv) {
                    Show-PodeWebToast -Message "Server con ID $serverId non trovato." -Title 'Errore' -Duration 4000
                    Hide-PodeWebModal
                    return
                }

                if ($srv.Monitorato) {
                    $monitoratoTesto = 'Si'
                } else {
                    $monitoratoTesto = 'No'
                }

                Update-PodeWebTextbox -Name 'det_hostname'    -Value $srv.Hostname
                Update-PodeWebTextbox -Name 'det_ip'          -Value $srv.IP
                Update-PodeWebTextbox -Name 'det_tipo'        -Value $srv.Tipo
                Update-PodeWebTextbox -Name 'det_stato'       -Value $srv.Stato
                Update-PodeWebTextbox -Name 'det_ultimocheck' -Value $srv.UltimoCheck
                Update-PodeWebTextbox -Name 'det_monitorato'  -Value $monitoratoTesto
            }

    } # fine Add-PodeWebPage

} # fine Start-PodeServer
