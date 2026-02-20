# Pode.Web Best Practice - Riferimento Rapido

Versione testata: **Pode 2.12.1 + Pode.Web 0.8.3**
Doc ufficiale: https://badgerati.github.io/Pode.Web/0.8.3/

---

## 1. New-PodeWebModal

**NON esiste** il parametro `-Title`. Il titolo si imposta con `-DisplayName`.

```powershell
# CORRETTO
New-PodeWebModal -Name 'NomeInterno' -DisplayName 'Titolo Visibile' -Icon 'eye' -Size Large -Content @(...)

# SBAGLIATO - causa 400
New-PodeWebModal -Name 'X' -Title 'Titolo' ...
```

**Parametri disponibili**: Name, DisplayName, Id, Content, Icon, SubmitText, CloseText, Size, ScriptBlock, ArgumentList, CssClass, CssStyle, EndpointName, Method, Action, AsForm, NoAuthentication

**Mostrare/nascondere**:
```powershell
Show-PodeWebModal -Name 'NomeModal'           # Con -Name
Show-PodeWebModal -Name 'NomeModal' -DataValue $val -Actions @(...)  # Con dati
Hide-PodeWebModal                              # Chiudi modal corrente (no parametri)
```

---

## 2. New-PodeWebSelect - Parameter Set MUTUALMENTE ESCLUSIVI

`-Options` e `-ScriptBlock` sono in **parameter set diversi**. NON si possono combinare.

| Parameter Set | Parametri chiave |
|--------------|-----------------|
| **Options** | -Options, -DisplayOptions, -SelectedValue |
| **ScriptBlock** | -ScriptBlock, -ArgumentList, -SelectedValue |

```powershell
# CORRETTO - opzioni statiche
New-PodeWebSelect -Name 'tipo' -Options @('a','b','c') -SelectedValue 'a'

# CORRETTO - opzioni dinamiche (caricate da ScriptBlock)
New-PodeWebSelect -Name 'tipo' -ScriptBlock { @('a','b','c') }

# SBAGLIATO - parameter set conflict, causa errore
New-PodeWebSelect -Name 'tipo' -Options @('a','b') -ScriptBlock { ... }
```

**Per gestire onChange**: usare `Register-PodeWebEvent -Type Change`:
```powershell
New-PodeWebSelect -Name 'tipo' -Options @('a','b','c') -SelectedValue 'a' |
    Register-PodeWebEvent -Type Change -ScriptBlock {
        $selected = $WebEvent.Data['tipo']
        # logica onChange...
    }
```

**Update da server** - `-Options` e **OBBLIGATORIO** anche per Update:
```powershell
# CORRETTO - deve ripetere le opzioni
Update-PodeWebSelect -Name 'tipo' -Options @('a','b','c') -SelectedValue 'b'

# SBAGLIATO - Options mancante, causa HANG (PS chiede input interattivo)
Update-PodeWebSelect -Name 'tipo' -SelectedValue 'b'
```

---

## 3. New-PodeWebCheckbox

Richiede **obbligatoriamente** `-Options` (array di stringhe label).

```powershell
# CORRETTO
New-PodeWebCheckbox -Name 'abilitato' -Options @('Abilitato') -Checked

# SBAGLIATO - -DisplayName NON e un parametro di Checkbox
New-PodeWebCheckbox -Name 'abilitato' -DisplayName 'Abilitato' -Checked
```

**Parametri**: Name, DisplayName, Id, Options, DisplayOptions, CssClass, CssStyle, Inline, AsSwitch, Checked, Disabled, NoForm, Required

**Il valore nel form** e il testo dell'opzione selezionata (es. `$WebEvent.Data['abilitato'] -eq 'Abilitato'`).

**Update** - `-Checked` e un **switch**, NON accetta valore booleano diretto:
```powershell
# CORRETTO - con colon syntax per passare valore bool a switch
Update-PodeWebCheckbox -Name 'abilitato' -Checked:$true
Update-PodeWebCheckbox -Name 'abilitato' -Checked:([bool]$val)

# SBAGLIATO - causa "parametro posizionale non trovato"
Update-PodeWebCheckbox -Name 'abilitato' -Checked $true
Update-PodeWebCheckbox -Name 'abilitato' -Checked ([bool]$val)
```

---

## 4. New-PodeWebButton

Il parametro `-ScriptBlock` e **obbligatorio** se non si usa `-Url`.

```powershell
# CORRETTO
New-PodeWebButton -Name 'Azione' -Icon 'plus' -Colour Green -ScriptBlock { ... }

# CORRETTO (link esterno)
New-PodeWebButton -Name 'Link' -Url '/pagina' -NewTab

# SBAGLIATO - manca ScriptBlock
New-PodeWebButton -Name 'Btn' -Icon 'x' -Colour Red -Size Small
```

**Size validi**: Normal, Small, Large

**NON** si possono creare Button con ScriptBlock **dentro** il ScriptBlock di una Table (gli endpoint vengono registrati una sola volta all'avvio, non dinamicamente).

---

## 5. New-PodeWebTable

```powershell
New-PodeWebTable -Name 'Lista' -SimpleFilter -SimpleSort -Compact -Click -DataColumn 'ID' `
    -ClickScriptBlock {
        $id = $WebEvent.Data['Value']   # Valore della DataColumn cliccata
        # logica click riga...
    } -ScriptBlock {
        # Restituisce righe (eseguito ad ogni refresh)
        [ordered]@{ ID = '1'; Nome = 'Test'; Stato = New-PodeWebBadge -Value 'OK' -Colour Green }
    }
```

**Refresh da server**: `Sync-PodeWebTable -Name 'Lista'`

**ATTENZIONE**: NON mettere `New-PodeWebButton -ScriptBlock {...}` nelle righe della tabella. I button con ScriptBlock registrano endpoint al build della pagina, NON a runtime.

---

## 6. Show/Hide Container

I comandi sono `Show-PodeWebComponent` / `Hide-PodeWebComponent` (NON `Show-PodeWebElement`).

```powershell
# Definizione con Hide iniziale
New-PodeWebContainer -Id 'mio-container' -Hide -Content @(...)

# Toggle visibilita
Show-PodeWebComponent -Id 'mio-container'
Hide-PodeWebComponent -Id 'mio-container'
```

**Parametri Show/Hide**: Id, Type, Name

---

## 7. Register-PodeWebEvent

Aggiunge handler eventi JavaScript ai componenti.

```powershell
$componente | Register-PodeWebEvent -Type Change -ScriptBlock { ... }
```

**Tipi evento**: Change, Focus, FocusOut, Click, MouseOver, MouseOut, KeyDown, KeyUp

---

## 8. New-PodeWebTextbox

```powershell
New-PodeWebTextbox -Name 'campo' -DisplayName 'Etichetta' -Value 'default' -Placeholder 'hint'
New-PodeWebTextbox -Name 'multi' -DisplayName 'Testo' -Multiline
New-PodeWebTextbox -Name 'num' -DisplayName 'Numero' -Type Number -Value '0'
New-PodeWebTextbox -Name 'ro' -DisplayName 'Sola lettura' -ReadOnly
```

**Tipi validi**: Text, Email, Password, Number, Date, Time, File, DateTime

**Update**: `Update-PodeWebTextbox -Name 'campo' -Value 'nuovo valore'`

---

## 9. Toast e Notifiche

```powershell
Show-PodeWebToast -Message 'Operazione completata' -Title 'Successo'
Show-PodeWebNotification -Title 'Alert' -Body 'Messaggio'
```

---

## 10. Pattern Pagina Standard

```powershell
Add-PodeWebPage -Name 'NomePagina' -Icon 'icona' -ScriptBlock {
    # 1. KPI Tiles
    New-PodeWebGrid -Cells @(
        New-PodeWebCell -Width 4 -Content @(
            New-PodeWebTile -Name 'KPI1' -Icon 'x' -Colour Blue -AutoRefresh -RefreshInterval 30 -ScriptBlock {
                [int](Invoke-SFERAScalar -Query "SELECT COUNT(*) FROM ...")
            }
        )
    )

    # 2. Pulsanti azione (fuori dalla tabella!)
    New-PodeWebButton -Name 'Nuovo' -Icon 'plus' -Colour Green -ScriptBlock {
        Show-PodeWebModal -Name 'ModalCrea'
    }

    # 3. Tabella con click handler
    New-PodeWebTable -Name 'Lista' -SimpleFilter -SimpleSort -Compact -Click -DataColumn 'ID' `
        -ClickScriptBlock { ... } -ScriptBlock { ... }

    # 4. Modali (definiti nella stessa pagina)
    New-PodeWebModal -Name 'ModalCrea' -DisplayName 'Titolo' -AsForm -Content @(...) -ScriptBlock { ... }
}
```

---

## 11. Errori Comuni e Soluzioni

| Errore | Causa | Soluzione |
|--------|-------|-----------|
| 400 Bad Request sulla pagina | Parametro inesistente in un componente | Verificare parametri con `Get-Command` |
| "Impossibile risolvere il set di parametri" | Parametri di set diversi combinati | Controllare ParameterSets del cmdlet |
| "Parametro -Title non trovato" | Modal non ha -Title | Usare -DisplayName |
| "-ScriptBlock obbligatorio" | Button senza ScriptBlock ne Url | Aggiungere -ScriptBlock o -Url |
| Show/Hide non funziona | Usato `*-Element` invece di `*-Component` | Usare Show/Hide-PodeWebComponent |
| Select onChange non funziona | -Options + -ScriptBlock insieme | Usare `Register-PodeWebEvent -Type Change` |
| Update-PodeWebSelect HANG | -Options mancante in Update | Passare SEMPRE -Options anche in Update |
| "parametro posizionale" su Checkbox | -Checked con valore bool | Usare `-Checked:$true` (colon syntax) |
| "NoNewline non trovato" (PS 5.1) | Out-String -NoNewline in Outputs.ps1 | Patch: `($items \| Out-String) -replace '(\r?\n)$',''` |
| 400 "matrice vuota" su Content | `New-PodeWebCell -Content @()` con array vuoto | Rimuovere la cella o mettere contenuto. `-Content` **NON** accetta `@()` vuoto |
