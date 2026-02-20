# PS 5.1 Gotcha: `$_` Contamination in Switch Blocks

## Il Bug

```powershell
$azione = $WebEvent.Data['azione']
switch ($azione) {
    'cleanup' {
        $raw = "D:\Backup\Server1`nE:\Backup\Server2`nF:\Backup\Server3"
        $paths = @(($raw -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        # $paths[0] e' "cleanup" invece di "D:\Backup\Server1"!
    }
}
```

**Risultato errato:**
```
$paths[0] = "cleanup"
$paths[1] = "E:\Backup\Server2"
$paths[2] = "F:\Backup\Server3"
```

---

## Spiegazione del Bug

In PowerShell 5.1, all'interno di un blocco `switch`, la variabile automatica `$_` viene
**sovrascritta con il valore corrente che lo switch sta confrontando** (in questo caso `"cleanup"`).

Quando si usa `ForEach-Object` in pipeline **dentro il blocco switch**, il motore PS 5.1
valuta il primo elemento del pipeline PRIMA che `$_` venga riassegnato dall'iteratore
`ForEach-Object`. Il risultato e' che il primo elemento della pipeline usa il `$_` dello
scope dello switch (= `"cleanup"`), mentre gli elementi successivi usano correttamente il
`$_` dell'iteratore.

### Perche' solo il primo elemento?

Il parser AST di PS 5.1 in un blocco `switch` imposta `$_` al valore matchato
(`"cleanup"`) prima di eseguire il corpo del blocco. Quando la pipeline avvia
`ForEach-Object`, il binding di `$_` avviene in modo lazy/ritardato: il primo ciclo
"eredita" il `$_` dello scope padre (= `"cleanup"`), poi `ForEach-Object` prende il
controllo e i cicli successivi usano correttamente i valori del pipeline.

### Schema del problema

```
switch ($azione) {         # $_ = "cleanup" (valore corrente dello switch)
    'cleanup' {
        # Qui $_ == "cleanup"
        $raw -split "`n"   # produce: "D:\...", "E:\...", "F:\..."
        | ForEach-Object {
            $_.Trim()      # Primo elemento: $_ ancora = "cleanup" -> "cleanup"
                           # Dal secondo in poi: $_ = elemento del pipeline -> OK
        }
    }
}
```

---

## Fix: Usare un foreach Loop

Il loop `foreach` NON contamina `$_`, quindi e' immune a questo bug.

```powershell
$azione = $WebEvent.Data['azione']
switch ($azione) {
    'cleanup' {
        $raw = "D:\Backup\Server1`nE:\Backup\Server2`nF:\Backup\Server3"

        # CORRETTO: foreach loop non usa $_, nessuna contaminazione
        $paths = @()
        foreach ($line in ($raw -split "`n")) {
            $trimmed = $line.Trim()
            if ($trimmed) {
                $paths += $trimmed
            }
        }
        # $paths[0] = "D:\Backup\Server1"  <-- corretto
        # $paths[1] = "E:\Backup\Server2"
        # $paths[2] = "F:\Backup\Server3"
    }
}
```

---

## Alternative Sicure

### Opzione A: Assegnare $_ a una variabile locale PRIMA della pipeline

```powershell
switch ($azione) {
    'cleanup' {
        $raw = "D:\Backup\Server1`nE:\Backup\Server2`nF:\Backup\Server3"

        # Salvare il valore in variabile locale, poi usare pipeline fuori dallo switch
        $lines = $raw -split "`n"
        $paths = @($lines | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        # Funziona perche' la pipeline ora e' su $lines, non su ($raw -split "`n")
        # MA: rimane dentro il blocco switch, quindi e' ancora a rischio.
        # Meglio usare foreach (Opzione principale).
    }
}
```

**Attenzione**: anche questa forma puo' essere fragile. La soluzione piu' sicura e' sempre il loop `foreach`.

### Opzione B: Estrarre la logica fuori dallo switch

```powershell
function Parse-Paths {
    param([string]$raw)
    $paths = @()
    foreach ($line in ($raw -split "`n")) {
        $trimmed = $line.Trim()
        if ($trimmed) { $paths += $trimmed }
    }
    return $paths
}

switch ($azione) {
    'cleanup' {
        $raw = "D:\Backup\Server1`nE:\Backup\Server2`nF:\Backup\Server3"
        $paths = Parse-Paths -raw $raw  # Nessun $_ nel corpo dello switch
    }
}
```

---

## Regola Mnemonica

> **Dentro un blocco `switch`, MAI usare `$_` in pipeline o `ForEach-Object`.**
> Usare SEMPRE `foreach ($var in $collection) { ... }` con una variabile nominata.

---

## Scope del Bug

| Contesto | `$_` contaminato? | Soluzione |
|----------|--------------------|-----------|
| `switch` block + `ForEach-Object` in pipeline | SI (primo elemento) | `foreach` loop |
| `switch` block + `Where-Object` in pipeline | Potenzialmente | `foreach` loop + `if` |
| `if/else` block + `ForEach-Object` | No | Non affetto |
| `foreach` block + `ForEach-Object` | No | Non affetto |
| PS 7+ con `switch` + pipeline | Verificare | Preferire `foreach` per sicurezza |

---

## Versioni Affette

- PowerShell 5.1 (Windows PowerShell): **BUG CONFERMATO**
- PowerShell 7+: comportamento piu' prevedibile ma preferire `foreach` per coerenza

---

## Riferimento Memory

Questo gotcha e' documentato anche in:
- `MEMORY.md` (sezione "CRITICO: PS 5.1 - $_ contamination in switch blocks")
- System prompt dell'agente PowerShell-Pode.Web (sezione "PowerShell 5.1 - Gotcha e Workaround")
