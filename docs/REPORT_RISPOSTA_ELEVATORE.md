# Risposta longitudinale a un impulso di elevatore

**Riferimento storico (`kq=0`):** questo report documenta il modello prima dell'aggiunta dell'effetto di `q_pitch`. Per il modello corrente e il confronto con questo riferimento, leggere il [report su smorzamento e Iyy](REPORT_SMORZAMENTO_IYY.md). I file `results/elevator_response_*` rigenerati da `runProject` descrivono ora il modello corrente `kq=1`.

## Esperimento

Simulazione del modello longitudinale semplificato a 52 m/s. L'elevatore passa da -4.821444 deg a -5.321444 deg tra 2 e 2.5 secondi, poi ritorna al trim. La spinta rimane costante a circa 330.351 N. Durata osservata: 20 secondi.

L'analisi originale usava i risultati allora salvati in `elevator_pulse_simulation.mat`, senza modificare l'aerodinamica o ripetere la simulazione. Quel file viene ora rigenerato per il modello corrente; il caso storico e conservato nel confronto.

## Controlli effettuati

- Prima dell'impulso, lo scostamento massimo di velocita e circa 1.83e-12 m/s e quello dell'angolo d'attacco circa 7.07e-13 deg: il trim viene mantenuto.
- La prima velocita di beccheggio successiva al comando e positiva: il muso inizia ad alzarsi secondo la convenzione adottata.
- Il grafico mostra oscillazioni rapide iniziali che si attenuano, seguite da variazioni lente di velocita, traiettoria e quota.

## Condizione finale a 20 secondi

| Grandezza | Scostamento dal valore iniziale |
|---|---:|
| Velocita | +0.315573 m/s |
| Angolo d'attacco | +0.0000717 deg |
| Assetto | +0.010144 deg |
| Angolo della traiettoria | +0.010072 deg |
| Velocita di beccheggio | +0.131296 deg/s |
| Quota | -1.672701 m |

La risposta non e completamente assestata a 20 secondi. Una piccola differenza finale di angolo d'attacco non implica che velocita, assetto e quota siano tutti tornati all'equilibrio. La velocita di beccheggio finale e ancora diversa da zero.

## Separazione delle scale temporali

Tra 2.5 e 5.5 secondi, i massimi assoluti degli scostamenti sono 0.514421 deg per l'angolo d'attacco e 1.806660 deg/s per la velocita di beccheggio. Negli ultimi cinque secondi scendono rispettivamente a 0.000951 deg e 0.131670 deg/s. Questi confronti descrivono il decadimento del transitorio rapido, senza dimostrare da soli l'assestamento del modo lento.

La linearizzazione numerica delle quattro variabili dinamiche V, gamma, theta e q_pitch attorno al trim fornisce due coppie di autovalori:

| Modo | Autovalori [1/s] | Periodo oscillatorio | Tempo di decadimento e-fold |
|---|---|---:|---:|
| Rapido | -1.709485 +/- 5.770799 i | 1.088789 s | 0.584972 s |
| Lento | -0.007235 +/- 0.266817 i | 23.548701 s | 138.208398 s |

Il tempo e-fold indica quanto impiega l'inviluppo del modo linearizzato a ridursi a circa il 37% del valore iniziale; non e un tempo di completo assestamento. Le parti reali sono negative: nel modello linearizzato locale entrambi i modi si attenuano. Il modo lento e debolmente smorzato e la durata di 20 secondi copre meno di un suo periodo completo.

La quota e esclusa dalla matrice dinamica: con densita costante, una quota diversa non cambia le forze. Il modello non impone il ritorno alla quota iniziale.

## Limiti e passaggio realizzato

Questi risultati verificavano il comportamento numerico del modello didattico con `kq=0`, non la dinamica di un velivolo sperimentale. `Iyy=1000 kg*m^2` era ed e una stima, la portanza dell'ala e lineare, la densita e costante e la resistenza di coda e fusoliera e trascurata. In questo riferimento non c'era un termine esplicito da velocita di beccheggio; il decadimento derivava dall'accoppiamento delle equazioni.

Il passaggio previsto e stato svolto: l'effetto di `q_pitch` sulla coda e stato introdotto come stima geometrica quasi stazionaria e confrontato con questo riferimento, insieme alla sensibilita a `Iyy`. Formula, risultati e limiti sono nel [report dedicato](REPORT_SMORZAMENTO_IYY.md).

## Riproduzione del riferimento

Eseguire `runProject` dalla radice del progetto oppure `setupProject` seguito da `comparePitchDampingAndInertia`. Il caso `kq=0, Iyy=1000` e il primo in `results/pitch_damping_inertia_comparison.mat` e nel riepilogo testuale corrispondente. Lo script verifica che i cinque massimi precedenti siano riprodotti entro 5e-5 nelle rispettive unita. `analyseElevatorResponse` legge invece il MAT nominale rigenerato con `kq=1`.
