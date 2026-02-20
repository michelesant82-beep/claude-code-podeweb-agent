# Debug: Parameter Set Conflict su New-PodeWebSelect

## Errore

```
Parameter set cannot be resolved using the specified named parameters.
One or more parameters issued cannot be used together or an insufficient number of parameters were provided.
```

## Codice Problematico

```powershell
New-PodeWebSelect -Name 'categoria' -Options @('A','B','C') -ScriptBlock {
    $sel = $WebEvent.Data['categoria']
    Sync-PodeWebTable -Name 'TabProdotti'
}
```

---

## Analisi della Causa

`New-PodeWebSelect` in Pode.Web 0.8.3 espone **due parameter set mutualmente esclusivi**:

| Parameter Set | Parametri | Scopo |
|---------------|-----------|-------|
| `Static`      | `-Options @(...)` | Opzioni definite a compile-time, lista fissa |
| `Dynamic`     | `-ScriptBlock { ... }` | Opzioni calcolate a runtime da un blocco script |

Combinare `-Options` e `-ScriptBlock` nello stesso cmdlet causa il conflitto perche PowerShell non riesce a determinare quale dei due parameter set usare.

**Il problema concettuale**: lo `-ScriptBlock` in `New-PodeWebSelect` serve per **generare la lista di opzioni dinamicamente** (es. leggendole da un DB), NON per reagire al cambio di selezione. L'utente ha confuso i due scopi:

- `-ScriptBlock` su `New-PodeWebSelect` = "come calcolo le opzioni?"
- `Register-PodeWebEvent -Type Change` = "cosa faccio quando l'utente cambia selezione?"

---

## Fix Corretto

### Caso 1: Opzioni statiche + reazione onChange

Usare `-Options` per le opzioni e `Register-PodeWebEvent` per la reazione al cambiamento.

```powershell
New-PodeWebSelect -Name 'categoria' -Options @('A','B','C') -SelectedValue 'A' |
    Register-PodeWebEvent -Type Change -ScriptBlock {
        $sel = $WebEvent.Data['categoria']
        Sync-PodeWebTable -Name 'TabProdotti'
    }
```

### Caso 2: Opzioni dinamiche (da DB) + reazione onChange

Usare `-ScriptBlock` per generare le opzioni, poi `Register-PodeWebEvent` per la reazione.

```powershell
New-PodeWebSelect -Name 'categoria' -ScriptBlock {
    # Questo blocco DEVE restituire l'array di opzioni
    @('A', 'B', 'C')  # oppure: Invoke-SqlQuery -Query "SELECT Nome FROM Categorie"
} | Register-PodeWebEvent -Type Change -ScriptBlock {
    $sel = $WebEvent.Data['categoria']
    Sync-PodeWebTable -Name 'TabProdotti'
}
```

---

## Regola Mnemonica

```
New-PodeWebSelect -Options  → lista statica, nota a compile-time
New-PodeWebSelect -ScriptBlock → lista dinamica, calcolata a runtime
Register-PodeWebEvent -Type Change → azione su cambio selezione (sempre separata)

MAI combinare -Options e -ScriptBlock nello stesso New-PodeWebSelect!
```

---

## Attenzione: Update-PodeWebSelect

Se successivamente si vuole aggiornare la select via script, ricordare che `Update-PodeWebSelect` richiede **obbligatoriamente** `-Options`. Ometterlo causa un HANG perche PS 5.1 rimane in attesa di input interattivo.

```powershell
# SBAGLIATO - HANG in PS 5.1
Update-PodeWebSelect -Name 'categoria' -SelectedValue 'B'

# CORRETTO - sempre passare -Options anche in Update
Update-PodeWebSelect -Name 'categoria' -Options @('A','B','C') -SelectedValue 'B'
```

---

*Fonte: Pode.Web 0.8.3 | Data: 2026-02-19*
