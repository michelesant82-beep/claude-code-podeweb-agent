# test3_select_onchange.ps1
# Pattern: Select cascading con onChange + Modal form precompilato
# Pode 2.12.1 + Pode.Web 0.8.3 | PS 5.1 compatible

Import-Module Pode
Import-Module Pode.Web

# ---------------------------------------------------------------------------
# Dati simulati: mappa Reparto -> lista dipendenti
# Ogni dipendente: @{ Nome; Email }
# ---------------------------------------------------------------------------
$script:DipendentiDB = @{
    'IT' = @(
        @{ Nome = 'Luca Bianchi';   Email = 'l.bianchi@azienda.it' }
        @{ Nome = 'Sara Verdi';     Email = 's.verdi@azienda.it'   }
        @{ Nome = 'Marco Neri';     Email = 'm.neri@azienda.it'    }
    )
    'HR' = @(
        @{ Nome = 'Anna Russo';     Email = 'a.russo@azienda.it'   }
        @{ Nome = 'Paolo Esposito'; Email = 'p.esposito@azienda.it'}
    )
    'Finance' = @(
        @{ Nome = 'Giorgio Conti';  Email = 'g.conti@azienda.it'   }
        @{ Nome = 'Elena Marino';   Email = 'e.marino@azienda.it'  }
        @{ Nome = 'Fabio Gallo';    Email = 'f.gallo@azienda.it'   }
        @{ Nome = 'Rita Fiore';     Email = 'r.fiore@azienda.it'   }
    )
}

# Helper: restituisce i nomi (label) per la select Dipendente
function Get-NomiDipendenti {
    param([string]$Reparto)
    $lista = $script:DipendentiDB[$Reparto]
    if (-not $lista) { return @('-- nessun dipendente --') }
    return @($lista | ForEach-Object { $_.Nome })
}

# Helper: cerca un dipendente per nome (ricerca lineare nei reparti)
function Get-DipendentePerId {
    param([string]$Nome)
    foreach ($reparto in $script:DipendentiDB.Keys) {
        foreach ($dip in $script:DipendentiDB[$reparto]) {
            if ($dip.Nome -eq $Nome) { return $dip }
        }
    }
    return $null
}

# ---------------------------------------------------------------------------
# Server Pode
# ---------------------------------------------------------------------------
Start-PodeServer {

    Add-PodeEndpoint -Address localhost -Port 8085 -Protocol Http

    Use-PodeWebTemplates -Theme Dark

    # -----------------------------------------------------------------------
    # Pagina principale
    # -----------------------------------------------------------------------
    Add-PodeWebPage -Name 'Dipendenti' -Icon 'account-group' -HomePage -ScriptBlock {

        # --- Select Reparto (onChange aggiorna select Dipendente) ---
        # REGOLA: -Options e Register-PodeWebEvent sono compatibili.
        # NON usare -Options e -ScriptBlock insieme sullo stesso New-PodeWebSelect.
        New-PodeWebSelect -Name 'Reparto' -DisplayName 'Reparto' `
            -Options @('IT', 'HR', 'Finance') -SelectedValue 'IT' |
            Register-PodeWebEvent -Type Change -ScriptBlock {
                $repartoScelto = $WebEvent.Data['Reparto']

                # Calcola lista nomi per il reparto selezionato
                $nomi = Get-NomiDipendenti -Reparto $repartoScelto

                # CRITICO: Update-PodeWebSelect DEVE sempre avere -Options
                # (senza -Options PS entra in attesa di input interattivo → HANG)
                Update-PodeWebSelect -Name 'Dipendente' `
                    -Options $nomi `
                    -SelectedValue $nomi[0]
            }

        # --- Select Dipendente (popolata inizialmente con IT) ---
        $nomiIniziali = Get-NomiDipendenti -Reparto 'IT'
        New-PodeWebSelect -Name 'Dipendente' -DisplayName 'Dipendente' `
            -Options $nomiIniziali -SelectedValue $nomiIniziali[0]

        # --- Pulsante Dettaglio ---
        # Il pulsante legge il valore corrente della select Dipendente
        # e apre il modal con -DataValue = nome dipendente selezionato.
        # REGOLA: Button DEVE avere -ScriptBlock o -Url.
        # REGOLA: Button NON dentro ScriptBlock di Table (qui non c'e tabella, OK).
        New-PodeWebButton -Name 'Dettaglio' -DisplayName 'Dettaglio' `
            -Icon 'account-details' -Colour Blue -ScriptBlock {
                $nomeScelto = $WebEvent.Data['Dipendente']
                if ([string]::IsNullOrWhiteSpace($nomeScelto)) {
                    Show-PodeWebToast -Message 'Nessun dipendente selezionato.' -Title 'Attenzione'
                    return
                }
                Show-PodeWebModal -Name 'ModalDettaglio' -DataValue $nomeScelto
            }

        # --- Separatore visivo ---
        New-PodeWebText -Value ' ' | Out-Null   # spacer (noop, solo leggibilita)

        # -----------------------------------------------------------------------
        # Modal Dettaglio dipendente
        # -DisplayName  = titolo visibile (NON -Title che non esiste)
        # -AsForm       = abilita submit via pulsante Save
        # ScriptBlock   = eseguito al CARICAMENTO del modal (DataValue disponibile)
        #                 + al SUBMIT (quando -AsForm e presente)
        # Per distinguere load vs submit si usa $WebEvent.Data['Value'] (DataValue)
        # vs i campi form.
        # In questo pattern:
        #   - Load:   $WebEvent.Data['Value'] contiene il nome -> precompila campi
        #   - Submit: $WebEvent.Data['Note'] contiene le note salvate -> mostra toast
        # -----------------------------------------------------------------------
        New-PodeWebModal -Name 'ModalDettaglio' -DisplayName 'Dettaglio Dipendente' `
            -Icon 'account-details' -Size Large -AsForm `
            -Content @(
                New-PodeWebTextbox -Name 'det_Nome' -DisplayName 'Nome' -ReadOnly
                New-PodeWebTextbox -Name 'det_Email' -DisplayName 'Email' -ReadOnly
                New-PodeWebTextbox -Name 'det_Note' -DisplayName 'Note' -Multiline `
                    -Placeholder 'Inserisci note sul dipendente...'
            ) -ScriptBlock {
                $nome = $WebEvent.Data['Value']

                if (-not [string]::IsNullOrWhiteSpace($nome)) {
                    # --- LOAD del modal: precompila i campi readonly ---
                    $dip = Get-DipendentePerId -Nome $nome
                    if ($dip) {
                        Update-PodeWebTextbox -Name 'det_Nome'  -Value $dip.Nome
                        Update-PodeWebTextbox -Name 'det_Email' -Value $dip.Email
                        # Note: campo vuoto all'apertura (editabile dall'utente)
                        Update-PodeWebTextbox -Name 'det_Note'  -Value ''
                    } else {
                        Update-PodeWebTextbox -Name 'det_Nome'  -Value $nome
                        Update-PodeWebTextbox -Name 'det_Email' -Value '-- non trovato --'
                    }
                } else {
                    # --- SUBMIT del form: salva le note ---
                    $noteInserite = $WebEvent.Data['det_Note']
                    $nomeForm     = $WebEvent.Data['det_Nome']

                    # Qui potresti persistere le note su DB o file
                    # Per ora simuliamo un salvataggio con toast
                    $msg = if ([string]::IsNullOrWhiteSpace($noteInserite)) {
                        "Nessuna nota inserita per $nomeForm."
                    } else {
                        "Note salvate per $nomeForm."
                    }

                    Show-PodeWebToast -Message $msg -Title 'Salvataggio'
                    Hide-PodeWebModal
                }
            }
    }
}
