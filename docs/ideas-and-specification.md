# SEC-V: Aufgaben, Spezifikation und Ideen

**Autor:** Jörn Hoffmann

**Stand 2026-11-05.** An SEC-V wird vorerst nicht weitergearbeitet. Dieses Dokument hält fest, was als Nächstes anstünde (Abschnitt A) und wohin die Weiterentwicklung mit den Ideen aus RISP gehen soll (ab Abschnitt 1).

**Frage.** Wie weit lässt sich ein Prozessor durch seine Struktur gegen eigene Schwachstellen absichern, und wie viel Tempo holen Einheiten, Pipelining und Interleaved Multi-Threading (IMT) dabei wieder herein, ohne Caches und Spekulation?

**Kennzeichen.** **[E]** vom Autor entschieden. **[V]** Vorschlag, noch nicht bestätigt; darf nach Messung geändert werden, die Änderung steht dann im Bericht. **[O]** offen. Belege: **gemessen** (ein Lauf zeigt es), **hergeleitet** (aus Code oder Dokumenten begründet), **ungeprüft**.

## A. Nächste Aufgaben

Nachgelesen im Stand `bb0c8fa`; ausgeführt wurden nur die SVUT-Tests.

### A.1 Tests

- [ ] **Offizielle `riscv-tests` (`rv64ui`) gegen den Kern laufen lassen.** Das lief noch nie; es zeigt, ob der Kern funktioniert und wo er hakt.
- [ ] **`secv_testbench` prüft nichts:** Er läuft 10000 Zeiteinheiten und besteht immer. Pass oder Fail über eine Speicherstelle oder Ähnliches ergänzen. Die übrigen 171 SVUT-Tests bestehen, alle 172 zusammen (gemessen).
- [ ] **Auf cocotb umstellen [E]:** Werkzeuge aus `hex-v` (`tests/`) übernehmen, SVUT-Fälle dabei überführen.
- [ ] **Vergleich gegen Spike:** Retire-Port (RVFI-Art) ergänzen, dann Generator, Abdeckung und Mutanten aus `hex-v` (`tests/spike/`) übernehmen.
- [ ] **Fehlende Einheitentests:** `mem.sv` hat nur einen SVUnit-Test, kein SVUT; `csr.sv`, `ram_wb.sv` und `rom_wb.sv` haben keinen. **[E]** Tests mit cocotb wie in `hex-v`; die SVUT- und SVUnit-Tests werden abgelöst.
- [ ] **Todos nachziehen:** `alu`, `branch`, `gpr`, `mem_decoder` tragen „Add unit tests“, haben aber Testbenches.
- [ ] Formale Verifikation der Einheiten (Todo in fast allen Köpfen).

### A.2 Fehlerkorrekturen

Alles **hergeleitet**, vor der Korrektur mit einem Test belegen.

- [ ] **Traps wirken nicht:** In `secv.sv` werden `mret` und `trap_adr` nirgends getrieben, und `trap_vec` geht nicht in den PC-Mux. Eine Exception verändert den PC also nicht.
- [ ] **Byte-Adressen:** `mem.sv` legt die Byte-Adresse direkt an, `ram_wb` hat einen Eintrag pro Adresse, die Selects kennen keinen Versatz. `SW` auf 0 und `LB` auf 1 sähen dann verschiedene Wörter.
- [ ] **`LWU`:** Setzt die Selects wie `LD`.
- [ ] **`alu_core`:** `shamt` ist fest 6 Bit und passt nur zu `XLEN=64`.
- [ ] **`XLEN`:** Sieht wie ein Modul-Parameter aus, gilt aber über das Package global; auf 32 Bit prüfen.

### A.3 CSRs und Traps fertigstellen

- [ ] **Traps verdrahten:** Sprung auf `trap_vec`, `trap_pc`, `trap_adr`, Prioritäten (Todo „Trap, fault, exception handling“).
- [ ] **`ECALL`, `EBREAK`, `MRET`:** `FUNCT3_ECALL_EBREAK` landet in `csr.sv` im `default` und damit bei `err`. Dekodieren, `mret` treiben.
- [ ] **Machine Mode vollständig** (Todo in `csr.sv`), Test für `csr.sv`.
- [ ] **Interrupts:** `csr.sv` hat die Signale, der Kern `secv` hat keinen Interrupt-Eingang.
- [ ] **Timer und Zähler:** Timer (`csr.sv`), `minstret` (`csr_regs.sv`).
- [ ] **PMP** (`csr_regs.sv`: Implementierung, Verallgemeinerung).
- [ ] **User Mode, Exceptions bei ungültigen Schreibzugriffen**, Frage „csr-logic decision out of register?“ (`csr_regs.sv`).

### A.4 Pipelining

Der Entwurf steht ab Abschnitt 4. Reihenfolge:

- [ ] **Vorbereitung:** Einheitenschnittstelle mit `done`, Automat in Einheiten trennen (Todo „Separate units“).
- [ ] **a) reguläre Pipeline** mit den Stufen aus Abschnitt 4, Bibliothek `hdl/pipe/` aus `hex-v`.
- [ ] **b) IMT:** Thread-Tags, Scheduler, hart und weich (Abschnitt 5).
- [ ] **Wiedervorlage** (Abschnitt 5.4), **FU-Rahmen und Policy** (Abschnitt 6).

### A.5 Aufräumen und ISA

- **Branch `memtag`:** Bleibt liegen, er ist kaputt **[E]**. Speicher-Tags wären neu zu bauen, siehe Ideen.
- [ ] **Package:** „Cleanup and reorder“, fehlende Dekodierfunktionen (`decode_funct3`, `decode_rs1` usw., `zext8` usw.), Stand in `hex-v` ansehen.
- [ ] **Decoder:** Todos in `decoder.sv`, Addierer in `SRC1_SEL_RS1_IMM` durch die ALU ersetzen **[E]**.
- [ ] **ISA:** 32-Bit-Build **[E]**, dann M (Abschnitt 9), später B, C, Krypto (README).
- [x] **Autor in den Dateiköpfen:** nur noch `Jörn Hoffmann`, ohne Mail **[E]**.
- [ ] **Sonstiges:** `hdl/unused/` sichten, Encoder-Funktionen im Package (später), README auf den Stand bringen.

## 1. Die Kostentreiber zuerst

| # | Risiko | Was es kostet | Wie es geklärt wird |
|---|---|---|---|
| 1 | Ergebnis-Mux hinter den Einheiten und `fn`-Decoder vor der ALU, im kritischsten Pfad | Takt, ungemessen | Prototyp zu Beginn von Schritt 2; bei zu hohen Kosten dekodiert die Einheit ihr `fn` in ID mit einer Funktion ihres Packages vor |
| 2 | Die Pipeline hält nie an, sobald ein harter Thread existiert (Abschnitt 5.5) | Weiche Threads bezahlen Warten mit Wiederholen | Messen: CPI einer weichen Schleife neben einem harten Thread |
| 3 | Harter Thread läuft mit höchstens 1/3 Tempo | Echtzeit und Spiele auf HEX | Vertex-Profil auf rv32 vor der GTE; Arbeit auf Threads und Einheiten verteilen |
| 4 | Registerdatei und CSRs pro Thread | Fläche und Timing mit `THREADS` | Über die Testmatrix messen; RAM oder Flipflops wählen |
| 5 | Geteilter Speicher | Die taktgenaue Echtzeit-Aussage gilt nur bis zum Bus | Abschnitt 9, Schritt 7 |

Vergleichsbasis ist `v0` (Abschnitt 2), alles auf ECP5 und Gowin, Fmax über mindestens 3 Seeds. Dieselbe Logik schwankt allein um rund 75 LUT4 (gemessen); kleinere Unterschiede belegen nichts.

## 2. Herkunft und Ausgangsmaterial

| Quelle | Wo | Was daraus wird |
|---|---|---|
| RISP | `~/Develop/uni-leipzig.de/risp/core/risp_06`, `risp_05_thread` (VHDL, nur lesen) | Funktionseinheit als Architektur, `FU_TABLE`, `fu_i_t`/`fu_o_t`, `fu_default`, Registersatz pro Thread, Wiedervorlage (`funits/arith/arith.vhd`), `skel` als Vorlage, Permutation vor dem Decoder, Ideenlisten im Kopf von `cpu/cpu.vhd` |
| SEC-V | Dieses Repo, `main` auf `bb0c8fa` | RISC-V-Package, Befehlsformate, `decode_imm_*`, `alu_core`, Stil, Kopfzeilen mit Todos |
| `v0` | Tag `v0` in `c64-re/hex-v` (klassischer Fünfstufen-Kern) | **Vergleichsbasis.** Dazu Werkzeuge zum Übernehmen: `tests/spike/` (Spike-Vergleich, Generator, Abdeckung, Mutanten), `tests/core/` (offizielle Programme, ISS, `test_timing.py`), `hdl/pipe/`, `synth/` (`run_synth.py`, `equiv.py`), `scripts/check_style.py`, `docs/style.md`, `Makefile` |

**Zahlen von `v0`, gemessen:** ECP5 1813 LUT4, 475 FF, 78,5 bis 83,0 MHz; Gowin 1503 LUT4, 91,4 bis 92,3 MHz; CPI 1,14 auf rv32ui, 1,68 in der Schleife; Load-Use 2 Takte, genommener Sprung 2 Takte; 436 Tests; 8188 Spike-Läufe ohne Abweichung (laut Agentenbericht). VexRiscv zum Vergleich: lite 2814 LUT4, fast 2749 LUT4, beide mit M, CSRs und 2-KB-Befehlscache (Tabelle im README von `v0`).

**Zustand der Vorgänger:** Alle 172 SVUT-Tests von SEC-V bestehen (gemessen), aber `secv_testbench` prüft nichts; der ganze Kern ist unbelegt. In SEC-V scheint jede Byte-Adresse ein eigenes Wort zu sein (`ram_wb`, `mem.sv`; hergeleitet). In RISP hängen `dividend` und `divisor` beide an `GPR_SRC1` (`arith.vhd`; hergeleitet). Beides nicht ungeprüft übernehmen.

## 3. Ziele und Grenzen

- **[E]** Die CPU wird durch Struktur und Architektur sicherer gegen Schwachstellen ihrer selbst. Ein Fehler in einer Einheit bleibt in dieser Einheit.
- **[E]** SEC-V wird auf 32 Bit abgespeckt, die Decoder werden wo möglich vereinfacht. Tempo kommt über Einheiten (GTE), Pipelining und IMT.
- **[E]** Einheiten sind in sich abgeschlossen, alles bleibt einzeln testbar, der Code ist gut lesbar, im Stil des Owners.
- **[V]** RV32I zuerst, dann M. `XLEN` bleibt als Makro im Package, gebaut und getestet wird zunächst nur 32. **[O]** 64 Bit später wieder?
- **Nicht in dieser Arbeit:** Sprungvorhersage und Caches (höchstens spätere Optionen, standardmäßig aus), C-Erweiterung, Superskalarität, Out-of-Order.
- **Kein Ziel:** Schutz gegen Seitenkanäle in der Physik; wo eine Aussage nur für Takte gilt, steht das dabei.

## 4. Pipeline

**[E]** Fünf Stufen IF, ID, EX, MEM, WB. Speicher in eigener Stufe. Adressen rechnet die ALU, es gibt keinen eigenen Adressaddierer. **[E]** Eine ALU, ein Befehl pro Takt in EX.

```
Takt             t    t+1  t+2  t+3  t+4
Befehl           IF   ID   EX   MEM  WB
                      │    │    │    └ Register schreiben, Antwort des Speichers
                      │    │    └ Anfrage an den Datenbus
                      │    └ FU-Rahmen: Einheit rechnet, Sprung entschieden
                      └ Decoder, Register lesen für den nächsten Takt (mit Write-Through), PC + Immediate
```

**Abstandsregel.** Kommt der nächste Befehl desselben Threads frühestens 3 Takte später, braucht er keine Hazard-Logik:

| Fall | Warum | Beleg |
|---|---|---|
| Registerwert | Er liest in `t+4` in ID, der Vorgänger schreibt in `t+4` in WB: Write-Through | Gemessen an `v0`: bei 3 bis 5 Takten alle Läufe richtig, bei 1 und 2 falsch; Lücken dabei mit NOPs gefüllt |
| Load | Dieselben Takte, sofern die Antwort in `t+4` kommt | Wie oben |
| Sprung | Entscheidung beim Verlassen von EX in `t+2`, Ziel am Port in `t+3`; es wird nichts Falsches geholt | Hergeleitet, im Schritt 5 zu messen |

Die Regel gilt nur, solange kein Befehl aufgehalten wird. Echte leere Slots sind nicht getestet: Wartet ein Befehl in WB und davor ist eine Lücke, könnte der Nachfolger aufrücken. Darum Abschnitt 5.5.

**Die Bibliothek** `hdl/pipe/` wird übernommen: `pipe_reg`, `pipe_skid`, `pipe_hazard` (opake Tags), Flush pro Stufe. **Thread-Tags** laufen von Anfang an durch alle Stufen, auch mit einem Thread **[V]**. Ein Flush wirkt nur auf den eigenen Thread.

## 5. Threads und Rotation

### 5.1 Anzahl

**[E]** `THREADS` ist frei konfigurierbar:

| `THREADS` | Name | Eigenschaft |
|---|---|---|
| 1 bis 4 | Under-committed | Freie Slots |
| 5 | Full committed | So viele Threads wie Stufen |
| über 5 | Overcommitted | Mehr Kontexte als Stufen; hebt das RISP-Todo auf |

Pro Thread: PC, Registersatz (Adresse `{thread, register}`), Parkzustand, später CSRs. Mehr Threads erhöhen den Durchsatz nicht über einen Befehl pro Takt; sie bringen Kontexte und Auslastung, wenn andere warten.

### 5.2 Modus pro Thread

**[E]** Pro Thread hart oder weich, wie bei FlexPRET:

- **Hart:** feste Slots, das Tempo hängt nicht von anderen ab.
- **Weich:** bekommt jeden Slot, den gerade niemand nutzt.

```systemverilog
parameter int        THREADS     = 3;
parameter thread_mode_t THREAD_MODE [THREADS] = '{HARD, SOFT, SOFT};
parameter int        SLOT_PERIOD = 3;   // [V] mindestens max(Zahl der harten Threads, 3)
```

**[V]** Sind alle Threads hart, wird die Hazard-Logik beim Bauen entfernt (`pipe_hazard` mit `ENABLE=0`, kein Flush, kein Load-Use). Sobald einer weich ist, bleibt sie.

### 5.3 Scheduler

**[V]** Ein eigenes Modul `thread_sched`, zuerst nur der Ring:

```systemverilog
input  logic [THREADS-1:0] can_fetch_i;     // Nicht geparkt, nicht gestoppt
output logic               fetch_valid_o;   // Sonst: Bubble in diesem Takt
output thread_t            fetch_thread_o;
output logic               fetch_collect_o; // Wiedervorlage: Bubble ohne Fetch (5.4)
```

Regel pro Takt:
1. Ein Zähler läuft reihum von 0 bis `SLOT_PERIOD-1`. Der i-te harte Thread besitzt Slot i.
2. Gehört der Slot einem harten Thread, der holen kann, bekommt ihn dieser Thread.
3. Sonst bekommt ihn der nächste weiche Thread, der holen kann, reihum.
4. Sonst bleibt der Slot eine Bubble.

| Konfiguration | Folge |
|---|---|
| 1 hart, `SLOT_PERIOD` 3 | `A - - A - -` |
| 2 hart | `A B - A B -` |
| 3 hart | `A B C A B C` |
| 5 hart, `SLOT_PERIOD` 5 | `A B C D E` |
| 7 hart, `SLOT_PERIOD` 7 | `A B C D E F G` |
| A hart, B und C weich | `A B C A B C`; schläft C: `A B B A B B`; schläft A: `B C B C B C` |
| 3 hart, 2 weich, `SLOT_PERIOD` 3 | **Die weichen verhungern:** Beim Bauen ablehnen oder `SLOT_PERIOD` 5 verlangen |

Mit einem weichen Thread allein ist das der normale Einzelkern, ein Befehl pro Takt.

**Thread-Start [V]:** Eine Tabelle `THREAD_RESET_PC`, wie `THREAD_RESET_ADR` in RISP; `mhartid` kommt mit den CSRs. Ein Thread ohne Programm springt auf sich selbst oder bleibt gestoppt.

### 5.4 Wiedervorlage

**[E]** Eine langsame Einheit ist belegt, der Befehl schreitet nicht fort. **[E]** Anders als in RISP ohne erneutes Fetch und Decode, als markierte Bubble:

1. Der Befehl erreicht EX. Die Einheit übernimmt die Operanden und antwortet `done=0`.
2. Der Thread parkt: Der PC bleibt auf dem Befehl, eigene Nachfolger werden geflusht, `can_fetch` fällt. Im Rahmen liegt pro Thread `{fu, fn, rd}` **[V]**.
3. Die Einheit meldet `ready_thread[t]`.
4. Der Scheduler gibt dem Thread im nächsten passenden Slot statt eines Fetches eine Bubble mit `collect=1`, ohne Busverkehr, Decoder und Registerlesen.
5. Die Bubble holt in EX das Ergebnis ab, `done=1`, läuft bis WB, retired und der PC rückt weiter.

**Belegte Einheit [V]:** Besitzt ein anderer Thread die Einheit, antwortet sie `busy=1`. Der Thread bekommt seinen Befehl dann wie in RISP noch einmal über einen normalen Fetch desselben PC, sobald die Einheit frei ist. So bleibt die Operandenhaltung einfach.

**Traps [V]:** Wird ein parkender Thread unterbrochen, löscht das den Besitzer in der Einheit. Der PC steht noch auf dem Befehl, er läuft nachher von vorn. Sonst könnte ein Handler Register ändern und das alte Ergebnis käme an (hergeleitet aus der PC-Prüfung in `arith.vhd`).

### 5.5 Anhalten

**[E]** Sobald ein harter Thread existiert, hält die Pipeline nie an. Jedes Warten läuft über die Wiedervorlage.

Daraus folgt **[V]**:
- Der Speicher muss parken können, sobald er Wartezustände hat (Abschnitt 6.4). Am BRAM ohne Wartezustände reicht `done=1`.
- Auch weiche Threads dürfen dann nicht in EX warten, denn sie hielten den harten Thread dahinter auf. Load-Use, FENCE.I und andere Hazard-Wartezeiten werden zum Wiederholen vom eigenen PC. **[O]** Soll ein rein weicher Kern weiterhin wie `v0` anhalten (bessere CPI, zwei Mechanismen) oder immer wiederholen (ein Mechanismus)? Vorschlag: messen; bei kleinem Unterschied immer wiederholen.
- Ein verspäteter Fetch bleibt eine Bubble.

## 6. Einheiten und FU-Rahmen

### 6.1 Aufbau

**[E]** Die Einheiten sind in sich abgeschlossen. Der FU-Rahmen ist eine Art Muxer, der sie ankoppelt, und zugleich die Stelle für Policy und Beweis. **[E]** Rahmen in EX und in MEM, der Speicher ist eine Einheit hinter dem MEM-Rahmen.

```
EX-Rahmen:   ALU, Branch, M, CSR, GTE ...      Policy: rd, PC, darf der Thread diese Einheit
MEM-Rahmen:  Speichereinheit                   Policy: Adressbereich
```

Jede Einheit hat ihren Ordner, ihr Package (`fn`-Codes liegen dort), ihren Test und folgt `hdl/funits/skel/` als Vorlage **[V]**. Eine neue Einheit braucht außerhalb nur einen Eintrag in `FU_TABLE` und ihre Instanz im Rahmen **[V]**. Bei RISP waren das `cpu_fu_pkg` und `cpu.vhd`.

### 6.2 `fu_i_t`, `fu_o_t`

**[V]** Entwurf; Namen und Felder dürfen sich beim Bau ändern:

```systemverilog
typedef struct packed {         // Rahmen zur Einheit
    logic       ena;            // Einheit ist ausgewählt, Eingang gültig
    logic       collect;        // Wiedervorlage: nur Ergebnis abholen
    thread_t    thread;
    fu_fn_t     fn;             // Rohes fn; die Einheit dekodiert selbst
    xlen_t      src1, src2;
} fu_i_t;

typedef struct packed {         // Einheit zum Rahmen
    logic       done;           // 0: Wiedervorlage
    logic       busy;           // Nicht angenommen, Einheit gehört einem anderen Thread
    logic       rd_write;
    xlen_t      res;
    logic       pc_write;
    pc_t        pc_next;
    logic       err;            // Trap: illegales fn, Zugriffsfehler
} fu_o_t;

// Eigener Port der Einheit, nicht im Struct: Thread ist fertig
output logic [THREADS-1:0] ready_thread_o;
```

- **Vorgabe:** `fu_o_default()`: `done=1`, nichts schreiben, wie `fu_default` in RISP.
- **Optionale Eingänge [V]:** PC, Immediate und CSRs bekommt nur, wer sie braucht, als eigener Port. Eine Einheit ohne diesen Port kann sie nicht lesen.
- **Schnelle Einheiten:** Die ALU antwortet im selben Takt mit festem `done=1`, die Synthese sollte die Wiedervorlage bei ihr entfernen (ungemessen).
- **Decoder [E]:** Die getrennten Decoder von SEC-V gibt es wegen Permutation und Entkopplung. Der Hauptdecoder liefert nur `fu`, Registerfelder, Immediate und `fn`; die Einheit dekodiert `fn` selbst und meldet ungültige über `err`. Die Vereinfachung ist erlaubt, wo sie nichts kostet.

### 6.3 Hauptdecoder

**[V]** Abbildung von RISC-V auf Einheiten:

| RISC-V | `fu` in EX | `fn` | Weg |
|---|---|---|---|
| `OP`, `OP-IMM` | ALU | `{inst[30], funct3}`; bei `OP-IMM` Bit 30 nur für `SRL`/`SRA` | |
| `OP` mit `funct7=01` | M | `funct3` | |
| `LUI`, `AUIPC` | ALU, `ADD` | | `AUIPC`: ID addiert den PC aufs Immediate |
| `LOAD`, `STORE` | ALU, `ADD` | | **Adresse aus der ALU [E]**, weiter an MEM mit `{is_store, funct3}` |
| `BRANCH` | Branch | `funct3` | Ziel aus dem Addierer in ID |
| `JAL` | Branch | eigener Code | Ziel aus ID, Link als `res` |
| `JALR` | Branch | eigener Code | Ziel `rs1 + imm`, eigener kleiner Addierer **[O]** oder Umweg über die ALU |
| `FENCE` | keine | | Leer |
| `FENCE.I` | Branch | eigener Code | Älteres eigenes Store abwarten, dann Sprung zum nächsten Befehl |
| `SYSTEM` | CSR (Schritt 4) | | Vorher: Thread stoppt, `trap_o[thread]` |
| Unbekannter Opcode | | | Hauptdecoder meldet Trap |

Einen Addierer behält ID: Der Branch vergleicht in EX, das Ziel `PC + imm` entsteht vorher. Die Branch-Einheit braucht einen eigenen Vergleicher. Was das gegenüber `v0` kostet (dort vergleicht die ALU), zeigt die Messung.

### 6.4 Speichereinheit

**[E]** Einheit hinter dem MEM-Rahmen, sie bekommt über `fu_i_t` in `src1` die Adresse aus der ALU und in `src2` die Store-Daten.

- **[V]** Enthält Bus-Logik, `store_align`, `load_align`, alles in einem Ordner; genau eine Schnittstelle zur Pipeline.
- **[V]** Anfrage in MEM, Antwort in WB.
- **[V] Zunächst:** Am BRAM immer `done=1`, wie in `v0`.
- **[V] Parken (Schritt 7):** Kommt die Antwort nicht im WB-Takt, entfällt das Schreiben, der Thread parkt, die Einheit puffert die spätere Antwort, eine Wiedervorlage-Bubble holt sie in WB ab. Ein Store läuft nur einmal, weil die Bubble nichts mehr anstößt.
- **Bus:** Pipelined Wishbone wie in `v0`.

### 6.5 Policy und Isolation

**[E]** Eine Policy legt fest, was eine Einheit darf, zum Beispiel PC+1 übernehmen. Das ist die Stelle für den formalen Beweis. Das Ziel ist Fehlereindämmung.

**[V]** Regeln:
- **Schreibrechte wirken am Ausgang:** Der Rahmen übernimmt ein Signal nur, wenn das Recht besteht. Ohne PC-Recht ist der nächste PC immer PC+4.
- **Leserechte durch Nicht-Verdrahten:** Der Owner sieht die Sperre am Eingang als teurer; zudem existiert ein nicht verdrahtetes Signal in der Einheit gar nicht.
- **Policy ist zunächst eine Konstante beim Bauen**, gesperrte Wege sollten wegfallen (ungemessen).
- **Verstoß:** Trap des Threads, sobald es Traps gibt, vorher `trap_o`.

| Einheit | Register | PC | Flags, CSRs | Bus |
|---|---|---|---|---|
| ALU | `rd` | PC+4 | Nein | Nein |
| Branch | `rd` (Link) | Ja | Nein | Nein |
| Speicher | `rd` | PC+4 | Nein | Ja, im Bereich |
| M | `rd` | PC+4 | Nein | Nein |
| CSR | `rd` | Ja, Trap und Rückkehr | Ja | Nein |
| Beschleuniger, GTE | `rd` | PC+4 | Nein | Nur eigener Bereich, wenn überhaupt |

**[E] Eigene Einheit pro Thread.** Ein Thread kann zum Beispiel GTE-Thread sein und seine eigene Einheit bekommen, sinnvoll vor allem bei mehrzyklischen Einheiten. **[V]** Dafür eine Tabelle:

```systemverilog
parameter fu_mask_t THREAD_UNITS [THREADS] = '{FU_ALU|FU_GTE, FU_ALU|FU_MEM, FU_ALU|FU_MEM|FU_M};
```
Mehrere Instanzen sind weitere Einträge in `FU_TABLE`. Spricht ein Thread eine fremde Einheit an, gibt es einen Trap. Für Echtzeit-Aussagen brauchen harte Threads eine eigene oder eine Einheit mit fester Laufzeit.

**Was der Rahmen nicht leistet:** Falsche Rechenwerte (bleiben für Beweise pro Einheit, Spike-Vergleich oder Validierungs-Threads). Eigene Ports einer Einheit umgehen ihn, darum läuft auch der Bus durch den Rahmen. Seitenkanäle.

## 7. Prüfung

Übernommen aus `v0`, neu wo angegeben:

| Prüfung | Inhalt | Annahme |
|---|---|---|
| Einzeltests | cocotb, Verilator, `tests/module/` pro Einheit | Alle bestehen |
| Offizielle Programme | `rv32ui`, später `rv32um`; `ma_data` weglassen | In allen Warte-Profilen |
| Spike-Vergleich | Retire-Port gegen Spike, zufällige Programme, Abdeckung, Mutanten | **0 Abweichungen**, Abdeckung voll, alle Mutanten gesehen |
| **Neu: Threads** | Retire-Port bekommt `thread`; pro Thread ein eigenes Programm mit getrenntem Speicher und eigener Spike-Lauf | Matrix `THREADS` 1, 2, 3, 5, 7 mal alle hart, alle weich, gemischt |
| **Neu: echte Lücken** | Harte Threads mit leeren Slots, Sprüngen, Loads und Wartezuständen | Ersetzt den schwachen `core_nofwd` (bestand auch bei zu kleinem Abstand, Ursache nicht untersucht) |
| **Neu: Taktgenauigkeit** | Harter Thread läuft allein und neben Lastprogrammen in weichen Threads | Retire-Takte des harten Threads identisch, solange Speicher und Einheiten nicht geteilt sind |
| **Neu: Rechte, formal** | SymbiYosys, Ausgänge der Einheit als freie Eingänge; siehe unten | Beweis besteht, ein Mutant mit entfernter Sperre lässt ihn scheitern |
| **Neu: Fehlereinbau** | Einheiten mit eingebauten Fehlern; zählen, was der Rahmen abfängt und was durchkommt | Tabelle pro Fehlerklasse gegen `v0` |
| Messung | `make synth`, ECP5 und Gowin, mindestens 3 Seeds; CPI | Gegen `v0` im Bericht |
| Review | Sol zu jeder HDL-Stufe, Befunde selbst prüfen | Archiv in `docs/reviews/` |

**Zu beweisende Eigenschaften [V]:**
1. Ohne PC-Recht ist der nächste PC eines Threads PC+4, für jede Ausgabe der Einheit.
2. Ohne Registerrecht wird kein Register geschrieben.
3. Eine Einheit schreibt nur in den Registersatz des Threads, dem der Befehl gehört.
4. Ein Bus-Zugriff liegt immer im erlaubten Bereich.
5. Ein harter Thread bekommt seinen Slot, egal was andere Threads tun.
6. Jeder Befehl retired höchstens einmal; ein Store läuft genau einmal.
7. Eine geflushte Einheit oder ein gelöschter Besitzer liefert kein altes Ergebnis.

**Die Umgebung:** Python-Umgebung `c64-re/.venv`, Spike `~/src/riscv-isa-sim/install/bin/spike`, OSS CAD Suite wie im `Makefile`.

## 8. Regeln für den Agenten

- **Commits in `sec-v` ohne jede Claude-Zeile** (für `hex-v` vom Owner so festgelegt, hier **[V]** genauso). Commit nach jedem Schritt, Bericht auf Deutsch, höchstens 15 Zeilen, gemessen, hergeleitet und ungeprüft trennen.
- **Stil des Owners:** `docs/style.md` von `v0`, Referenz `hdl/secv.sv` im Stand `bb0c8fa` von `sec-v`. Kopf mit Project, Author, Purpose, Abschnitten, **Todo und Ideen**, History. Leerzeile und Kommentar vor jedem Block, ausgerichtete Ports, benannte `always`-Blöcke, `end`, Leerzeile, `else`, Banner 120 Zeichen. Todos und Ideen dieser Datei wandern in die Köpfe der passenden Module.
- **Lesbarkeit ist ein Ziel:** Maßstab ist `secv.sv`, von oben nach unten lesbar. Taktdiagramme kommen aus der Simulation und werden getestet, wie `test_timing.py`.
- **KISS.** Keine Option, die niemand bestellt hat. Spezifikation ist kein Gesetz: Weicht die Messung ab, Abweichung begründen und melden.
- **Nichts ins Board laden, nicht ins GitHub-Repo pushen** ohne Auftrag; das Remote `sec-v` bleibt unberührt.
- **Stopp und melden:** wenn eine [E]-Entscheidung nicht haltbar ist, eine Messung einen Kostentreiber bestätigt oder das Protokoll der Pipe-Bibliothek sich ändern müsste.

## 9. Todo, in dieser Reihenfolge

Jeder Schritt ein eigener Agent, danach prüft der Koordinator und merged. **[V]** Die Reihenfolge ist ein Vorschlag.

**Schritt 0: Klären**
- [ ] Tag auf den Stand `bb0c8fa` vor jeder Änderung am Kern; gearbeitet wird auf einem Branch.
- [ ] Offizielle `rv64ui` gegen den unveränderten Kern laufen lassen: Funktioniert er, und wo hakt er?

**Schritt 1: Abspecken**
- [ ] RV32I, Automat wie in `secv.sv`, mit Rahmen und abgeschlossenen Einheiten (ALU, Branch, Speicher), `fu_i`/`fu_o`, `FU_TABLE`, `skel`.
- [ ] Werkzeuge von `v0` übernehmen. **Annahme:** `rv32ui` und Spike-Vergleich ohne Abweichung; Flächenvergleich gegen `v0`.
- [ ] Nachweis Erweiterbarkeit: Wie viele Stellen außerhalb einer Einheit musste man anfassen?

**Schritt 2: Pipeline**
- [ ] **Zuerst der Prototyp:** Rahmen plus ALU gegen `v0`, Ergebnis-Mux und `fn`-Decoder messen. Entscheidung: rohes `fn` oder Vordekodieren in ID. Bericht, bevor es weitergeht.
- [ ] Fünf Stufen mit `hdl/pipe/`, Thread-Tags, ein weicher Thread. **Annahme:** alle Prüfungen, CPI und Fmax nahe `v0`.

**Schritt 3: M und Wiedervorlage**
- [ ] M als erste neue Einheit, Dividierer iterativ. **[O]** Feste Laufzeit (sicherer) oder wertabhängig (im Mittel schneller)? Schalter vorschlagen.
- [ ] Parken und markierte Bubble. **Annahme:** `rv32um`, Spike-Vergleich mit `--isa=rv32im`, Mutanten für Flush während der Division.

**Schritt 4: CSRs und Traps**
- [ ] Machine Mode, klein: `mstatus`, `mtvec`, `mepc`, `mcause`, `mie`, `mip`, `mhartid`, Zähler. CSR als Einheit.
- [ ] Interrupts als eingeschobene Bubble (wie `create_irq_inst` in RISP) **[V]**.

**Schritt 5: Threads**
- [ ] `thread_sched`, harte und weiche Threads, Flush pro Thread, Registerdatei `{thread, register}`.
- [ ] Alle hart: Hazard-Logik weg. Testmatrix aus Abschnitt 7, echte Lücken, Taktgenauigkeit. Fläche und Fmax über `THREADS`.

**Schritt 6: Policy und Beweise**
- [ ] Policy-Tabelle, `THREAD_UNITS`, Verstoß als Trap.
- [ ] SymbiYosys mit den Eigenschaften aus Abschnitt 7, Fehlereinbau. Ergebnis: Kosten-Nutzen-Tabelle gegen `v0`.

**Schritt 7: Speicher**
- [ ] Parken des Speichers, feste Bus-Slots für harte Threads. PTARM und FlexPRET lesen.

**Schritt 8: GTE und HEX**
- [ ] Vertex-Profil auf rv32, dann GTE als Einheit mit eigenem Ablauf.
- [ ] Einbindung ins SoC, Vergleich mit VexRiscv auf dem Board (Go des Owners).

## 10. Ideen, noch keine Arbeit

- **Shuffle und Priorität (Owner):** `A B C → B C A → C B A`, Priorität `A B A C`. Hergeleitet: Ohne Hazard-Logik nur mit Abstand ab 3, also Shuffle ab 4 Threads und Priorität bis 1/3, etwa `A B C A D E`. `A B A C` hat Abstand 2, braucht einen Forwarding-Pfad, Load-Warten und Flush. Harter Thread mit Shuffle ist nicht mehr taktgenau, nur begrenzt.
- **Kein RR-Scheduler in Echtzeitsystemen (Owner):** Der Ring ist Round Robin in Hardware.
- **Fusion-Befehle (Owner, offen):** Mehrere Register lesen oder schreiben, über mehrere Runden wirken, auch als Micro-Ops. Hergeleitet: Runden und µops laufen über denselben Bubble-Weg, ein Slot pro Schritt, ohne neue Ports. In jedem Takt weiterrechnen geht nur mit eigenen Rechenwerken, also im Sequenzer der Einheit. µops in Hilfsregister, erst der letzte schreibt `rd`, dann ist ein Trap sauber. Für RISC-V im Custom-Opcode-Bereich; Spike kennt sie nicht.
- **Validierungs-Threads (RISP):** Ein zweiter Thread rechnet versetzt mit, schreibt nicht und vergleicht (MISD), mit eigenem Speicher und Schlüssel. Der Versatz hilft gegen eine Störung, die in einem Takt beide träfe.
- **Strukturpermutation (Owner):** Der Hauptdecoder gibt einer Einheit eine andere Nummer, sie liegt anderswo im Muxer und wird anders verschaltet. Normaler RISC-V-Code läuft unverändert; jede Permutation muss denselben Spike-Vergleich bestehen. Bei 5 Einheiten 120 Anordnungen, rund 7 Bit. Ob die Netzliste sich wirklich ändert, ist nicht gemessen.
- **Opcode-Permutation (RISP):** XOR-Schlüssel und `PERM_MAP` vor dem Decoder, Parität im Kopf. Pro Thread eigene Schlüssel.
- **Weitere Vorschläge aus dem Kopf von `risp_06/sources/cpu/cpu.vhd`:** Hashes des Befehlsspeichers, Isolationsbereiche zwischen Threads, sichere Bus-Einheit, dynamische Rekonfiguration (Einheiten zur Laufzeit ein- und auslagern), skalierbare Pipeline n bis m Stufen.
- **Aus SEC-V:** Speicher-Tags, Bitmanipulation, Krypto. Encoder-Funktionen im Package (Owner: später), heute nur in `tests/hexv_names.py` von `v0`.
- **Aus dem README von SEC-V:** Shadow Stack, PMP, SCADS, Cache-Adresspermutation, Krypto- und Hash-Einheiten, Schlüsselschutz, PUF-Attestierung, Trojaner-Erkennung über PUFs.
- **Weiteres:** Sprungvorhersage und Caches als Optionen, standardmäßig aus; atomare Befehle für den Austausch zwischen Threads; riscv-formal auf dem Retire-Port.

## 11. Andere Forschungskerne

Nur aus Suchzusammenfassungen, kein Paper vollständig gelesen (**ungeprüft**). FlexPRET und Klessydra vor Schritt 5 lesen, PTARM vor Schritt 7.

| Kern | Was er macht | Offen | Was daraus zu lernen ist |
|---|---|---|---|
| [FlexPRET](https://github.com/pretis/flexpret), [Bericht](https://www2.eecs.berkeley.edu/Pubs/TechRpts/2015/EECS-2015-181.html) | 5 Stufen, RISC-V, Chisel; harte Threads in festen Takten, weiche im Rest; Zeitbefehle | Ja | **Am nächsten am Entwurf.** Scheduler, Schlafen, Zeitbefehle |
| [PTARM](https://www2.eecs.berkeley.edu/Pubs/TechRpts/2012/EECS-2012-113.html) (PRET) | Thread-interleaved, jeder Thread in einer Stufe, Scratchpads statt Caches, DRAM mit wiederholbarem Timing | Nicht geprüft | Geteilter Speicher ohne Timing-Kanal |
| [Klessydra T03x](https://github.com/klessydra/T03x), [Paper](https://arxiv.org/pdf/1712.04902) | Offener Barrel, drei Harts, je mit Registern, CSRs und PC, ohne Flush-Kosten | Ja | CSRs pro Thread, Vergleich der Fläche |
| [XMOS xCORE](https://www.xmos.com/download/xCORE-Architecture-Flyer(1_2).pdf), [Artikel](https://www.eejournal.com/article/xmos-using-risc-v-to-define-socs-in-software/) | Hardware-Threads, Scheduler in Silizium, keine Interrupts | Nein | Beleg für „kein RR-Scheduler nötig“, Herstellerangaben |
| [Patmos](https://springerlink.bibliotecabuap.elogim.com/content/pdf/10.1007/s11241-018-9300-4.pdf) | Zeitlich vorhersagbar, zwei Befehle pro Takt, kein Multithreading | Ja | Für den Echtzeit-Vergleich |
| [Lee, Geschichte des Interleaving](https://www.sos-vo.org/system/files/sos_files/Time_for_High-Confidence_Software_Systems.pdf) | CDC 6600, Denelcor HEP, Lee und Messerschmitt 1987 | | Herkunft, bekannter Nachteil: langsamer Einzel-Thread |
| [Morpheus](https://lbiernac.github.io), [Überblick](https://www.cnx-software.com/2019/05/07/morpheus-unhackable-risc-v-processor/?amp=1) | RISC-V, verschlüsselt Code und Zeiger, wechselt Schlüssel laufend | | Permutation zur Laufzeit |
| [Instruction Set Randomization](https://cs.brown.edu/~vpk/papers/polyglot.host17.pdf) | Eigener Befehlssatz pro Programm | | Warum ISR gegen Code-Reuse an Wert verlor |
| [ShuffleV](https://arxiv.org/pdf/2510.13111) | Auf Ibex, mischt Befehle gegen elektromagnetische Seitenkanäle | | Zum Shuffle |
| [CHERI](https://www.cl.cam.ac.uk/~swm11/papers/isca2014.pdf) | Hardware prüft Grenzen und Rechte | | Rechte für Software statt für Einheiten |

**Neuheit:** Einen Rahmen um Einheiten mit bewiesenen Rechten und die Strukturpermutation fand die kurze Suche nicht. Das ist keine Aussage über den Stand der Forschung und braucht eine eigene Literatursuche.

## 12. Forschungsfragen

1. Wie viele eingebaute Fehler fängt ein Rahmen, und wie klein wird der Teil, der korrekt sein muss?
2. Was kosten abgeschlossene Einheiten gegenüber `v0` an Fläche und Takt, und was bringen sie an Erweiterbarkeit und Beweisbarkeit?
3. Wie viel holen Threads an Durchsatz herein, mit und ohne Hazard-Logik?
4. Reicht das für harte Echtzeit bei geteiltem Speicher?
5. Ändert Strukturpermutation die Netzliste wirklich, und wofür hilft das?
6. Trägt das Konzept Spiele auf HEX, wenn Arbeit auf Threads und Einheiten verteilt ist?
